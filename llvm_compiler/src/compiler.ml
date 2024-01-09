


let llvm_compile_and_dump asts =
  let open Llvm in
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
  ];
  (* Initialize types aliases *)
  let i8 = i8_type ctx in
  let i32 = i32_type ctx in
  let i64 = i64_type ctx in
  (* Initialize constant functions *) (* ayta prepei na ta dw ligo*)
  let c32 = const_int i32 in
  let c64 = const_int i64 in
  (* Initialize global variables *)
  let vars_type = array_type i64 26 in (* ayto den xreiazetai edw alla sto array datatype *)
  let the_vars = declare_global vars_type "vars" md in 
  set_linkage Linkage.Private the_vars;
  set_initializer (const_null vars_type) the_vars;
  (* Llvm.set_alignment 16 the_vars; *)

  let nl = "\n" in
  let nl_type = Llvm.array_type i8 (1 + String.length nl) in
  let the_nl = Llvm.declare_global nl_type "nl" md in
  Llvm.set_linkage Llvm.Linkage.Private the_nl;
  Llvm.set_global_constant true the_nl;
  Llvm.set_initializer (Llvm.const_stringz ctx nl) the_nl;
  Llvm.set_alignment 1 the_nl;
  (* Initialize library functions *)
  let writeInteger_type =
    function_type (Llvm.void_type ctx) [| i64 |] in
  let the_writeInteger =
    Llvm.declare_function "writeInteger" writeInteger_type md in
  let writeString_type =
    Llvm.function_type (Llvm.void_type ctx) [| Llvm.pointer_type i8 |] in
  let the_writeString =
    Llvm.declare_function "writeString" writeString_type md in
  (* Define and start and main function *)
  let main_type = Llvm.function_type i32 [| |] in
  let main = Llvm.declare_function "main" main_type md in
  let bb = Llvm.append_block ctx "entry" main in
  Llvm.position_at_end bb builder;
  (* Emit the program code *)
  let info = {
    context          = context;
    the_module       = the_module;
    builder          = builder;
    i8               = i8;
    i32              = i32;
    i64              = i64;
    c32              = c32;
    c64              = c64;
    the_vars         = the_vars;
    the_nl           = the_nl;
    the_writeInteger = the_writeInteger;
    the_writeString  = the_writeString;
  } in
  List.iter (compile_stmt info) asts;
  ignore (Llvm.build_ret (c32 0) builder);
  (* Verify *)
  Llvm_analysis.assert_valid_module the_module;
  (* Optimize *)
  ignore (Llvm.PassManager.run_module the_module pm);
  (* Print out the IR *)
  Llvm.print_module "a.ll" the_module