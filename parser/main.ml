let main =
  let lexbuf = Lexing.from_channel stdin in
  try
    Parser.program Lexer.lexer lexbuf;
    Printf.printf "Syntax OK!\n";
    exit 0
  with Parser.Error ->
    Printf.eprintf "Syntax error\n";
    exit 1
