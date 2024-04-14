open Llvm
open Ast
open Symbol
open TypeKind
open Compiler_helpers

(* first function in llvm ir must be called main, but grace syntax allows any name for a program's main function*)
let first_function = ref true 


let rec type_to_lltype llvm ty =
  match ty with
  | TY_int          -> (llvm.i64, None)
  | TY_char         -> (llvm.i8, None)
  | TY_none         -> (llvm.void, None)
  | TY_array (t, l) -> 
      let (ty, _) = type_to_lltype llvm t in
      let dims_sum = List.fold_left ( * ) 1 l in
      (Llvm.array_type ty dims_sum, Some l)

(* this for matrix indexes (l-values) so that we don't have to codegen anything*)
let retrieve_index e =
  match e with
  | E_int_const i -> i
  | _             -> assert false

(* returns a pointer to the struct with all values in the ST at the time of calling and the new environment with keys mapped to their place in the struct *)
let createStructType llvm env fname =
  let frame = named_struct_type llvm.ctx ("frame."^fname) in
  let keys, values = llvmSTvalues env in
  let st_pairs = List.combine keys values in
  struct_set_body frame (Array.of_list (List.map type_of values)) false;
  (* List.iter (fun x -> print_string (string_of_lltype (type_of x))) values; *)

  let frame_ptr = build_alloca frame ("frame."^fname^"_ptr") llvm.bd in
  
  (* prepei na ginei kapoio filtering wste na min vazei ta panta *)
  if List.length st_pairs <> 0 then 
    (* store each value in ST in the struct and update the ST so that these values point to their new place *)
    let store_and_updateST (index, env) (k, v) =
      let base = (build_struct_gep frame frame_ptr index ("frame_elem_"^(string_of_int index)) llvm.bd) in
      (* print_string (string_of_llvalue (base)); *)
      (* print_char '\n'; *)
      (* print_string (string_of_llvalue (v)); *)
      (* print_string "\n"; *) 
      (* print_string (string_of_lltype (element_type (type_of base))); *)
      (* print_string (string_of_lltype (element_type (type_of v))); *)
      (* let opaq = build_bitcast base (pointer_type2 llvm.ctx) "ptr" llvm.bd in *)
    
      (* print_char '\n'; *)
      (* print_string (string_of_lltype (type_of v)); *)
      print_string "\n\n";


      ignore (build_store v base llvm.bd); 

      let replace x =
        match x with
        | Some ll_entry ->
            (match ll_entry with
            | BasicEntry _ 
            | CompositeEntry (_, _, _) 
            | FuncParamEntry (_, _)          -> Some (StackFrameEntry (ll_entry, frame_ptr, index))
            | _                         -> assert false)
        | None -> assert false in

      let newST = SymbolTable.update k replace env in
      (index+1, newST)
    in 
    let (_, env) = List.fold_left store_and_updateST (0, env) st_pairs in
    frame_ptr, env
  else frame_ptr, env



let rec create_fcall llvm func env stmt =
  match stmt with
  | S_fcall (name, exprs) ->
      print_string ("Calling"^name);
      let upper = if List.mem name llvm.predefined_fs then 0 else 1 in (* ayto einai hardcoded -> kako. an ginoun override oi predefined den tha paizei swsta. ousiastika ayto ginetai gia na min pernaei stack frame stis prokathorismenes synarthseis oi opoies einia vevaio oti xreiazontai mono tis parametrous tous. enallaktika gia aplothta tha mporouse na pernaei to stack frame kai se aytes kai as einai axreiasto *)

      let f = 
        match lookup_function name llvm.md with
        | Some f -> f
        | None -> raise (Failure "unknown function referenced") in


      print_string  (value_name f);
      let fparams = params f in
      
      let args =
        let ast_args = Option.value exprs ~default:[] in
        if Array.length fparams = List.length ast_args + upper then () else
          raise (Failure (name^"(...): incorrect # arguments passed"));
        ast_args in


      let fix_arg arg = 
        let ll_env_arg = codegen_expr llvm func env arg in
        let llv = extract_llv ll_env_arg in

        match classify_type (type_of llv) with
        | Pointer -> 
            let ty = extract_llt ll_env_arg in
            (match classify_ptr ll_env_arg with
            | Array ->
                let str_ptr = build_gep ty llv [| llvm.c64 0; llvm.c64 0 |] "arrptr" llvm.bd in (* ??? build_gep and opaque_ptr should be handled on the receiver (so a build_load is needed????) *)
                str_ptr
            | Integer -> build_load ty llv "farg" llvm.bd (* when this is matched pointer is a variable or an array element*)
            | _ -> assert false) (* structs need to be handled *)
        | Integer -> llv
        | _ -> assert false
      in
      let fixed_args = List.map fix_arg args in

      let ll_args = 
        if upper = 1 then 
          let stackframe =
         FunctionsToFrames.find name func.stack_frames(*createStackFrame llvm env name*) in
          Array.of_list (stackframe::fixed_args) 
        else 
          Array.of_list fixed_args in


      let fty = 
        match lookupST name env with
        | FuncEntry ty -> ty
        | _ -> assert false in
      let frt = return_type fty in
      (match classify_type frt with
      | Void -> build_call fty f ll_args "" llvm.bd
      | Integer ->
          if integer_bitwidth frt == 32 then
            let ret = build_call fty f ll_args (name^"call") llvm.bd in
            build_sext ret llvm.i64 (name^"ret") llvm.bd
          else
            build_call fty f ll_args (name^"ret") llvm.bd
      | _ -> assert false)
      
  | _ -> assert false

and handle_matrix llvm func env lvalue acc =
  match lvalue with
  | L_id var as lvalue         -> (*(codegen_expr llvm env (L_id var))::acc*)
      (* let x = (codegen_expr llvm env (L_id var)) in *)
      (match codegen_expr llvm func env lvalue with
      | CompositeEntry (llv, dims, _) as ce -> ce, acc
      | _              -> assert false)

  | L_string_lit s as lvalue   -> (*(codegen_expr llvm env (L_string_lit s))::acc*)
      (match codegen_expr llvm func env lvalue with
      | CompositeEntry (llv, dims, _) as ce -> ce, acc
      | _              -> assert false)
  | L_matrix (e1, e2) ->
      (* let x = codegen_expr llvm env e2 in
      handle_matrix llvm env e1 (x::acc) *)
      (match codegen_expr llvm func env e2 with
      | BasicEntry (llv, ty) as be -> handle_matrix llvm func env e1 (be::acc)
      | _ -> assert false)
  | _ -> assert false


and codegen_expr llvm func env expr =
  match expr with
  | E_int_const i  -> (BasicEntry (llvm.c64 i, llvm.i64))
  | E_char_const c -> (BasicEntry (llvm.c8 (Char.code c), llvm.i64))
  | L_string_lit s -> 
      let str = const_stringz llvm.ctx s in
      let str_ty = type_of str in
      (* elegxos ypoloipwn syanrthsewn*)

      let str_ptr = build_alloca str_ty "strtmp" llvm.bd in
      let _ = build_store str str_ptr llvm.bd in
      (* let str_ptr = build_gep2 str_ty str_array [| llvm.c32 0; llvm.c32 0 |] "str_ptr" llvm.bd in (* ??? build_gep and opaque_ptr should be handled on the receiver (so a build_load is needed????) *)
      let opaque_ptr = build_bitcast str_ptr (pointer_type2 llvm.ctx) "ptr" llvm.bd in *)

      print_string "reached here\n";
      (* print_string (string_of_llvalue str); *)
      (* print_string (string_of_llvalue str_ptr); *)
      print_string (string_of_lltype (type_of str_ptr));
      CompositeEntry (str_ptr, [1 + String.length s], str_ty)
  | L_id var ->
      lookupST var env (* can be Basic, composite or stackframe entry *)
      (* begin
        match var_ty with
        | i32 when i32 == llvm.i32 -> var_addr, None  (* ean einai function param BY REFERENCE ayto prepei na allajei*)
        | i8 when i8 == llvm.i8    -> var_addr, None 
        | _ ->
          let var_ptr = build_gep2 var_ty var_addr [| llvm.c32 0; llvm.c32 0 |] (var^"ptr") llvm.bd in
          let opaque_ptr = build_bitcast var_ptr (pointer_type2 llvm.ctx) "ptr" llvm.bd in
          opaque_ptr, dims
      end *)
  | L_matrix (e1, e2) as e ->
      (* print_string "reached"; *)
      (* let array_types, dims = List.split (handle_matrix llvm env e []) in *)
      let base_entry, index_entries = handle_matrix llvm func env e [] in
      (* let dims = Option.get (List.hd dims) in *)
      begin
        (* match array_types with
        | array_ptr::indexes -> *)
            let array_llv = extract_llv base_entry in
            let array_ty = (extract_llt base_entry) in (*type_of array_ptr is pointer to the type of array eg [50xi64]*, so element_type is the array type [50xi64] (not pointer) *)
            (* let int_indexes = List.map (fun x -> Int64.to_int (Option.get (int64_of_const x))) indexes in *)
            (* let linear_index = compute_linear_index dims int_indexes in  *)

            let indexes = List.map (fun x ->
              let llv = extract_llv x in
              match classify_type (type_of llv) with
              | Pointer -> build_load (extract_llt x) llv "index_load" llvm.bd
              | _       -> llv
            ) index_entries 
            in

            let dims = extract_array_dims base_entry in
            let llindex = compute_linear_index llvm dims indexes in

          
            (* element_ptr points to the index of the matrix we want *)
            (* let element_ptr = build_gep2 array_ty array_ptr [| llvm.c32 0; llvm.c32 linear_index |] "matrixptr" llvm.bd in *)
            (* element_type of array_ty is the type of an array. if [50xi64] then i64 *)
            let element_ptr = build_gep array_ty array_llv [| llvm.c64 0; llindex |] "matrixptr" llvm.bd in

            (BasicEntry (element_ptr, element_type array_ty)) (* !!! array_ty is wrong here I think *)
        (* | [] -> assert false *)
      end
  | E_fcall stmt -> 
      (match stmt with
      | S_fcall (name, ps) -> 
          let retv = create_fcall llvm func env (S_fcall (name, ps)) in
          (BasicEntry (retv, type_of retv))
      | _ -> assert false)
  | E_op1 (op, e) -> 
      let rhs = codegen_expr llvm func env e in

      let get_value llv =
        match llv with
        | BasicEntry (x, ty) -> (* need to check this (the ty)!!!*)
            (* let ty = type_of x in *)
            (match classify_type (type_of x) with
            | Pointer -> build_load (extract_llt llv) x "op1tmp" llvm.bd (* pointer is a variable or an array element*)
            | Integer -> x
            | _ -> assert false)
        | _ -> assert false
      in
      let rhs_value = get_value rhs in

      begin
        match op with
        | Op_plus  -> (BasicEntry (rhs_value, type_of rhs_value))    (*!!!! this and the below need checking *)
        | Op_minus -> (BasicEntry ((build_neg rhs_value "negtmp" llvm.bd), llvm.i64))
        | _        -> assert false
      end
  | E_op2 (e1, op, e2) -> (* needs checking like the above *)
      let lhs, rhs = codegen_expr llvm func env e1, codegen_expr llvm func env e2 in

      let get_value llv =
        match llv with
        | FuncParamEntry (x, ty) ->
            (match classify_type (type_of x) with
            | Pointer -> build_load (extract_llt llv) x "op2tmp" llvm.bd (* pointer is a variable or an array element*)
            | Integer -> x
            | _ -> assert false)
        | BasicEntry (x, ty) ->
            (* let ty = type_of x in *)
            (match classify_type (type_of x) with
            | Pointer -> build_load (extract_llt llv) x "op2tmp" llvm.bd (* pointer is a variable or an array element*)
            | Integer -> x
            | _ -> assert false)
        | _ -> assert false
      in
      let lhs_value, rhs_value = get_value lhs, get_value rhs in

      match op with
      | Op_plus  -> (BasicEntry ((build_add lhs_value rhs_value "addtmp" llvm.bd), llvm.i64))
      | Op_minus -> (BasicEntry ((build_sub lhs_value rhs_value "subtmp" llvm.bd), llvm.i64))
      | Op_times -> (BasicEntry ((build_mul lhs_value rhs_value "multmp" llvm.bd), llvm.i64))
      | Op_div   -> (BasicEntry ((build_sdiv lhs_value rhs_value "divtmp" llvm.bd), llvm.i64))
      | Op_mod   -> (BasicEntry ((build_srem lhs_value rhs_value "modtmp" llvm.bd), llvm.i64))
      | _        -> assert false

and codegen_cond llvm func env cond =
  match cond with
  | C_bool1 (op, c) ->
    (* body *)
      let rhs = codegen_cond llvm func env c in
      begin
        match op with
        | Op_not -> build_xor rhs (llvm.c1 1) "negtmp" llvm.bd
        | _      -> assert false
      end
  | C_bool2 (c1, op, c2) ->
      let lhs = codegen_cond llvm func env c1 in
      let rhs = codegen_cond llvm func env c2 in
      begin
        match op with
        | Op_and -> build_and lhs rhs "andtmp" llvm.bd
        | Op_or  -> build_or lhs rhs "ortmp" llvm.bd
        | _      -> assert false
      end
  | C_expr (e1, op, e2) -> 
      let lhs = codegen_expr llvm func env e1 in
      let rhs = codegen_expr llvm func env e2 in
      
      let get_value llv = 
        match llv with
        | FuncParamEntry (x, _)
        | BasicEntry (x, _) ->  (* needs checking!!! *)
            (* let ty = type_of x in *)
            (* let element_ty = element_type (type_of llv) in *)
            
            (match classify_type (type_of x) with
            | Pointer -> build_load (extract_llt llv) x "condtmp" llvm.bd (* pointer is a variable or an array element*)
            | Integer -> x
            | _ -> assert false)
        | _ -> assert false
      in
      let lhs = get_value lhs in
      let rhs = get_value rhs in
      
      match op with
      | Op_eq          -> build_icmp Icmp.Eq lhs rhs "eqtmp" llvm.bd
      | Op_hash        -> build_icmp Icmp.Ne lhs rhs "netmp" llvm.bd
      | Op_less        -> build_icmp Icmp.Slt lhs rhs "sltmp" llvm.bd
      | Op_lesseq      -> build_icmp Icmp.Sle lhs rhs "slemp" llvm.bd
      | Op_greater     -> build_icmp Icmp.Sgt lhs rhs "sgtmp" llvm.bd
      | Op_greatereq   -> build_icmp Icmp.Sge lhs rhs "sgemp" llvm.bd
      | _              -> assert false

and codegen_stmt llvm func env stmt = (* isos den xreiazetai to env *)
  match stmt with
  | S_fcall (name, exprs) as fcall -> let _ = create_fcall llvm func env fcall in ()
  | S_colon _ -> ()
  | S_assign (e1, e2) ->
      let dest =
        let l_entry = codegen_expr llvm func env e1 in
        let l = extract_llv l_entry in
      
        (* HERE a way must be found to handle structs *)
        (* let l_ty = element_type (type_of l) in      
        match classify_type l_ty with
        | Struct -> 
            let (original_llv, struct_pos) = extract_struct_info l_entry in
            let first_arg = (params func.the_f).(0) in
            let frame_element_ptr = build_struct_gep2 l_ty first_arg struct_pos "frame_var" llvm.bd in (* to miden prepei na fygei kai na mpei to struct pos*)
            build_load2 (element_type (type_of frame_element_ptr)) frame_element_ptr "lvload" llvm.bd
        | _      ->  in *)

        match classify_type (type_of l) with
        | Pointer ->
            (match classify_ptr l_entry with
            | Integer -> l
                (* let ty = extract_llt l_entry in
                build_load ty l "lvload" llvm.bd *)
            | _ -> assert false) (* structs need to be handled *)
        (* | Integer -> l *)
        | _       -> assert false
      in

      (* print_string ("AAA"^(string_of_lltype (element_type (type_of l)))^"AAA"); *)
      let src =
        let r_entry = codegen_expr llvm func env e2 in
        let r = extract_llv r_entry in
        match classify_type (type_of r) with
        | Pointer ->
            (match classify_ptr r_entry with
            | Integer ->
                let ty = extract_llt r_entry in
                build_load ty r "rvload" llvm.bd
            | _ -> assert false) (* structs need to be handled *)
        | Integer -> r
        | _       -> assert false
      in ignore (build_store src dest llvm.bd)
  | S_block stmts -> List.iter (codegen_stmt llvm func env) stmts
  | S_if (c, s) ->
      let cond = codegen_cond llvm func env c in
      let start_bb = insertion_block llvm.bd in
      let cur_function = block_parent start_bb in

      let then_bb = append_block llvm.ctx "then" cur_function in
      let after_bb = append_block llvm.ctx "after" cur_function in
      let _ = build_cond_br cond then_bb after_bb llvm.bd in

      position_at_end then_bb llvm.bd;
      codegen_stmt llvm func env s;
      let _ = build_br after_bb llvm.bd in

      position_at_end after_bb llvm.bd
  | S_ifelse (c, s1, s2) ->
      let cond = codegen_cond llvm func env c in
      let start_bb = insertion_block llvm.bd in
      let cur_function = block_parent start_bb in

      let then_bb = append_block llvm.ctx "then" cur_function in
      let else_bb = append_block llvm.ctx "else" cur_function in
      let merge_bb = append_block llvm.ctx "ifafter" cur_function in
      let _ = build_cond_br cond then_bb else_bb llvm.bd in

      position_at_end then_bb llvm.bd;
      codegen_stmt llvm func env s1;
      let _ = build_br merge_bb llvm.bd in 
      
      position_at_end else_bb llvm.bd;
      codegen_stmt llvm func env s2;
      let _ = build_br merge_bb llvm.bd in

      position_at_end merge_bb llvm.bd;
  | S_while (c, s) ->
      let start_bb = insertion_block llvm.bd in
      let cur_function = block_parent start_bb in
    
      let cond_bb = append_block llvm.ctx "cond" cur_function in
      let loop_bb = append_block llvm.ctx "loop" cur_function in
      let after_bb = append_block llvm.ctx "afterloop" cur_function in
      let _ = build_br cond_bb llvm.bd in

      position_at_end cond_bb llvm.bd;
      let cond = codegen_cond llvm func env c in
      let _ = build_cond_br cond loop_bb after_bb llvm.bd in

      position_at_end loop_bb llvm.bd;
      codegen_stmt llvm func env s;
      let _ = build_br cond_bb llvm.bd in

      position_at_end after_bb llvm.bd;

  | S_return e ->
      match e with
      | Some expr ->
          let n = 
            match codegen_expr llvm func env expr with
            | BasicEntry (x, _) -> x
            | _            -> assert false
          in
          ignore (build_ret n llvm.bd)
      | None -> ignore (build_ret_void llvm.bd)







let params_to_names_and_lltypes llvm fparams =
  let fparams_helper acc params = 
    match params with
    | F_params (r, vars, t) -> 
        (match r with
        | Some _  -> 
            let ty, _ = type_to_lltype llvm t in
            vars::acc, List.map (fun _ -> llvm.ptr, Some ty) vars
        | None -> 
            let ty, _ = type_to_lltype llvm t in 
            vars::acc, List.map (fun _ -> ty, None) vars)
    | _ -> assert false in

  (* the logic behind this is that we accumulate all variable names and map each variable to its type *)
  List.fold_left_map (fparams_helper) [] fparams  (* returns a tuple: string list list, lltype list list*)
  |> fun (names, lltypes) -> 
      List.(rev names |> concat, lltypes |> concat)

let codegen_fhead llvm sframe head = (* ayto kalo einai na ginei merge me to codegen_decl *)
  match head with
  | F_head (name, params, t) ->
      let frt, _ = type_to_lltype llvm t in
      let var_names, fparams =
        match params with
        | Some ps -> params_to_names_and_lltypes llvm ps (* fparams_to_llarray returns list, not array :) *)
        | None    -> [], [] in
      (* List.iter print_string var_names; *)
      let lltypes, pointer_types = List.split fparams in
      begin
        match sframe with
        | Some _ -> (name, var_names, pointer_types, function_type frt (Array.of_list (llvm.ptr::lltypes)))
        | None   -> (name, var_names, pointer_types, function_type frt (Array.of_list lltypes))
      end
  | _ -> assert false

let rec addVars llvm env vars (t, dims) = (* edw prepei na ginei handle to duplicate vars h isws sto semantic*)
  match vars with (* ayth h synarthsh mporei na fygei mallon teleiws kai na ginei me foldl*)
  | hd::tl -> 
      let alloca_addr = build_alloca t hd llvm.bd in (* edw o builder einai hdh sthn arxh ths synarthshs wste na paijei to mem2reg *)
      let newST = 
        match dims with
        | None   -> insertST env hd (BasicEntry (alloca_addr, t))
        | Some l -> insertST env hd (CompositeEntry (alloca_addr, l, t))
      in addVars llvm newST tl (t, dims)
  | [] -> env




let rec codegen_decl llvm sframe env decl =
  match decl with
  | F_def (h, locals, block) ->

      let (name, var_names, pointer_types, ft) = 
        if !first_function = true then (
          let (_, param_names, pointer_types, ft) = codegen_fhead llvm sframe h in
          first_function := false;
          ("main", param_names, pointer_types, ft))
        else
          codegen_fhead llvm sframe h
      in
      
      

      let f = 
        match lookup_function name llvm.md with (* search for function "name" in the ctx *)
        | None -> declare_function name ft llvm.md (*here what happens when a function is redefined locally?*)
        | Some f ->
            if Array.length (basic_blocks f) = 0 then () else
              raise (Failure "redefinition of function");
            if Array.length (params f) = Array.length (param_types ft) then () else
              raise (Failure "redefinition of function with different # args");
            f in

      
      let env = insertST env name (FuncEntry ft) in


      let env = 
        if List.length var_names <> 0 then 
          List.fold_left2 (fun e (name, pty) param ->
            set_value_name name param;
            insertST e name (FuncParamEntry (param, pty))
          ) env (List.combine var_names pointer_types) (params f |> Array.to_list |> List.tl) 
        else
          env in

      (* print_string ((string_of_llvalue f));
      Array.iter (fun x -> print_string ("\t"^(string_of_llvalue x)^"\n")) (params f);
      printllvmST env; *)


      (* if name <> "main" then set_value_name (Option.get sname) (params f).(0); *)
      (* set names for arguments *)
      let bb = append_block llvm.ctx (name ^ "_entry") f in
      position_at_end bb llvm.bd;

      let func_info = {
        the_f = f;
        stack_frames = 
          match sframe with
          | Some frame -> FunctionsToFrames.empty |> FunctionsToFrames.add name frame
          | None       -> FunctionsToFrames.empty
          (* if name = "main" then FunctionsToFrames.empty
          else FunctionsToFrames.empty |> FunctionsToFrames.add; *)
      } in

      (*handle locals and block*)
      let func_info, local_env = List.fold_left (codegen_localdef llvm bb) (func_info, env) locals in
      (* edw thelei skepsi gia to pws tha mpoun oi times twn local-defs: den thelw tis times pou eisagei to definition mias fucntion*)
      
      position_at_end bb llvm.bd;
      (* body *)
      codegen_stmt llvm func_info local_env block;


        let helper x =
          match block_terminator x with
          | Some _ -> ()
          | None   -> ignore (build_ret_void llvm.bd) in  (* mia int synarthsh prepei na kanei return kati akoma kai an den yparxei to return mesa se ayth? den jerw an entopizetai (apo ton semantic analyzer) mia int synarthsh pou den exei kapoio return *)
        iter_blocks helper f;

      
      (* Llvm_analysis.assert_valid_function f; *)
      (* env *)



      print_string (name^"_ST\n");
      printllvmST local_env;



      (* insertST env name (FuncEntry ft) *)
      env


  | _         -> assert false

and codegen_localdef llvm entryBB (func, env) local = (*entryBB is the function's entry block *)
  match local with
  | F_def (h, locals, block) as fdef ->
      let name =
        match h with
        | F_head (name, _, _) -> name
        | _ -> assert false in
      
      let frame_ptr, newST = createStructType llvm env name in
      let _, _,_, ft = codegen_fhead llvm (Some frame_ptr) h in
      let _ = codegen_decl llvm (Some frame_ptr) newST fdef in 

      let env = insertST env name (FuncEntry ft) in  (* frame_ptr is dummy here, just to fill a gap: it needs to be replaced by the function f*)
      ({func with stack_frames = FunctionsToFrames.add name frame_ptr func.stack_frames}, env)

  | F_decl h -> (* this should be used for function definitions as well*)
      (*let (name, var_names, pointer_types, ft) = codegen_fhead llvm None  h in
       let f =  this has some role but I have not looked into it
        match lookup_function name llvm.md with 
        | None -> declare_function name ft llvm.md (* !!! here what happens when a function is redefined locally?*)
        | Some f ->
            if Array.length (basic_blocks f) = 0 then () else
              raise (Failure "redefinition of function");
            if Array.length (params f) = Array.length (param_types ft) then () else
              raise (Failure "redefinition of function with different # args");
            f 
      in *)
      (* insertST env name (f, None) *)
      (func, env)
  | V_def (vars, t) -> 
      position_at_end entryBB llvm.bd;
      let llty, dims = type_to_lltype llvm t in
      (* let dims = Option.get dims in *)
      (func, addVars llvm env vars (llty, dims))  (* isws anti na kalw thn addvars na mporei na ginei olo ayto me foldl*)
  | _ -> assert false

let llvm_compile_and_dump asts =
  (* Initialize LLVM: context, module, builder and FPM*)
  Llvm_all_backends.initialize ();
  let ctx = global_context () in
  let md = create_module ctx "grace program" in
  let builder = builder ctx in
  let fpm = PassManager.create () in
  List.iter (fun optim -> optim fpm) [
    Llvm_scalar_opts.add_memory_to_register_promotion;
    Llvm_scalar_opts.add_instruction_combination;
    Llvm_scalar_opts.add_reassociation;
    Llvm_scalar_opts.add_gvn;
    Llvm_scalar_opts.add_cfg_simplification;
  ]; (*maybe add some more??? *)
  (* Initialize types *)
  let i1 = i1_type ctx in
  let i8 = i8_type ctx in
  let i32 = i32_type ctx in
  let i64 = i64_type ctx in
  let void = void_type ctx in
  let ptr = pointer_type ctx in
  (* Initialize constant types *)
  let c1 = const_int i1 in
  let c8 = const_int i8 in
  let c32 = const_int i32 in
  let c64 = const_int i64 in


  (* Initialize library functions and add them to the Symbol Table *)
  let writeInteger_ty = function_type void [| i64 |] in
  let writeChar_ty = function_type void [| i8 |] in
  let writeString_ty = function_type void [| ptr |] in (*maybe pointer_type i8 should be used?*)
  let readInteger_ty = function_type i64 [| |] in
  let readChar_ty = function_type i8 [| |] in
  let readString_ty = function_type void [| i64; ptr |] in
  let ascii_ty = function_type i32 [| i8 |] in
  let chr_ty = function_type i8 [| i64 |] in
  let strlen_ty = function_type i32 [| ptr |] in
  let strcmp_ty = function_type i32 [| ptr; ptr |] in
  let strcpy_ty = function_type void [| ptr; ptr |] in
  let strcat_ty = function_type void [| ptr; ptr |] in
  
  let _ = declare_function "writeInteger" writeInteger_ty md in
  let _ = declare_function "writeChar" writeChar_ty md in
  let _ = declare_function "writeString" writeString_ty md in
  let _ = declare_function "readInteger" readInteger_ty md in
  let _ = declare_function "readChar" readChar_ty md in
  let _ = declare_function "readString" readString_ty md in
  let _ = declare_function "ascii" ascii_ty md in
  let _ = declare_function "chr" chr_ty md in
  let _ = declare_function "strlen" strlen_ty md in
  let _ = declare_function "strcmp" strcmp_ty md in
  let _ = declare_function "strcpy" strcpy_ty md in
  let _ = declare_function "strcat" strcat_ty md in

  

  let predefined = ["writeInteger"; "writeChar"; "writeString"; 
                    "readInteger"; "readChar"; "readString"; 
                    "ascii"; "chr"; "strlen"; "strcmp"; 
                    "strcpy"; "strcat"] in

  let predefined_types = [writeInteger_ty; writeChar_ty; writeString_ty; 
                          readInteger_ty; readChar_ty; readString_ty; 
                          ascii_ty; chr_ty; strlen_ty; strcmp_ty;
                          strcpy_ty; strcat_ty] in

  let env = 
    List.fold_left2 (fun e name fty -> 
      insertST e name (FuncEntry fty)
    ) emptyST predefined predefined_types in
  (* c1 1 is dummy here (and everywhere else in FuncEntry as well!) *)
  
    (* let predefined_env = addPredefined emptyST in *)

  (* gather all info in a record for later use *)
  let info = {
    ctx              = ctx;
    md               = md;
    bd               = builder;
    i1               = i1;
    i8               = i8;
    i32              = i32;
    i64              = i64;
    c1               = c1;
    c8               = c8;
    c32              = c32;
    c64              = c64;
    void             = void;
    ptr              = ptr;
    predefined_fs    = predefined;
  } in


  (* Emit the program code and add return value to main function *)
  ignore (codegen_decl info None env asts);
  (* ignore (build_ret (c32 0) builder); *)

  (* Verify the entire module*)
  (* Llvm_analysis.assert_valid_module md; *)

  (* Optimize *) (* this must be optional *)
  (* ignore (PassManager.run_module md fpm); *)

  (* Print out the IR *)
  print_module "llvm_ir.ll" md;; (* dump_module to print in stdout*)




(* let () = llvm_compile_and_dump 5; *)