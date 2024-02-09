open Llvm
open Ast
open Symbol
open Semantic


let first_function = ref true; (* first function in llvm ir must be called main, but grace syntax allows any name for a program's main function*)

(* keep the llvm settings in a record*)
type llvm_info = {
  context          : llcontext;
  the_module       : llmodule;
  builder          : llbuilder;
  i8               : lltype;
  i32              : lltype;
  i64              : lltype;
  c8               : int -> llvalue;
  c32              : int -> llvalue;
  c64              : int -> llvalue;
  void             : lltype;
  the_vars         : llvalue;
}


let type_to_lltype llvm ty =
  match ty with
  | TY_int  -> llvm.i32
  | TY_char -> llvm.i8
  | TY_none -> llvm.void
  | _       -> llvm.i32 (*to be implemented*)

let codegen_expr llvm env expr =
  match expr with
  | E_int_const i  -> llvm.c64 i
  | E_char_const c -> llvm.c8 (Char.code c)
  | L_string_lit s -> 
      let str = const_stringz llvm.context s in
      let str_ty = type_of str in

      (* elegxos ypoloipwn syanrthsewn*)

      let str_array = build_alloca str_ty "tmp" llvm.builder in
      let _ = build_store str str_array llvm.builder in
      let str_ptr = build_gep2 str_ty str_array [| llvm.c32 0; llvm.c32 0 |] "str_ptr" llvm.builder in
      let opaque_ptr = build_bitcast str_ptr (pointer_type2 llvm.context) "ptr" llvm.builder in
      opaque_ptr

  | _ -> raise (Failure "dummy error, have to look into this")

let codegen_stmt llvm env stmt = (* isos den xreiazetai to env *)
  match stmt with
  | S_fcall (name, exprs) ->     
      let f = 
        match lookup_function name llvm.the_module with
        | Some f -> f
        | None -> raise (Failure "unknown function referenced") in
      let frt =  return_type (type_of f) in
      let params = params f in
      let ll_args =
        match exprs with
        | Some es -> 
            if Array.length params = List.length es then () else
              raise (Failure "incorrect # arguments passed");
            Array.of_list (List.map (codegen_expr llvm env) es)
        | None ->
            if Array.length params = 0 then () else
              raise (Failure "incorrect # arguments passed");
            [| |] 
      in
      let name = (*if return_type frt == void then "" else name^"_call" in*)
        match frt with
        | void -> ""
        | _ -> name^"call" in
      ignore (build_call2 frt f ll_args name llvm.builder)

  | _ -> raise (Failure "dummy failure")

let codegen_block llvm env block =
  match block with
  | S_block stmts -> List.map (codegen_stmt llvm env) stmts
  | _ -> raise (Failure "dummy")

let compile_fparam llvm params = 
  match params with
  | F_params (r, vars, t)  -> (match r with
                              | Some _   -> List.map (fun _ -> pointer_type2 llvm.context) vars
                              | None     -> let ty = type_to_lltype llvm t in 
                                            List.map (fun _ -> ty) vars)
  | _                      -> raise (Failure "Compile params: Reached unreachable >:(")

let rec fparams_to_llarray llvm fparams acc =
  match fparams with
  | hd::tl -> fparams_to_llarray llvm tl (acc @ (compile_fparam llvm hd))
  | []     -> acc

let compile_fhead llvm head =
  match head with
  | F_head (name, params, t) -> let ftype = type_to_lltype llvm t in
                                (match params with
                                | Some ps  -> let params = Array.of_list (fparams_to_llarray llvm ps []) in
                                              (name, function_type ftype params)
                                | None     -> (name, function_type ftype [| |]))
  | _                        -> raise (Failure "Compile function header: Reached unreachable >:(")

let rec compile_decl llvm env decl =
  match decl with
  | F_def (h, locals, block) -> let env = sem_decl env (F_def (h, locals, block)) in
                                let (name, ft) = 
                                  if !first_function = true then (
                                    first_function := false;
                                    let (_, ft) = compile_fhead llvm h in
                                    let name = "main" in
                                    (name, ft))
                                  else
                                     compile_fhead llvm h
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
                                (* set names for arguments *)
                                let bb = append_block llvm.context (name ^ "_entry") f in
                                position_at_end bb llvm.builder;
                                (*handle locals and block*)
                                (* let _ = List.fold_left (compile_decl llvm) env locals in *)
                                (* let _ = List.map (compile_decl llvm env) locals in *)
                                (* body *)
                                let _ = codegen_block llvm env block in
                                let _ = build_ret (llvm.c32 42) llvm.builder in
                                Llvm_analysis.assert_valid_function f;
                                env
  | F_decl head              -> (match head with
                                | F_head (name, params, t) -> (match params with
                                                              | Some ps  -> let types = paramsToTypes ps [] in
                                                                            insertST env name (FunEntry(t, types))
                                                              | None     -> insertST env name (FunEntry(t, [])))
                                | _                        -> raise (Failure "11 Reached unreachable :("))
  | V_def (vars, t)          -> (match t with  (* prepei na kanw check gia duplicate variable! dyskolo...*)
                                | TY_int             -> addVars env vars IntEntry
                                | TY_char            -> addVars env vars CharEntry
                                | TY_array (t, dims) -> addVars env vars (ArrayEntry (t, dims))
                                | _                  -> raise (Failure "12 Reached unreachable :("))
  | _         -> raise (Failure "Reached unreachable")

let llvm_compile_and_dump asts =
  (* Initialize LLVM: context, module, builder and FPM*)
  Llvm_all_backends.initialize ();
  let ctx = global_context () in
  let md = create_module ctx "grace program" in
  let builder = builder ctx in
  let fpm = PassManager.create () in
  List.iter (fun optimization -> optimization fpm) [
    Llvm_scalar_opts.add_memory_to_register_promotion;
    Llvm_scalar_opts.add_instruction_combination;
    Llvm_scalar_opts.add_reassociation;
    Llvm_scalar_opts.add_gvn;
    Llvm_scalar_opts.add_cfg_simplification;
  ]; (*maybe add some more??? *)
  (* Initialize types aliases *) (*remove unused *)
  let i8 = i8_type ctx in
  let i32 = i32_type ctx in
  let i64 = i64_type ctx in
  let void = void_type ctx in
  (* Initialize constant functions *) (* ayta prepei na ta dw ligo*)
  let c8 = const_int i8 in
  let c32 = const_int i32 in
  let c64 = const_int i64 in
  (* Initialize global variables *) (* ayta isws den xreiazontai katholou *)
  let vars_type = array_type i64 26 in (* ayto den xreiazetai edw alla sto array datatype *)
  let the_vars = declare_global vars_type "vars" md in 
  set_linkage Linkage.Private the_vars;
  set_initializer (const_null vars_type) the_vars;
  Llvm.set_alignment 16 the_vars;


  (* Initialize library functions and add them to the Symbol Table *)
  let writeInteger_ty = function_type void [| i64 |] in
  let writeChar_ty = function_type void [| i8 |] in
  let writeString_ty = function_type void [| pointer_type2 ctx |] in (*maybe pointer_type i8 should be used?*)
  let readInteger_ty = function_type i32 [| |] in
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

  let predefined_env = addPredefined emptyST in

  (* gather all info in a record for later use *)
  let info = {
    context          = ctx;
    the_module       = md;
    builder          = builder;
    i8               = i8;
    i32              = i32;
    i64              = i64;
    c8               = c8;
    c32              = c32;
    c64              = c64;
    void             = void;
    the_vars         = the_vars;
  } in


  (* Emit the program code and add return value to main function *)
  ignore (compile_decl info predefined_env asts); (*MAJOR PROBLEM: first function must be called main in llvm ir*)
  (* ignore (build_ret (c32 0) builder); *)

  (* Verify the entire module*)
  Llvm_analysis.assert_valid_module md;

  (* Optimize *) (* this must be optional *)
  (* ignore (PassManager.run_module md fpm); *)

  (* Print out the IR *)
  print_module "llvm_ir.ll" md;; (* dump_module to print in stdout*)




(* let () = llvm_compile_and_dump 5; *)