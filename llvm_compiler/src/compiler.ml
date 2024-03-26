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
  the_vars         : llvalue;
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


let rec create_fcall llvm env stmt =
  match stmt with
  | S_fcall (name, exprs) -> (* otan kaleitai mia synarthsh prepei na kanei alloca ta vars ths?? *)
      let f = 
        match lookup_function name llvm.the_module with
        | Some f -> f
        | None -> raise (Failure "unknown function referenced") in
      let frt = (return_type (type_of f)) in (*regarding these: for writeInt (f is void (i64)* ), (type_of f is void (i64)), (element_type type_of f is void)*)
      let actual_frt = element_type frt in
      let params = params f in
      let ll_args =
        match exprs with
        | Some es -> 
            if Array.length params = List.length es then () else
              raise (Failure (name^": incorrect # arguments passed"));
            let params, _ = List.split (List.map (codegen_expr llvm env) es) in
            params
        | None ->
            if Array.length params = 0 then () else
              raise (Failure (name^": incorrect # arguments passed"));
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
                  let str_ptr = build_gep2 element_ty arg [| llvm.c32 0; llvm.c32 0 |] "arrptr" llvm.builder in (* ??? build_gep and opaque_ptr should be handled on the receiver (so a build_load is needed????) *)
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
      let ll_args = Array.of_list (List.map fix_arg ll_args) in


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

and handle_matrix llvm env lvalue acc =
  match lvalue with
  | L_id var          -> (codegen_expr llvm env (L_id var))::acc
  | L_string_lit s    -> (codegen_expr llvm env (L_string_lit s))::acc
  | L_matrix (e1, e2) ->
      let x = codegen_expr llvm env e2 in
      handle_matrix llvm env e1 (x::acc)
  | _ -> assert false

and codegen_expr llvm env expr =
  match expr with
  | E_int_const i  -> llvm.c64 i, None
  | E_char_const c -> llvm.c8 (Char.code c), None
  | L_string_lit s -> 
      let str = const_stringz llvm.context s in
      let str_ty = type_of str in
      (* elegxos ypoloipwn syanrthsewn*)

      let str_ptr = build_alloca str_ty "strtmp" llvm.builder in
      let _ = build_store str str_ptr llvm.builder in
      (* let str_ptr = build_gep2 str_ty str_array [| llvm.c32 0; llvm.c32 0 |] "str_ptr" llvm.builder in (* ??? build_gep and opaque_ptr should be handled on the receiver (so a build_load is needed????) *)
      let opaque_ptr = build_bitcast str_ptr (pointer_type2 llvm.context) "ptr" llvm.builder in *)
      str_ptr, Some [1 + String.length s]
  | L_id var ->
      let var_ptr, dims = lookupST var env in
      var_ptr, dims
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
      let array_types, dims = List.split (handle_matrix llvm env e []) in
      let dims = Option.get (List.hd dims) in
      begin
        match array_types with
        | array_ptr::indexes ->
            let array_ty = element_type (type_of array_ptr) in (*type_of array_ptr is pointer to the type of array eg [50xi64]*, so element_type is the array type [50xi64] (not pointer)*)
            let int_indexes = List.map (fun x -> Int64.to_int (Option.get (int64_of_const x))) indexes in
            let linear_index = compute_linear_index dims int_indexes in
          
            (* element_ptr points to the index of the matrix we want *)
            let element_ptr = build_gep2 array_ty array_ptr [| llvm.c32 0; llvm.c32 linear_index |] "matrixptr" llvm.builder in
            (* element_type of array_ty is the type of an array. if [50xi64] then i64 *)
            element_ptr, None
        | [] -> assert false
      end
  | E_fcall stmt -> 
      (match stmt with
      | S_fcall (name, ps) -> 
          let retv = create_fcall llvm env (S_fcall (name, ps)) in
          retv, None
      | _ -> assert false)
  | E_op1 (op, e) -> 
      let rhs, _ = codegen_expr llvm env e in

      let get_values llv = 
        let ty = type_of llv in
        let element_ty = element_type (type_of llv) in
        match classify_type ty with
        | Pointer -> build_load2 element_ty llv "condtmp" llvm.builder (* pointer is a variable or an array element*)
        | Integer -> llv
        | _ -> raise (Failure "aa")
      in
      let rhs = get_values rhs in

      begin
        match op with
        | Op_plus  -> rhs, None
        | Op_minus -> build_neg rhs "negtmp" llvm.builder, None
        | _        -> assert false
      end
  | E_op2 (e1, op, e2) ->
      let lhs, _ = codegen_expr llvm env e1 in
      let rhs, _ = codegen_expr llvm env e2 in

      let get_values llv = 
        let ty = type_of llv in
        let element_ty = element_type (type_of llv) in
        match classify_type ty with
        | Pointer -> build_load2 element_ty llv "condtmp" llvm.builder (* pointer is a variable or an array element*)
        | Integer -> llv
        | _ -> raise (Failure "aa")
      in
      let lhs = get_values lhs in
      let rhs = get_values rhs in

      match op with
      | Op_plus  -> build_add lhs rhs "addtmp" llvm.builder, None
      | Op_minus -> build_sub lhs rhs "subtmp" llvm.builder, None
      | Op_times -> build_mul lhs rhs "multmp" llvm.builder, None
      | Op_div   -> build_sdiv lhs rhs "divtmp" llvm.builder, None
      | Op_mod   -> build_srem lhs rhs "modtmp" llvm.builder, None
      | _        -> assert false

and codegen_cond llvm env cond =
  match cond with
  | C_bool1 (op, c) ->
    (* body *)
      let rhs = codegen_cond llvm env c in
      begin
        match op with
        | Op_not -> build_xor rhs (llvm.c1 1) "negtmp" llvm.builder
        | _      -> assert false
      end
  | C_bool2 (c1, op, c2) ->
      let lhs = codegen_cond llvm env c1 in
      let rhs = codegen_cond llvm env c2 in
      begin
        match op with
        | Op_and -> build_and lhs rhs "andtmp" llvm.builder
        | Op_or  -> build_or lhs rhs "ortmp" llvm.builder
        | _      -> assert false
      end
  | C_expr (e1, op, e2) -> 
      let lhs, _ = codegen_expr llvm env e1 in
      let rhs, _ = codegen_expr llvm env e2 in
      
      let get_values llv = 
        let ty = type_of llv in
        let element_ty = element_type (type_of llv) in
        match classify_type ty with
        | Pointer -> build_load2 element_ty llv "condtmp" llvm.builder (* pointer is a variable or an array element*)
        | Integer -> llv
        | _ -> raise (Failure "aa")
      in
      let lhs = get_values lhs in
      let rhs = get_values rhs in
      
      match op with
      | Op_eq          -> build_icmp Icmp.Eq lhs rhs "eqtmp" llvm.builder
      | Op_hash        -> build_icmp Icmp.Ne lhs rhs "netmp" llvm.builder
      | Op_less        -> build_icmp Icmp.Slt lhs rhs "sltmp" llvm.builder
      | Op_lesseq      -> build_icmp Icmp.Sle lhs rhs "slemp" llvm.builder
      | Op_greater     -> build_icmp Icmp.Sgt lhs rhs "sgtmp" llvm.builder
      | Op_greatereq   -> build_icmp Icmp.Sge lhs rhs "sgemp" llvm.builder
      | _              -> assert false

and codegen_stmt llvm env stmt = (* isos den xreiazetai to env *)
  match stmt with
  | S_fcall (name, exprs) as fcall -> let _ = create_fcall llvm env fcall in ()
  | S_colon _ -> ()
  | S_assign (e1, e2) ->
      let l, _ = codegen_expr llvm env e1 in
      let r, _ = codegen_expr llvm env e2 in
      let _ =
        match classify_type (type_of r) with
        | Pointer -> 
            let v = build_load2 (element_type (type_of r)) r "rvload" llvm.builder in
            build_store v l llvm.builder
        | _ -> build_store r l llvm.builder
      in ()
  | S_block stmts -> List.iter (codegen_stmt llvm env) stmts
  | S_if (c, s) ->
      let cond = codegen_cond llvm env c in
      let start_bb = insertion_block llvm.builder in
      let cur_function = block_parent start_bb in

      let then_bb = append_block llvm.context "then" cur_function in
      let after_bb = append_block llvm.context "after" cur_function in
      let _ = build_cond_br cond then_bb after_bb llvm.builder in

      position_at_end then_bb llvm.builder;
      codegen_stmt llvm env s;
      let _ = build_br after_bb llvm.builder in

      position_at_end after_bb llvm.builder
  | S_ifelse (c, s1, s2) ->
      let cond = codegen_cond llvm env c in
      let start_bb = insertion_block llvm.builder in
      let cur_function = block_parent start_bb in

      let then_bb = append_block llvm.context "then" cur_function in
      let else_bb = append_block llvm.context "else" cur_function in
      let merge_bb = append_block llvm.context "ifafter" cur_function in
      let _ = build_cond_br cond then_bb else_bb llvm.builder in

      position_at_end then_bb llvm.builder;
      codegen_stmt llvm env s1;
      let _ = build_br merge_bb llvm.builder in 
      
      position_at_end else_bb llvm.builder;
      codegen_stmt llvm env s2;
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
      let cond = codegen_cond llvm env c in
      let _ = build_cond_br cond loop_bb after_bb llvm.builder in

      position_at_end loop_bb llvm.builder;
      codegen_stmt llvm env s;
      let _ = build_br cond_bb llvm.builder in

      position_at_end after_bb llvm.builder;

  | S_return e ->
      match e with
      | Some expr ->
          let n, _ = codegen_expr llvm env expr in
          ignore (build_ret n llvm.builder)
      | None -> ignore (build_ret_void llvm.builder)

let createStructType llvm env fname =
  let values = llvmSTvalues env in
  struct_type llvm.context (Array.of_list (List.map type_of values))

let createStruct llvm env fname =
  let x = named_struct_type llvm.context ("frame."^fname) in
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
  frame_ptr

let codegen_fparam llvm params = 
  match params with
  | F_params (r, vars, t) -> 
      begin
        match r with
        | Some _  -> List.map (fun _ -> pointer_type2 llvm.context) vars
        | None -> 
            let ty, _ = type_to_lltype llvm t in 
            List.map (fun _ -> ty) vars
      end
  | _ -> assert false

let rec fparams_to_llarray llvm fparams acc =  (* na dokimasw anti gia to @ na kanw reverse sto telos (fainetai idio)*)
  match fparams with
  | hd::tl -> fparams_to_llarray llvm tl (acc @ (codegen_fparam llvm hd))
  | []     -> acc

let codegen_fhead llvm env head = (* ayto kalo einai na ginei merge me to codegen_decl *)
  match head with
  | F_head (name, params, t) ->
      let ftype, _ = type_to_lltype llvm t in
      let stackframety = createStructType llvm env name in
      begin
        match params with
        | Some ps  -> let params = Array.of_list (stackframety::(fparams_to_llarray llvm ps [])) in
                      (name, function_type ftype params)
        | None     -> (name, function_type ftype [| stackframety |])
      end
  | _ -> assert false

let rec addVars llvm env vars (t, dims) = (* edw prepei na ginei handle to duplicate vars h isws sto semantic*)
  match vars with
  | hd::tl -> 
      let alloca_addr = build_alloca t hd llvm.builder in (* edw o builder einai hdh sthn arxh ths synarthshs wste na paijei to mem2reg *)
      let newST = insertST env hd (alloca_addr, dims) in
      addVars llvm newST tl (t, dims)
  | [] -> env




let rec codegen_decl llvm env decl =
  match decl with
  | F_def (h, locals, block) ->

      let (name, ft) = 
        if !first_function = true then (
          first_function := false;
          let (_, ft) = codegen_fhead llvm env h in
          let name = "main" in
          (name, ft))
        else
          codegen_fhead llvm env h
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
      let local_env = List.fold_left (codegen_localdef llvm bb) env locals in
      (* edw thelei skepsi gia to pws tha mpoun oi times twn local-defs: den thelw tis times pou eisagei to definition mias fucntion*)
      
      position_at_end bb llvm.builder;
      (* body *)
      codegen_stmt llvm local_env block;
      
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
      (* Llvm_analysis.assert_valid_function f; *)
      (* env *)



      print_string (name^"_ST\n");
      printllvmST local_env;



      (* insertST env name (f, None) ayto mallon den prepei na mpei *)
      env


  | _         -> assert false

and codegen_localdef llvm entryBB env local = (*entryBB is the function's entry block *)
  match local with
  | F_def (h, locals, block) as fdef -> 
      let _ = codegen_decl llvm env fdef in env

  | F_decl h -> (* this should be used for function definitions as well*)
      let (name, ft) = codegen_fhead llvm env h in
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
      env
  | V_def (vars, t) -> 
      position_at_end entryBB llvm.builder;
      let llty, dims = type_to_lltype llvm t in
      (* let dims = Option.get dims in *)
      addVars llvm env vars (llty, dims)
  | _ -> assert false

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
    the_vars         = the_vars;
  } in


  (* Emit the program code and add return value to main function *)
  ignore (codegen_decl info emptyST asts);
  (* ignore (build_ret (c32 0) builder); *)

  (* Verify the entire module*)
  (* Llvm_analysis.assert_valid_module md; *)

  (* Optimize *) (* this must be optional *)
  (* ignore (PassManager.run_module md fpm); *)

  (* Print out the IR *)
  print_module "llvm_ir.ll" md;; (* dump_module to print in stdout*)




(* let () = llvm_compile_and_dump 5; *)