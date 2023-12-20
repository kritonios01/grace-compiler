let main =
  let lexbuf = Lexing.from_channel stdin in
  try
    let asts = Parser.program Lexer.lexer lexbuf in
    Ast.printAST (*asts*);
    Printf.printf "%d lines read.\n" !Lexer.num_lines;
    Printf.printf "Syntax OK!\n";
    exit 0
  with 
  | Parser.Error -> (* this is an error raised by the parser *)
      Printf.eprintf "Syntax error at line %d\n" (!Lexer.num_lines + 1);
      exit 1
  | Lexer.LexingError e -> (* this is an error raised by the lexer *)
      Printf.eprintf "%s\n" e;
      exit 1