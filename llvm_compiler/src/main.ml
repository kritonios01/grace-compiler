open Llvm

let main =
  let lexbuf = Lexing.from_channel stdin in
  try
    let asts = Parser.program Lexer.lexer lexbuf in
    let _ = Semantic.sem_ast asts in
    Printf.printf "%d lines read.\n" !Lexer.num_lines;
    Printf.printf "Syntax OK!\n";
    Printf.printf "Semantics OK!\n";
    exit 0
  with 
  | Parser.Error -> (* this is an error raised by the parser *)
      Printf.eprintf "Syntax error at line %d\n" (!Lexer.num_lines + 1);
      exit 1
  | Lexer.LexingError e -> (* this is an error raised by the lexer *)
      Printf.eprintf "%s\n" e;
      exit 1
  | Semantic.TypeError s ->
      Printf.eprintf "Type error: %s\n" s;
  | Symbol.SymbolExc (sym, s) ->
      Printf.eprintf "%s: %s\n" s sym;