let main =
  let lib_dir = try Sys.getenv "GRC_LIB_PATH" with Not_found -> raise (Failure "GRC_LIB_PATH environment variable was not found!\n") in
  let usage_msg = "grcc [-f] [-i] [-O] [-v] [-o <output>] <program.grc>" in
  let opt_flag = ref false in
  let f_flag = ref false in
  let i_flag = ref false in
  let v_flag = ref false in
  let o_flag = ref "" in
  let input_dir = ref "" in

  let set_input x = input_dir := x in

  let speclist =
    [
      ("-f", Arg.Set f_flag, "Use stdin as input and output assembly on stdout");
      ("-i", Arg.Set i_flag, "Use stdin as input and output LLVM IR on stdout");
      ("-O", Arg.Set opt_flag, "Apply LLVM optimizations");
      ("-v", Arg.Set v_flag, "Verbose mode");
      ("-o", Arg.Set_string o_flag, "Specify the executable's filename");
    ]
  in 
  ignore (Arg.parse speclist set_input usage_msg);

  if !input_dir = "" then
    (Printf.eprintf "Error: input file was not specified!\n";
    exit 1);

  if !i_flag && !f_flag then
    (Printf.eprintf "Error: -i and -f flags cannot be both on!\n";
    exit 1);

  let print_message msg var =
    match !v_flag with
    | true -> 
        (match var with
        | Some x -> Printf.printf "%d %s" x msg;
        | None   -> Printf.printf "%s" msg)
    | false -> () in
      
  let check_and_delete file =
    if Sys.file_exists file then
      Sys.remove file
    else
      () in

  let filename = 
    Filename.(
      basename !input_dir |> remove_extension) in

  let ic =
    if !f_flag || !i_flag then stdin
    else open_in !input_dir
  in
  let lexbuf = Lexing.from_channel ic in
  try
    let asts = Parser.program Lexer.lexer lexbuf in
    print_message "lines read.\n" (Some !Lexer.num_lines);
    print_message "Syntax OK!\n" None;
    let _ = Semantic.sem_ast asts in
    (* Printf.printf "Semantics OK!\n"; *)
    let _ = Compiler.llvm_compile_and_dump asts filename !opt_flag !i_flag in

    if !i_flag then
      exit 0;
    let llc_rv = Sys.command ("llc-16 "^ filename^".ll -o "^ filename ^ ".s") in
    if llc_rv <> 0 then
      (check_and_delete (filename^".ll");
      exit 1)
    else if !f_flag then 
      ignore (Sys.command ("cat "^ filename ^".s"))
    else
      let out = if !o_flag <> "" then !o_flag else "a.out" in
      ignore (Sys.command ("clang -no-pie "^ filename ^".s "^ lib_dir ^" -o "^out));
    print_message "Compilation OK!\n" None;
    List.iter check_and_delete [filename^".ll"; filename^".s"];
    exit 0
  with 
  | Parser.Error -> (* this is an error raised by the parser *)
      Printf.eprintf "Syntax error at line %d\n" (!Lexer.num_lines + 1);
      exit 1
  | Lexer.LexingError e -> (* this is an error raised by the lexer *)
      Printf.eprintf "%s\n" e;
      exit 1
  | Semantic.TypeError s -> (* this is an error raised by the semantic analyzer *)
      Printf.eprintf "Type error: %s\n" s;
  | Symbol_tables.SymbolExc (sym, s) -> (* this is an error raised by the ST when it doesn't find a token *)
      Printf.eprintf "%s: %s\n" s sym;