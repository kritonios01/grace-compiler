let main =
  let lexbuf = Lexing.from_channel stdin in
  try
    let asts = Parser.program Lexer.lexer lexbuf in
    Printf.printf "%d lines read.\n" !Lexer.num_lines;
    Printf.printf "Syntax OK!\n";
    let _ = Semantic.sem_ast asts in
    Printf.printf "Semantics OK!\n";
    let _ = Compiler.llvm_compile_and_dump asts in
    Printf.printf "Compilation OK!\n";

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