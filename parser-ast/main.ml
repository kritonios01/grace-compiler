open Ast

let main =
  let lexbuf = Lexing.from_channel stdin in
  try
    let asts = Parser.program Lexer.lexer lexbuf in
    printAST asts;
    Printf.printf "%d lines read.\n" !Lexer.num_lines;
    Printf.printf "Syntax OK!\n";
    exit 0
  with 
  | Parser.Error -> (* this is an error raised by parser *)
      Printf.eprintf "Syntax error at line %d\n" (!Lexer.num_lines + 1);
      exit 1
  | Lexer.LexingError e ->
      Printf.eprintf "%s\n" e;
      exit 1