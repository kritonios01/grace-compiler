open Llvm
open Ast
open Symbol_tables
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

(* returns a pointer to the struct with all values in the ST at the time of calling and the new environment with keys mapped to their place in the struct *)
let create_struct llvm func callee_env cur_env fname =  (* struct type can be passed as and argument to this function so that it doesn't have to be created again *)
  let frame = named_struct_type llvm.ctx ("frame."^fname) in

  let env = find_new_values callee_env cur_env in

  let keys, values = llvmST_to_llenv_entries env in

  (* print_string "Creating struct " *)
  (* List.iter (print_llenv_entry) values; *)
  (* print_llenv_entry values *)

  let values = List.map (codegen_llenv_entry llvm func true) values in (* this needs to be checked that it works as expected. it was added to handle arrays, but the rest need to be checked! *)


  let st_pairs = List.combine keys values in
  struct_set_body frame (Array.of_list (List.map type_of values)) false;

  let frame_ptr = build_alloca frame ("frame."^fname^"_ptr") llvm.bd in
  
  (* store each value of callee's ST in the struct *)
  let store_and_updateST index (k, v) = (* edw prepei na ginei handle to na einai mesa se stackframe ayto pou theloume na valouem sto neo stackframe*)
    let base = (build_struct_gep frame frame_ptr index ("frame."^fname^(string_of_int index)) llvm.bd) in
    ignore (build_store v base llvm.bd); 
    (index+1)
  in 
  let _ = List.fold_left store_and_updateST 0 st_pairs in
  frame_ptr

let create_struct_type llvm env fname =
  let keys, values = llvmSTvalues env in
  let st_pairs = List.combine keys values in
  let frame_ty = struct_type llvm.ctx (Array.of_list (List.map type_of values)) in

  (* update the ST so that these values point to their new place *)
  let updateST (index, env) (k, v) =
    let replace x =
      match x with
      | Some ll_entry ->
          (match ll_entry with (* this returns Some ... because this is what is expected from the update function *)
          | BasicEntry _ 
          | CompositeEntry (_, _, _) 
          | FuncParamEntry (_, _, _)         -> Some (StackFrameEntry (ll_entry, index))
          | StackFrameEntry (original, _)    -> Some (StackFrameEntry (original, index))
          | _                         -> assert false) 
      | None -> assert false 
    in
    let newST = SymbolTable.update k replace env in
    (index+1, newST)
  in 
  let (_, env) = List.fold_left updateST (0, env) st_pairs in
  frame_ty, env

let rec create_fcall llvm func env stmt =
  match stmt with
  | S_fcall (name, exprs) ->
      let upper = if List.mem name llvm.predefined_fs then 0 else 1 in (* ayto einai hardcoded -> kako. an ginoun override oi predefined den tha paizei swsta. ousiastika ayto ginetai gia na min pernaei stack frame stis prokathorismenes synarthseis oi opoies einia vevaio oti xreiazontai mono tis parametrous tous. enallaktika gia aplothta tha mporouse na pernaei to stack frame kai se aytes kai as einai axreiasto *)
      let f = 
        match lookup_function name llvm.md with
        | Some f -> f
        | None -> raise (Failure( "unknown function referenced: "^name)) in
      let (fty, callee_env) =
        match lookupST name env with
        | FuncEntry (ty, env) -> (ty, env)
        | _                  -> assert false in

      let fparams = 
        params f
        |> Array.to_list
        |> if upper = 1 then List.tl else (fun x -> x) in
      
      let args =
        let ast_args = Option.value exprs ~default:[] in
        if List.(length fparams = length ast_args) then () else
          raise (Failure (name^"(...): incorrect # arguments passed"));
        ast_args 
      in

      let fix_arg arg param_ty = 
        let ptr =
          match classify_type param_ty with
          | Pointer -> true
          | Integer -> false
          | _       -> assert false in 
        codegen_expr llvm func env arg
        |> codegen_llenv_entry llvm func ptr
      in

      let fixed_args = List.(
        map type_of fparams
        |> map2 fix_arg args) in

      let ll_args = 
        if upper = 1 then 
          (* let _ = (print_string ("Creating struct for "^name^"\n")) in *)
          let frame_ptr = create_struct llvm func callee_env env name in
          Array.of_list (frame_ptr::fixed_args)
        else 
          Array.of_list fixed_args in

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

(* returns the llenv_entry which represents the array pointer 
   and a list of llenv_entries which represent the indices*)
and handle_matrix llvm func env lvalue acc =
  match lvalue with
  | L_id var ->
      (match codegen_expr llvm func env lvalue with
      | CompositeEntry (_, _, _) as ce   -> ce, acc
      | FuncParamEntry (_, _, _) as fpe  -> fpe, acc
      | StackFrameEntry (_, _) as sfe    -> sfe, acc
      | _ -> assert false)
  | L_string_lit s ->
      (match codegen_expr llvm func env lvalue with
      | CompositeEntry (_, _, _) as ce -> ce, acc
      | _ -> assert false)
  | L_matrix (e1, e2) ->
      (match codegen_expr llvm func env e2 with
      | BasicEntry (llv, ty) as be    -> handle_matrix llvm func env e1 (be::acc)
      | StackFrameEntry (_, _) as sfe -> handle_matrix llvm func env e1 (sfe::acc)
      | _ -> assert false)
  | _ -> assert false


and codegen_expr llvm func env expr =
  match expr with
  | E_int_const i  -> (BasicEntry (llvm.c64 i, llvm.i64))
  | E_char_const c -> (BasicEntry (llvm.c8 (Char.code c), llvm.i64))
  | L_string_lit s -> 
      let str = const_stringz llvm.ctx s in
      let str_ty = type_of str in
      let str_ptr = build_alloca str_ty "strtmp" llvm.bd in
      ignore (build_store str str_ptr llvm.bd);
      CompositeEntry (str_ptr, [1 + String.length s], str_ty)
  | L_id var -> lookupST var env
  | L_matrix (e1, e2) as e ->
      let base_entry, index_entries = handle_matrix llvm func env e [] in
      let array_ty = extract_llt base_entry in
      let array_llv = codegen_llenv_entry llvm func true base_entry in
      let indices = List.map (codegen_llenv_entry llvm func false) index_entries in
      let dims = extract_array_dims base_entry in
      let llindex = 
        add_remaining_indices llvm indices dims
        |> compute_linear_index llvm in
      let element_ptr = build_gep array_ty array_llv [| llvm.c64 0; llindex |] "matrixptr" llvm.bd in
      if List.(length dims = length indices) then
        (BasicEntry (element_ptr, element_type array_ty))
      else
        let new_dims, new_dims_sum = remove_left_dims indices dims in
        (CompositeEntry (element_ptr, new_dims, array_type (element_type array_ty) new_dims_sum))
  | E_fcall stmt -> 
      (match stmt with
      | S_fcall (name, ps) -> 
          let retv = create_fcall llvm func env (S_fcall (name, ps)) in
          (BasicEntry (retv, type_of retv))
      | _ -> assert false)
  | E_op1 (op, e) -> 
      let rhs = 
        codegen_expr llvm func env e
        |> codegen_llenv_entry llvm func false in
      begin
        match op with
        | Op_plus  -> (BasicEntry (rhs, (*type_of rhs_value*) llvm.i64))    (*!!!! this and the below need checking *)
        | Op_minus -> (BasicEntry ((build_neg rhs "negtmp" llvm.bd), llvm.i64))
        | _        -> assert false
      end
  | E_op2 (e1, op, e2) -> (* needs checking like the above *)
      let lhs =
        codegen_expr llvm func env e1
        |> codegen_llenv_entry llvm func false in
      let rhs =
        codegen_expr llvm func env e2
        |> codegen_llenv_entry llvm func false in

      match op with
      | Op_plus  -> (BasicEntry ((build_add lhs rhs "addtmp" llvm.bd), llvm.i64))
      | Op_minus -> (BasicEntry ((build_sub lhs rhs "subtmp" llvm.bd), llvm.i64))
      | Op_times -> (BasicEntry ((build_mul lhs rhs "multmp" llvm.bd), llvm.i64))
      | Op_div   -> (BasicEntry ((build_sdiv lhs rhs "divtmp" llvm.bd), llvm.i64))
      | Op_mod   -> (BasicEntry ((build_srem lhs rhs "modtmp" llvm.bd), llvm.i64))
      | _        -> assert false

(* returns the llvalue and the last basic block required for the phi node *)
and codegen_cond llvm func env cond =
  match cond with
  | C_bool1 (op, c) ->
      let rhs, _ = codegen_cond llvm func env c in
      begin
        match op with
        | Op_not -> build_xor rhs (llvm.c1 1) "negtmp" llvm.bd, None
        | _      -> assert false
      end
  | C_bool2 (c1, op, c2) ->
      let lhs, _ = codegen_cond llvm func env c1 in
      begin
        match op with
        | Op_and ->
            let cur_function = insertion_block llvm.bd |> block_parent in
            let c1_true_block = append_block llvm.ctx "eval_rest_AND" cur_function in
            let c1_false_block = append_block llvm.ctx "false_dump" cur_function in
            let end_block = append_block llvm.ctx "end_AND" cur_function in
            let _ = build_cond_br lhs c1_true_block c1_false_block llvm.bd in

            position_at_end c1_true_block llvm.bd;
            let rhs, phi_pred = codegen_cond llvm func env c2 in
            let _ = build_br end_block llvm.bd in

            position_at_end c1_false_block llvm.bd;
            let _ = build_br end_block llvm.bd in

            position_at_end end_block llvm.bd;
            build_phi [(llvm.c1 0, c1_false_block); (rhs, Option.value phi_pred ~default:c1_true_block)] "and_result" llvm.bd, Some end_block

        | Op_or  ->
            let cur_function = insertion_block llvm.bd |> block_parent in
            let c1_false_block = append_block llvm.ctx "eval_rest_OR" cur_function in
            let c1_true_block = append_block llvm.ctx "true_dump" cur_function in
            let end_block = append_block llvm.ctx "end_OR" cur_function in
            let _ = build_cond_br lhs c1_true_block c1_false_block llvm.bd in

            position_at_end c1_false_block llvm.bd;
            let rhs, phi_pred = codegen_cond llvm func env c2 in
            let _ = build_br end_block llvm.bd in

            position_at_end c1_true_block llvm.bd;
            let _ = build_br end_block llvm.bd in

            position_at_end end_block llvm.bd;
            build_phi [(llvm.c1 1, c1_true_block); (rhs, Option.value phi_pred ~default:c1_false_block)] "or_result" llvm.bd, Some end_block
        | _      -> assert false
      end
  | C_expr (e1, op, e2) -> 
      let lhs =
        codegen_expr llvm func env e1
        |> codegen_llenv_entry llvm func false in
      let rhs =
        codegen_expr llvm func env e2
        |> codegen_llenv_entry llvm func false in

      match op with
      | Op_eq          -> build_icmp Icmp.Eq lhs rhs "eqtmp" llvm.bd, None
      | Op_hash        -> build_icmp Icmp.Ne lhs rhs "netmp" llvm.bd, None
      | Op_less        -> build_icmp Icmp.Slt lhs rhs "sltmp" llvm.bd, None
      | Op_lesseq      -> build_icmp Icmp.Sle lhs rhs "slemp" llvm.bd, None
      | Op_greater     -> build_icmp Icmp.Sgt lhs rhs "sgtmp" llvm.bd, None
      | Op_greatereq   -> build_icmp Icmp.Sge lhs rhs "sgemp" llvm.bd, None
      | _              -> assert false

and codegen_stmt llvm func env stmt =
  match stmt with
  | S_fcall (name, exprs) as fcall -> let _ = create_fcall llvm func env fcall in ()
  | S_colon _ -> ()
  | S_assign (e1, e2) ->
      let dest =
        codegen_expr llvm func env e1
        |> codegen_llenv_entry llvm func true in
      let src =
        codegen_expr llvm func env e2
        |> codegen_llenv_entry llvm func false in
      ignore (build_store src dest llvm.bd)
  | S_block stmts -> List.iter (codegen_stmt llvm func env) stmts
  | S_if (c, s) ->
      let cond, _ = codegen_cond llvm func env c in
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
      let cond, _ = codegen_cond llvm func env c in
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

      position_at_end merge_bb llvm.bd
  | S_while (c, s) ->
      let start_bb = insertion_block llvm.bd in
      let cur_function = block_parent start_bb in
    
      let cond_bb = append_block llvm.ctx "cond" cur_function in
      let loop_bb = append_block llvm.ctx "loop" cur_function in
      let after_bb = append_block llvm.ctx "afterloop" cur_function in
      let _ = build_br cond_bb llvm.bd in

      position_at_end cond_bb llvm.bd;
      let cond, _ = codegen_cond llvm func env c in
      let _ = build_cond_br cond loop_bb after_bb llvm.bd in

      position_at_end loop_bb llvm.bd;
      codegen_stmt llvm func env s;
      let _ = build_br cond_bb llvm.bd in

      position_at_end after_bb llvm.bd;
  | S_return e ->
      match e with
      | Some expr ->
          let n = 
            codegen_expr llvm func env expr (* edw to codegen_xpr prepei na gyrnaei mono BasicEntry*)
            |> codegen_llenv_entry llvm func false
          in ignore (build_ret n llvm.bd)
      | None -> ignore (build_ret_void llvm.bd)


let params_to_names_and_lltypes llvm fparams =
  let fparams_helper acc params = (* returns (type of parameter), (dims list if it is an array), (type of pointer is type of parameter is a pointer)*)
    match params with
    | F_params (r, vars, t) -> 
        (match r with
        | Some _  -> 
            let ty, dims = type_to_lltype llvm t in
            vars::acc, List.map (fun _ -> llvm.ptr, dims, Some ty) vars
        | None -> 
            let ty, _ = type_to_lltype llvm t in 
            vars::acc, List.map (fun _ -> ty, None, None) vars)
    | _ -> assert false in

  (* the logic behind this is that we accumulate all variable names and map each variable to its type *)
  List.fold_left_map (fparams_helper) [] fparams  (* returns a tuple: string list list, lltype list list*)
  |> fun (names, lltypes) -> 
      List.(rev names |> concat, lltypes |> concat)

(* sframe is None only for the main function. In all other cases including when there are no local-vars etc, a stackframe is created *)
let codegen_fhead llvm sframe head = (* ayto kalo einai na ginei merge me to codegen_decl *)
  match head with
  | F_head (name, params, t) ->
      let frt, _ = type_to_lltype llvm t in
      let var_names, fparams =
        match params with
        | Some ps -> params_to_names_and_lltypes llvm ps (* fparams_to_llarray returns list, not array :) *)
        | None    -> [], [] in
      (* List.iter print_string var_names; *)
      let lltypes, dims, pointer_types = split3 fparams ([], [], []) in (* those empty lists are just accumulators*)
      begin
        match sframe with
        | true -> (name, var_names, (dims, pointer_types), function_type frt (Array.of_list (llvm.ptr::lltypes)))
        | false   -> (name, var_names, (dims, pointer_types), function_type frt (Array.of_list lltypes))
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

let rec codegen_decl llvm sframe env decl = (* old_env is the symboltable before creating the stackframe *)
  match decl with
  | F_def (h, locals, block) ->
      let sframe_bool =
        match sframe with
        | Some _ -> true
        | None   -> false in

      let (name, var_names, (dims, pointer_types), ft) = 
        if !first_function = true then (
          let (_, param_names, (dims, pointer_types), ft) = codegen_fhead llvm sframe_bool h in
          first_function := false;
          ("main", param_names, (dims, pointer_types), ft))
        else
          codegen_fhead llvm sframe_bool h
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

      
      (* this env we add to FuncEntry is the one that must be used in the scope of this function 
       * it the newST which maps names to their position in the stack frame  *)
      let env = insertST env name (FuncEntry (ft, env)) in
      
      let bb = append_block llvm.ctx (name ^ "_entry") f in
      position_at_end bb llvm.bd;

      let env = 
        if List.length var_names <> 0 then 
          List.fold_left2 (fun e (name, (dim, pty)) param ->
            set_value_name name param;
            match pty with
            | Some _ -> insertST e name (FuncParamEntry (param, dim, pty))
            | None   -> 
                let param_ptr = build_alloca (type_of param) (name^"ptr") llvm.bd in
                ignore (build_store param param_ptr llvm.bd);
                insertST e name (FuncParamEntry (param_ptr, dim, Some (type_of param)))
            (* insertST e name (FuncParamEntry (param, dim, pty)) *)
          ) env (List.combine var_names (List.combine dims pointer_types)) (params f |> Array.to_list |> List.tl) 
        else
          env in

      (* print_string ((string_of_llvalue f));
      Array.iter (fun x -> print_string ("\t"^(string_of_llvalue x)^"\n")) (params f);
      printllvmST env; *)


      (* if name <> "main" then set_value_name (Option.get sname) (params f).(0); *)
      (* set names for arguments *)



      (* let bb = append_block llvm.ctx (name ^ "_entry") f in
      position_at_end bb llvm.bd; *)

      let func_info = {
        the_f = f;
        name = name;
        stack_frame_ty = sframe;
        (* stack_frames = 
          match sframe with
          | Some frame -> FunctionsToFrames.empty |> FunctionsToFrames.add name frame
          | None       -> FunctionsToFrames.empty *)
          (* if name = "main" then FunctionsToFrames.empty
          else FunctionsToFrames.empty |> FunctionsToFrames.add; *)
      } in

      (*handle locals and block*)
      let func_info, local_env = List.fold_left (codegen_localdef llvm bb) (func_info, env) locals in
      (* edw thelei skepsi gia to pws tha mpoun oi times twn local-defs: den thelw tis times pou eisagei to definition mias fucntion*)
      
      position_at_end bb llvm.bd;
      (* body *)
      codegen_stmt llvm func_info local_env block;

      (* this is to remove multiple block terminators in a single block. This can happen with while loops
         and if-then/if-then-else statements. If we were to ommit this step, the module would not be valid
         and thus optimizations could lead to undefined behaviour *)
      iter_blocks remove_wrong_terminators f;

      let helper x = (* mia int synarthsh prepei na kanei return kati akoma kai an den yparxei to return mesa se ayth? den jerw an entopizetai (apo ton semantic analyzer) mia int synarthsh pou den exei kapoio return *)
        match block_terminator x with
        | Some _ -> ()
        | None   -> 
            let frt = return_type ft in
            match classify_type frt with
            | Void -> ignore (build_ret_void llvm.bd)
            | Integer ->
                if integer_bitwidth frt == 64 then
                  ignore (build_ret (llvm.c64 0) llvm.bd)
                else
                  ignore (build_ret (llvm.c8 0) llvm.bd)
            | _ -> assert false
      in iter_blocks helper f;

      
      (* Llvm_analysis.assert_valid_function f; *)
      (* env *)


(* 
      print_string (name^"_ST\n");
      printllvmST local_env; *)



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
      
      (* let func_env =
        match SymbolTable.find_opt name env with
        | Some v ->
            (match v with
            | FuncEntry (_, e) -> e
            | _ -> assert false)
        | None  -> env in *)
      

      let frame_ty, newST = create_struct_type llvm env name in (* we need this ST so that the functions know where to find these variables*)
      let _, _, _, ft = codegen_fhead llvm true h in
      let _ = codegen_decl llvm (Some frame_ty) newST fdef in 
      (* this env in FuncEntry is the one that we need in order to create the struct later when the function is called 
       * it must be the same as the one we give to create_struct_callee  *)
      let env = insertST env name (FuncEntry (ft, env)) in 
      (func(*{func with stack_frames = FunctionsToFrames.add name frame_ptr func.stack_frames}*), env)

  | F_decl h -> (* this should be used for function definitions as well*)
      let name, _, _, ft = codegen_fhead llvm true h in
      let f = 
        match lookup_function name llvm.md with (* search for function "name" in the ctx *)
        | None -> declare_function name ft llvm.md (*here what happens when a function is redefined locally?*)
        | Some f ->
            if Array.length (basic_blocks f) = 0 then () else
              raise (Failure "redefinition of function");
            if Array.length (params f) = Array.length (param_types ft) then () else
              raise (Failure "redefinition of function with different # args");
            f in
      let env = insertST env name (FuncEntry (ft, env)) in (* here some thinking is needed*)
      (func, env)
  | V_def (vars, t) -> 
      position_at_end entryBB llvm.bd;
      let llty, dims = type_to_lltype llvm t in
      (* let dims = Option.get dims in *)
      (func, addVars llvm env vars (llty, dims))  (* isws anti na kalw thn addvars na mporei na ginei olo ayto me foldl*)
  | _ -> assert false

let llvm_compile_and_dump asts input_file opt_flag i_flag =
  (* Initialize LLVM: context, module, builder and FPM*)
  let open Llvm_scalar_opts in
  Llvm_all_backends.initialize ();
  let ctx = global_context () in
  let md = create_module ctx "grace program" in
  let builder = builder ctx in
  let fpm = PassManager.create () in
  List.iter (fun optim -> optim fpm) [
    add_sccp; add_memory_to_register_promotion;
    add_instruction_combination; add_cfg_simplification;
    add_scalar_repl_aggregation;
    add_early_cse; add_cfg_simplification; add_instruction_combination;
    add_tail_call_elimination; add_reassociation; add_loop_rotation;
    add_instruction_combination; add_cfg_simplification;
    add_ind_var_simplification; add_loop_idiom; add_loop_deletion;
    add_loop_unroll; add_gvn; add_memcpy_opt; add_sccp; add_licm;
    add_aggressive_dce; add_cfg_simplification; add_instruction_combination;
    add_dead_store_elimination; add_cfg_simplification
  ];
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
      insertST e name (FuncEntry (fty, emptyST))
    ) emptyST predefined predefined_types in
  
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


  (* Emit the program code *)
  ignore (codegen_decl info None env asts);

  (* Verify the entire module*) (* when this is uncommented, arrays.grc won't compile *)
  (* Llvm_analysis.assert_valid_module md;  *)

  (* Optimize if requested *)
  ignore (if opt_flag then PassManager.run_module md fpm else false); (* false is dummy here *)

  (* Print out the IR *)
 (* if i_flag then
    dump_module md
  else 
    print_module (input_file^".ll") md *)(* dump_module to print in stdout*)
  if i_flag then
    dump_module md
  else 
    print_module (input_file^".ll") md (* dump_module to print in stdout*)




(* let () = llvm_compile_and_dump 5; *)