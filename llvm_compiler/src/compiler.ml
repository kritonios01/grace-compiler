open Llvm
open Ast
open Symbol
open TypeKind

(* edw to ST apothikevei tis thesei mnimis opou apothikevontai ta locals *)


let first_function = ref true (* first function in llvm ir must be called main, but grace syntax allows any name for a program's main function*)
let f_has_ret = ref false

(* keep the llvm settings in a record*)
type llvm_info = {
  context          : llcontext;
  the_module       : llmodule;
  builder          : llbuilder;
  i1               : lltype;
  i8               : lltype;
  i32              : lltype;
  i64              : lltype;
  c1               : int -> llvalue;
  c8               : int -> llvalue;
  c32              : int -> llvalue;
  c64              : int -> llvalue;
  void             : lltype;
  predefined_fs    : string list;
}

module FunctionsToFrames = Map.Make(String)

(* in each function, keep its information*)
type func_info = {
  the_f   : llvalue;
  stack_frames : llvalue FunctionsToFrames.t;
}

(* helper function to compute index of linearized multi-dim array*)
(* this must be changed so that it computs indices in assembly and not in ocaml*)
let compute_linear_index dimensions indices =
  let rec aux acc dims indices =
    match dims, indices with
    | [], [] -> acc
    | d :: rest_dims, i :: rest_indices ->
      let acc' = acc * d + i in
      aux acc' rest_dims rest_indices
    | _ -> failwith "Mismatched dimensions and indices"
  in
  aux 0 dimensions indices

  
let compute_linear_index2 llvm dims indices =
  let open List in
  (* let int_type = i32_type llvm.context in *)
  let zero = llvm.c64 0 in
  let one = llvm.c64 1 in
  
  (* Reverse dimensions for easier processing, because we calculate from the last dimension *)
  let rev_dims = rev dims in
  
  (* Function to fold over each dimension and index to generate the multiplication and addition *)
  let folder (acc, prod) (dim, index) =
    let dim_val = llvm.c64 dim in
    let offset = build_mul index prod "multmp" llvm.builder in
    let new_acc = build_add acc offset "addtmp" llvm.builder in
    let new_prod = build_mul prod dim_val "prodtmpp" llvm.builder in
    (new_acc, new_prod)
  in
  
  (* Initial accumulator for fold is (0, 1) because index = 0 + i_1 * 1 initially *)
  let initial = (zero, one) in

  (* Process each dimension and its corresponding index *)
  let (linear_index, _) = fold_left folder initial (combine rev_dims (rev indices)) in
  
  linear_index
  



let extract_entry x =
  match x with
  | BasicEntry llv -> llv
  | StackFrameEntry (_, struct_, _) -> struct_
  | _ -> assert false

let extract_struct_info x =
  match x with
  | StackFrameEntry (orig, _, pos) -> (orig, pos)  (* isos na min xreiazetai katholou to original, px sto S_assign *)
  | _ -> assert false


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
  let frame = named_struct_type llvm.context ("frame."^fname) in
  let keys, values = llvmSTvalues env in
  let st_pairs = List.combine keys values in
  struct_set_body frame (Array.of_list (List.map type_of values)) false;
  (* List.iter (fun x -> print_string (string_of_lltype (type_of x))) values; *)

  let frame_ptr = build_alloca frame ("frame."^fname^"_ptr") llvm.builder in
  
  (* prepei na ginei kapoio filtering wste na min vazei ta panta *)
  if List.length st_pairs <> 0 then (* store each value in ST in the struct and update the ST so that these values point to their new place *)
    let store_and_updateST (index, env) (k, v) =
      let base = (build_struct_gep2 frame frame_ptr index ("frame_elem_"^(string_of_int index)) llvm.builder) in
      (* print_string (string_of_llvalue (base)); *)
      (* print_char '\n'; *)
      (* print_string (string_of_llvalue (v)); *)
      (* print_string "\n"; *) 
      print_string (string_of_lltype (element_type (type_of base)));
      (* print_string (string_of_lltype (element_type (type_of v))); *)
      (* let opaq = build_bitcast base (pointer_type2 llvm.context) "ptr" llvm.builder in *)
    
      (* print_char '\n'; *)
      (* print_string (string_of_lltype (type_of v)); *)
      print_string "\n\n";


      ignore (build_store v base llvm.builder); 

      let replace x =
        match x with
        | Some ll_entry ->
            (match ll_entry with
            | BasicEntry _ 
            | CompositeEntry (_, _) 
            | FuncParamEntry _          -> Some (StackFrameEntry (ll_entry, frame_ptr, index))
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
  | S_fcall (name, exprs) -> (* otan kaleitai mia synarthsh prepei na kanei alloca ta vars ths?? *)
      let f = 
        match lookup_function name llvm.the_module with
        | Some f -> f
        | None -> raise (Failure "unknown function referenced") in
      let frt = (return_type (type_of f)) in (*regarding these: for writeInt (f is void (i64)* ), (type_of f is void (i64)), (element_type type_of f is void)*)
      let actual_frt = element_type frt in
      let params = params f in
      let upper = if List.mem name llvm.predefined_fs then 0 else 1 in (* ayto einai hardcoded -> kako. an ginoun override oi predefined den tha paizei swsta. ousiastika ayto ginetai gia na min pernaei stack frame stis prokathorismenes synarthseis oi opoies einia vevaio oti xreiazontai mono tis parametrous tous. enallaktika gia aplothta tha mporouse na pernaei to stack frame kai se aytes kai as einai axreiasto *)
      let ll_args =
        match exprs with
        | Some es -> 
            if Array.length params = List.length es + upper then () else
              raise (Failure (name^"(...): incorrect # arguments passed"));
            (* let params, _ = List.split (List.map (codegen_expr llvm env) es) in *)
            let params =
              let get_llv x =
                match x with
                | BasicEntry v -> v
                | CompositeEntry (v, _) -> v
                | FuncParamEntry v      -> v
                | _ -> assert false in
              List.map (fun x -> get_llv (codegen_expr llvm func env x)) es in

            (* List.iter (fun x -> print_string (string_of_llvalue x)) params; to be removed *)
            params
        | None ->
            if Array.length params = 0 + upper then () else
              raise (Failure (name^"(): incorrect # arguments passed"));
            []
      in

      (* print_string (string_of_lltype (type_of f)); *)
      

      let fix_arg arg = 
        let ty = type_of arg in
        let element_ty = element_type (type_of arg) in
        (* print_string ((string_of_lltype (type_of arg)) ^ " ");
        print_string ((string_of_lltype (element_type (type_of arg))) ^ " "); *)
        match classify_type ty with (* ola ayta ejartwntai apo to an einai ref!*)
        | Pointer -> 
            begin
              match classify_type element_ty with
              | Array -> 
                  let str_ptr = build_gep2 element_ty arg [| llvm.c64 0; llvm.c64 0 |] "arrptr" llvm.builder in (* ??? build_gep and opaque_ptr should be handled on the receiver (so a build_load is needed????) *)
                  let opaque_ptr = build_bitcast str_ptr (pointer_type2 llvm.context) "ptr" llvm.builder in
                  opaque_ptr
              | _ -> build_load2 element_ty arg "farg" llvm.builder (* pointer is a variable or an array element*)
            end
        | Integer -> arg
        | _ -> raise (Failure "aa")
          
          (* let var_ptr = build_gep2 ty arg [| llvm.c32 0; llvm.c32 0 |] ("farg"^"ptr") llvm.builder in
          let opaque_ptr = build_bitcast var_ptr (pointer_type2 llvm.context) "ptr" llvm.builder in
          opaque_ptr *)
      in
      let fixed_args = List.map fix_arg ll_args in
      let ll_args = 
        if upper = 1 then 
          let stackframe = FunctionsToFrames.find name func.stack_frames(*createStackFrame llvm env name*) in
          Array.of_list (stackframe::fixed_args) 
        else 
          Array.of_list fixed_args in


      begin
        match classify_type actual_frt with
        | Void -> build_call2 frt f ll_args "" llvm.builder
        | Integer ->
            if integer_bitwidth actual_frt == 32 then
              let ret = build_call2 frt f ll_args (name^"call") llvm.builder in
              build_sext ret llvm.i64 (name^"ret") llvm.builder
            else
              build_call2 frt f ll_args (name^"ret") llvm.builder
        | _ -> assert false
      end
  | _ -> assert false

and handle_matrix llvm func env lvalue acc =
  match lvalue with
  | L_id var as lvalue         -> (*(codegen_expr llvm env (L_id var))::acc*)
      (* let x = (codegen_expr llvm env (L_id var)) in *)
      (match codegen_expr llvm func env lvalue with
      | CompositeEntry (llv, dims) -> (llv, dims), acc
      | _              -> assert false)

  | L_string_lit s as lvalue   -> (*(codegen_expr llvm env (L_string_lit s))::acc*)
      (match codegen_expr llvm func env lvalue with
      | CompositeEntry (llv, dims) -> (llv, dims), acc
      | _              -> assert false)
  | L_matrix (e1, e2) ->
      (* let x = codegen_expr llvm env e2 in
      handle_matrix llvm env e1 (x::acc) *)
      (match codegen_expr llvm func env e2 with
      | BasicEntry llv -> handle_matrix llvm func env e1 (llv::acc)
      | _ -> assert false)
  | _ -> assert false


and codegen_expr llvm func env expr =
  match expr with
  | E_int_const i  -> (BasicEntry (llvm.c64 i))
  | E_char_const c -> (BasicEntry (llvm.c8 (Char.code c)))
  | L_string_lit s -> 
      let str = const_stringz llvm.context s in
      let str_ty = type_of str in
      (* elegxos ypoloipwn syanrthsewn*)

      let str_ptr = build_alloca str_ty "strtmp" llvm.builder in
      let _ = build_store str str_ptr llvm.builder in
      (* let str_ptr = build_gep2 str_ty str_array [| llvm.c32 0; llvm.c32 0 |] "str_ptr" llvm.builder in (* ??? build_gep and opaque_ptr should be handled on the receiver (so a build_load is needed????) *)
      let opaque_ptr = build_bitcast str_ptr (pointer_type2 llvm.context) "ptr" llvm.builder in *)
      CompositeEntry (str_ptr, [1 + String.length s])
  | L_id var ->
      lookupST var env (* can be Basic, composite or stackframe entry *)
      (* begin
        match var_ty with
        | i32 when i32 == llvm.i32 -> var_addr, None  (* ean einai function param BY REFERENCE ayto prepei na allajei*)
        | i8 when i8 == llvm.i8    -> var_addr, None 
        | _ ->
          let var_ptr = build_gep2 var_ty var_addr [| llvm.c32 0; llvm.c32 0 |] (var^"ptr") llvm.builder in
          let opaque_ptr = build_bitcast var_ptr (pointer_type2 llvm.context) "ptr" llvm.builder in
          opaque_ptr, dims
      end *)
  | L_matrix (e1, e2) as e ->
      (* let array_types, dims = List.split (handle_matrix llvm env e []) in *)
      let (array_ptr, dims), indexes = handle_matrix llvm func env e [] in
      (* let dims = Option.get (List.hd dims) in *)
      begin
        (* match array_types with
        | array_ptr::indexes -> *)
            let array_ty = element_type (type_of array_ptr) in (*type_of array_ptr is pointer to the type of array eg [50xi64]*, so element_type is the array type [50xi64] (not pointer) *)
            (* let int_indexes = List.map (fun x -> Int64.to_int (Option.get (int64_of_const x))) indexes in *)
            (* let linear_index = compute_linear_index dims int_indexes in  *)

            let indexes = List.map (fun x ->
              match classify_type (type_of x) with
              | Pointer -> build_load2 (element_type (type_of x)) x "index_load" llvm.builder
              | _       -> x
            ) indexes in

            let llindex = compute_linear_index2 llvm dims indexes in

          
            (* element_ptr points to the index of the matrix we want *)
            (* let element_ptr = build_gep2 array_ty array_ptr [| llvm.c32 0; llvm.c32 linear_index |] "matrixptr" llvm.builder in *)
            (* element_type of array_ty is the type of an array. if [50xi64] then i64 *)
            let element_ptr = build_gep2 array_ty array_ptr [| llvm.c64 0; llindex |] "matrixptr" llvm.builder in

            (BasicEntry element_ptr)
        (* | [] -> assert false *)
      end
  | E_fcall stmt -> 
      (match stmt with
      | S_fcall (name, ps) -> 
          let retv = create_fcall llvm func env (S_fcall (name, ps)) in
          (BasicEntry retv)
      | _ -> assert false)
  | E_op1 (op, e) -> 
      let rhs = codegen_expr llvm func env e in

      let get_value llv =
        match llv with
        | BasicEntry x ->
            let ty = type_of x in
            (match classify_type ty with
            | Pointer -> build_load2 (element_type ty) x "condtmp" llvm.builder (* pointer is a variable or an array element*)
            | Integer -> x
            | _ -> assert false)
        | _ -> assert false
      in
      let rhs_value = get_value rhs in

      begin
        match op with
        | Op_plus  -> (BasicEntry rhs_value)
        | Op_minus -> (BasicEntry (build_neg rhs_value "negtmp" llvm.builder))
        | _        -> assert false
      end
  | E_op2 (e1, op, e2) ->
      let lhs, rhs = codegen_expr llvm func env e1, codegen_expr llvm func env e2 in

      let get_value llv =
        match llv with
        | BasicEntry x ->
            let ty = type_of x in
            (match classify_type ty with
            | Pointer -> build_load2 (element_type ty) x "condtmp" llvm.builder (* pointer is a variable or an array element*)
            | Integer -> x
            | _ -> assert false)
        | _ -> assert false
      in
      let lhs_value, rhs_value = get_value lhs, get_value rhs in

      match op with
      | Op_plus  -> (BasicEntry (build_add lhs_value rhs_value "addtmp" llvm.builder))
      | Op_minus -> (BasicEntry (build_sub lhs_value rhs_value "subtmp" llvm.builder))
      | Op_times -> (BasicEntry (build_mul lhs_value rhs_value "multmp" llvm.builder))
      | Op_div   -> (BasicEntry (build_sdiv lhs_value rhs_value "divtmp" llvm.builder))
      | Op_mod   -> (BasicEntry (build_srem lhs_value rhs_value "modtmp" llvm.builder))
      | _        -> assert false

and codegen_cond llvm func env cond =
  match cond with
  | C_bool1 (op, c) ->
    (* body *)
      let rhs = codegen_cond llvm func env c in
      begin
        match op with
        | Op_not -> build_xor rhs (llvm.c1 1) "negtmp" llvm.builder
        | _      -> assert false
      end
  | C_bool2 (c1, op, c2) ->
      let lhs = codegen_cond llvm func env c1 in
      let rhs = codegen_cond llvm func env c2 in
      begin
        match op with
        | Op_and -> build_and lhs rhs "andtmp" llvm.builder
        | Op_or  -> build_or lhs rhs "ortmp" llvm.builder
        | _      -> assert false
      end
  | C_expr (e1, op, e2) -> 
      let lhs = codegen_expr llvm func env e1 in
      let rhs = codegen_expr llvm func env e2 in
      
      let get_value llv = 
        match llv with
        | BasicEntry x ->
            let ty = type_of x in
            (* let element_ty = element_type (type_of llv) in *)
            (match classify_type ty with
            | Pointer -> build_load2 (element_type ty) x "condtmp" llvm.builder (* pointer is a variable or an array element*)
            | Integer -> x
            | _ -> assert false)
        | _ -> assert false
      in
      let lhs = get_value lhs in
      let rhs = get_value rhs in
      
      match op with
      | Op_eq          -> build_icmp Icmp.Eq lhs rhs "eqtmp" llvm.builder
      | Op_hash        -> build_icmp Icmp.Ne lhs rhs "netmp" llvm.builder
      | Op_less        -> build_icmp Icmp.Slt lhs rhs "sltmp" llvm.builder
      | Op_lesseq      -> build_icmp Icmp.Sle lhs rhs "slemp" llvm.builder
      | Op_greater     -> build_icmp Icmp.Sgt lhs rhs "sgtmp" llvm.builder
      | Op_greatereq   -> build_icmp Icmp.Sge lhs rhs "sgemp" llvm.builder
      | _              -> assert false

and codegen_stmt llvm func env stmt = (* isos den xreiazetai to env *)
  match stmt with
  | S_fcall (name, exprs) as fcall -> let _ = create_fcall llvm func env fcall in ()
  | S_colon _ -> ()
  | S_assign (e1, e2) ->
      (* let l = 
        match codegen_expr llvm env e1 with
        | BasicEntry x -> x
        | StackFrameEntry (src, stack, pos) -> stack
        | _            -> assert false
      in *)
      let r = (* ayto prepei na fygei kai na ginei opws to l *)
        match codegen_expr llvm func env e2 with
        | BasicEntry x -> x
        | _            -> assert false
      in
      let dest =
        let l_entry = codegen_expr llvm func env e1 in
        let l = extract_entry l_entry in

        let l_ty = element_type (type_of l) in
        match classify_type l_ty with
        | Struct -> 
            let (original_llv, struct_pos) = extract_struct_info l_entry in
            let first_arg = (params func.the_f).(0) in
            let frame_element_ptr = build_struct_gep2 l_ty first_arg struct_pos "frame_var" llvm.builder in (* to miden prepei na fygei kai na mpei to struct pos*)
            build_load2 (element_type (type_of frame_element_ptr)) frame_element_ptr "lvload" llvm.builder
        | _      -> l in
      (* print_string ("AAA"^(string_of_lltype (element_type (type_of l)))^"AAA"); *)
      let src =
        match classify_type (type_of r) with
        | Pointer -> build_load2 (element_type (type_of r)) r "rvload" llvm.builder
        | _       -> r
      in ignore (build_store src dest llvm.builder)
  | S_block stmts -> List.iter (codegen_stmt llvm func env) stmts
  | S_if (c, s) ->
      let cond = codegen_cond llvm func env c in
      let start_bb = insertion_block llvm.builder in
      let cur_function = block_parent start_bb in

      let then_bb = append_block llvm.context "then" cur_function in
      let after_bb = append_block llvm.context "after" cur_function in
      let _ = build_cond_br cond then_bb after_bb llvm.builder in

      position_at_end then_bb llvm.builder;
      codegen_stmt llvm func env s;
      let _ = build_br after_bb llvm.builder in

      position_at_end after_bb llvm.builder
  | S_ifelse (c, s1, s2) ->
      let cond = codegen_cond llvm func env c in
      let start_bb = insertion_block llvm.builder in
      let cur_function = block_parent start_bb in

      let then_bb = append_block llvm.context "then" cur_function in
      let else_bb = append_block llvm.context "else" cur_function in
      let merge_bb = append_block llvm.context "ifafter" cur_function in
      let _ = build_cond_br cond then_bb else_bb llvm.builder in

      position_at_end then_bb llvm.builder;
      codegen_stmt llvm func env s1;
      let _ = build_br merge_bb llvm.builder in 
      
      position_at_end else_bb llvm.builder;
      codegen_stmt llvm func env s2;
      let _ = build_br merge_bb llvm.builder in

      position_at_end merge_bb llvm.builder;
  | S_while (c, s) ->
      let start_bb = insertion_block llvm.builder in
      let cur_function = block_parent start_bb in
    
      let cond_bb = append_block llvm.context "cond" cur_function in
      let loop_bb = append_block llvm.context "loop" cur_function in
      let after_bb = append_block llvm.context "afterloop" cur_function in
      let _ = build_br cond_bb llvm.builder in

      position_at_end cond_bb llvm.builder;
      let cond = codegen_cond llvm func env c in
      let _ = build_cond_br cond loop_bb after_bb llvm.builder in

      position_at_end loop_bb llvm.builder;
      codegen_stmt llvm func env s;
      let _ = build_br cond_bb llvm.builder in

      position_at_end after_bb llvm.builder;

  | S_return e ->
      match e with
      | Some expr ->
          let n = 
            match codegen_expr llvm func env expr with
            | BasicEntry x -> x
            | _            -> assert false
          in
          ignore (build_ret n llvm.builder)
      | None -> ignore (build_ret_void llvm.builder)







let params_to_names_and_lltypes llvm fparams =
  let fparams_helper acc params = 
    match params with
    | F_params (r, vars, t) -> 
        (match r with
        | Some _  -> vars::acc, List.map (fun _ -> pointer_type2 llvm.context) vars
        | None -> 
            let ty, _ = type_to_lltype llvm t in 
            vars::acc, List.map (fun _ -> ty) vars)
    | _ -> assert false in

  (* the logic behind this is that we accumulate all variable names and map each variable to its type *)
  List.fold_left_map (fparams_helper) [] fparams  (* returns a tuple: string list list, lltype list list*)
  |> fun (names, lltypes) -> 
      List.(rev names |> concat, lltypes |> concat)

let codegen_fhead llvm sframe head = (* ayto kalo einai na ginei merge me to codegen_decl *)
  match head with
  | F_head (name, params, t) ->
      let ftype, _ = type_to_lltype llvm t in
      let var_names, fparams =
        match params with
        | Some ps -> params_to_names_and_lltypes llvm ps (* fparams_to_llarray returns list, not array :) *)
        | None    -> [], [] in
      (* List.iter print_string var_names; *)
      begin
        match sframe with
        | Some s -> (name, var_names, function_type ftype (Array.of_list (type_of s::fparams)))
        | None   -> (name, var_names, function_type ftype (Array.of_list fparams))
      end
  | _ -> assert false

let rec addVars llvm env vars (t, dims) = (* edw prepei na ginei handle to duplicate vars h isws sto semantic*)
  match vars with (* ayth h synarthsh mporei na fygei mallon teleiws kai na ginei me foldl*)
  | hd::tl -> 
      let alloca_addr = build_alloca t hd llvm.builder in (* edw o builder einai hdh sthn arxh ths synarthshs wste na paijei to mem2reg *)
      let newST = 
        match dims with
        | None   -> insertST env hd (BasicEntry alloca_addr)
        | Some l -> insertST env hd (CompositeEntry (alloca_addr, l))
      in addVars llvm newST tl (t, dims)
  | [] -> env




let rec codegen_decl llvm sframe env decl =
  match decl with
  | F_def (h, locals, block) ->

      let (name, var_names, ft) = 
        if !first_function = true then (
          let (_, param_names, ft) = codegen_fhead llvm sframe h in
          first_function := false;
          ("main", param_names, ft))
        else
          codegen_fhead llvm sframe h
      in
      
      

      let f = 
        match lookup_function name llvm.the_module with (* search for function "name" in the context *)
        | None -> declare_function name ft llvm.the_module (*here what happens when a function is redefined locally?*)
        | Some f ->
            if Array.length (basic_blocks f) = 0 then () else
              raise (Failure "redefinition of function");
            if Array.length (params f) = Array.length (param_types ft) then () else
              raise (Failure "redefinition of function with different # args");
            f in

      



      let env = 
        if List.length var_names <> 0 then 
          List.fold_left2 (fun e name param ->
            set_value_name name param;
            insertST e name (FuncParamEntry param)
          ) env var_names (params f |> Array.to_list |> List.tl) 
        else
          env in

      (* print_string ((string_of_llvalue f));
      Array.iter (fun x -> print_string ("\t"^(string_of_llvalue x)^"\n")) (params f);
      printllvmST env; *)


      (* if name <> "main" then set_value_name (Option.get sname) (params f).(0); *)
      (* set names for arguments *)
      let bb = append_block llvm.context (name ^ "_entry") f in
      position_at_end bb llvm.builder;

      let func_info = {
        the_f = f;
        stack_frames = FunctionsToFrames.empty;
      } in

      (*
      let x = named_struct_type llvm.context ("frame."^name) in (*na xrhsimopoihthei struct type*)
      (* print_string ((string_of_lltype x)^"\n"); *)
      let keys, values = List.split (SymbolTable.bindings env) in
      let values, _ = List.split values in
      struct_set_body x (Array.of_list (List.map type_of values)) false;
      (* struct_set_body x [| pointer_type llvm.i8; type_of (llvm.c32 2)|] false; *)
      (* print_string ((string_of_lltype x)^"\n"); *)
      let frame_ptr = build_alloca x "frame_ptr" llvm.builder in
      (* print_string (string_of_llvalue ( frame_ptr)^"\n"); *)
      if Array.length (struct_element_types x) <> 0 then
        let base_and_store struct_ty index element =
          let base = (build_struct_gep2 struct_ty frame_ptr index "frame0" llvm.builder) in
          ignore (build_store element base llvm.builder); 
          index+1 
        in ignore (List.fold_left (base_and_store x) 0 values);
      else ();
      *)


      (* create a place in memory to store return value *)
      (* let retv_addr = build_alloca llvm.i32 "retvptr" llvm.builder in
      let env = insertST env "retvptr_grace" (retv_addr, None) in *)

      (*handle locals and block*)
      let func_info, local_env = List.fold_left (codegen_localdef llvm bb) (func_info, env) locals in
      (* edw thelei skepsi gia to pws tha mpoun oi times twn local-defs: den thelw tis times pou eisagei to definition mias fucntion*)
      
      position_at_end bb llvm.builder;
      (* body *)
      codegen_stmt llvm func_info local_env block;
      
      (* ayto einai ligo bakalistiko, prepei na to stressarw na dw oti panta doulevei,
         o skopos einai na vazei ret void stis void synarthseis pou den exoun to 
         statement return sto telos*)
      (* let _ = 
        match block with
        | S_block (stmts) ->
            let x = List.hd (List.rev stmts) in
            (match x with
            | S_return _ -> ()
            | _ -> ignore (build_ret_void llvm.builder);)
        | _ -> assert false
        in *)
        (* (build_ret_void llvm.builder); *)

        (* let basic_blocks = basic_blocks f in
        let last_instruction = block_terminator entry_block in *)


        let helper x =
          match block_terminator x with
          | Some _ -> ()
          | None   -> ignore (build_ret_void llvm.builder) in
        iter_blocks helper ( f);
(*       
        ignore (match last_instruction with
        | Some _ -> () (* A terminator exists, no need to add a return. *)
        | None -> ignore (build_ret_void llvm.builder)); *)
          (* No terminator, so we add a default return based on `ret_type`. *)
          (* let default_return_value = match classify_type ret_type with
            | TypeKind.Void -> const_null ret_type
            | TypeKind.Integer -> const_int ret_type 0
            | _ -> failwith "Unhandled return type"
          in
          ignore (build_ret default_return_value builder) *)

      
      Llvm_analysis.assert_valid_function f;
      (* env *)



      print_string (name^"_ST\n");
      printllvmST local_env;



      (* insertST env name (f, None) ayto mallon den prepei na mpei *)
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
      let _ = codegen_decl llvm (Some frame_ptr) newST fdef in 

      ({func with stack_frames = FunctionsToFrames.add name frame_ptr func.stack_frames}, env)

  | F_decl h -> (* this should be used for function definitions as well*)
      let (name, var_names, ft) = codegen_fhead llvm None  h in
      let f = 
        match lookup_function name llvm.the_module with 
        | None -> declare_function name ft llvm.the_module (* !!! here what happens when a function is redefined locally?*)
        | Some f ->
            if Array.length (basic_blocks f) = 0 then () else
              raise (Failure "redefinition of function");
            if Array.length (params f) = Array.length (param_types ft) then () else
              raise (Failure "redefinition of function with different # args");
            f
      in 
      (* insertST env name (f, None) *)
      (func, env)
  | V_def (vars, t) -> 
      position_at_end entryBB llvm.builder;
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
  (* Initialize types aliases *)
  let i1 = i1_type ctx in
  let i8 = i8_type ctx in
  let i32 = i32_type ctx in
  let i64 = i64_type ctx in
  let void = void_type ctx in
  (* Initialize constant functions *)
  let c1 = const_int i1 in
  let c8 = const_int i8 in
  let c32 = const_int i32 in
  let c64 = const_int i64 in


  (* Initialize library functions and add them to the Symbol Table *)
  let writeInteger_ty = function_type void [| i64 |] in
  let writeChar_ty = function_type void [| i8 |] in
  let writeString_ty = function_type void [| pointer_type2 ctx |] in (*maybe pointer_type i8 should be used?*)
  let readInteger_ty = function_type i64 [| |] in
  let readChar_ty = function_type i8 [| |] in
  let readString_ty = function_type void [| i64; pointer_type2 ctx |] in
  let ascii_ty = function_type i32 [| i8 |] in
  let chr_ty = function_type i8 [| i64 |] in
  let strlen_ty = function_type i32 [| pointer_type2 ctx |] in
  let strcmp_ty = function_type i32 [| pointer_type2 ctx; pointer_type2 ctx |] in
  let strcpy_ty = function_type void [| pointer_type2 ctx; pointer_type2 ctx |] in
  let strcat_ty = function_type void [| pointer_type2 ctx; pointer_type2 ctx |] in
  
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

  (* let predefined_env = addPredefined emptyST in *)

  (* gather all info in a record for later use *)
  let info = {
    context          = ctx;
    the_module       = md;
    builder          = builder;
    i1               = i1;
    i8               = i8;
    i32              = i32;
    i64              = i64;
    c1               = c1;
    c8               = c8;
    c32              = c32;
    c64              = c64;
    void             = void;
    predefined_fs    = predefined;
  } in


  (* Emit the program code and add return value to main function *)
  ignore (codegen_decl info None emptyST asts);
  (* ignore (build_ret (c32 0) builder); *)

  (* Verify the entire module*)
  Llvm_analysis.assert_valid_module md;

  (* Optimize *) (* this must be optional *)
  (* ignore (PassManager.run_module md fpm); *)

  (* Print out the IR *)
  print_module "llvm_ir.ll" md;; (* dump_module to print in stdout*)




(* let () = llvm_compile_and_dump 5; *)