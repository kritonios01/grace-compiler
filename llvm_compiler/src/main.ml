let main =
  let usage_msg = "grcc [-f] [-i] [-O] <program.grc>" in
  let opt_flag = ref false in
  let f_flag = ref false in
  let i_flag = ref false in
  let input_dir = ref "" in

  let set_input x = input_dir := x in

  let speclist =
    [
      ("-f", Arg.Set f_flag, "Use stdin as input and output assembly on stdout");
      ("-i", Arg.Set i_flag, "Use stdin as input and output LLVM IR on stdout");
      ("-O", Arg.Set opt_flag, "Apply LLVM optimizations");
    ]
  in 
  ignore (Arg.parse speclist set_input usage_msg);

  if !i_flag && !f_flag then
    (Printf.eprintf "Error: -i and -f flags cannot be both on!\n";
    exit 1);

  let filename = 
    let open Filename in
    basename !input_dir |> remove_extension in

  let ic =
    if !f_flag || !i_flag then stdin
    else open_in !input_dir
  in
  let lexbuf = Lexing.from_channel ic in
  try
    let asts = Parser.program Lexer.lexer lexbuf in
    Printf.printf "%d lines read.\n" !Lexer.num_lines;
    Printf.printf "Syntax OK!\n";
    let _ = Semantic.sem_ast asts in
    Printf.printf "Semantics OK!\n";
    let _ = Compiler.llvm_compile_and_dump asts filename !opt_flag !i_flag in
    Printf.printf "Compilation OK!\n";
    
    if !i_flag then
      exit 0;
    let _ = Sys.command ("llc-16 "^ filename^".ll -o "^ filename ^ ".s") in
    if !f_flag then 
      ignore (Sys.command ("cat "^ filename ^".s"))
    else
      ignore (Sys.command ("clang -no-pie "^ filename ^".s ../lib.a -o "^ filename));
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