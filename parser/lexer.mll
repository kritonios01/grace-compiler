{
  open Parser

  let num_lines = ref 0
}

(* definitions of useful regexps *)
let id             = ['a'-'z' 'A'-'Z'] ['a'-'z' 'A'-'Z' '0'-'9' '_']*
let digit          = ['0'-'9']
let common_chars   = [^ '\'' '\"' '\\']
let hex            = digit | ['A'-'F'] | ['a'-'f']
let escseq         = '\\'  ('n' | 't' | 'r' | '0' | '\\' | '\'' | '\"' | ('x' hex hex))

let letter = ['a'-'z' 'A'-'Z']
let white  = [' ' '\t' '\r']

(* NOTE: Counting lines works but probably not when there are multiline comments *)
rule lexer = parse
  (* keywords *)
  | "and"     { T_and     }
  | "char"    { T_char    }
  | "div"     { T_div     }
  | "do"      { T_do      }
  | "else"    { T_else    }
  | "fun"     { T_fun     }
  | "if"      { T_if      }
  | "int"     { T_int     }
  | "mod"     { T_mod     }
  | "not"     { T_not     }
  | "nothing" { T_nothing }
  | "or"      { T_or      }
  | "ref"     { T_ref     }
  | "return"  { T_return  }
  | "then"    { T_then    }
  | "var"     { T_var     }
  | "while"   { T_while   }

  (* names *)
  | id                                    { T_id     }

  (* int constants unsigned *)
  | digit+                                { T_consti }
  
  (* char and string constants *)
  | '\'' (escseq | common_chars)  '\''    { T_constc }
  | '\"' (escseq | common_chars)+ '\"'    { T_consts }

  (* symbolic operators *)
  | '+'       { T_plus      }
  | '-'       { T_minus     }
  | '*'       { T_mul       }
  | '='       { T_eq        }
  | '#'       { T_hash      }
  | '<'       { T_less      }
  | '>'       { T_greater   }
  | "<="      { T_lesseq    }
  | ">="      { T_greatereq }

  (* seperators *)
  | '('       { T_lparen    }
  | ')'       { T_rparen    }
  | '['       { T_lbracket  }
  | ']'       { T_rbracket  }
  | '{'       { T_lcbracket }
  | '}'       { T_rcbracket }
  | ','       { T_comma     }
  | ';'       { T_semicolon }
  | ':'       { T_colon     }
  | "<-"      { T_assign    } 

  (* to be ignored by parser: white chars and comments *)
  | '\n'      { incr num_lines; lexer lexbuf}
  | white+    { lexer lexbuf    }
  | '$'       { comment lexbuf  }
  | "$$"      { mcomment lexbuf }

  (* Last options *)
  |  eof          { T_eof }
  |  _ as c       { Printf.eprintf "Invalid character: '%c' (ascii: %d)\n" c (Char.code c); lexer lexbuf }


(* comment entrypoint catches single line comments. Triggered after a $ is detected *)
and comment = shortest
  | [^'\n']* '\n'       { incr num_lines; Printf.eprintf "SingleLineComment\n"; lexer lexbuf                    }
  | _* '$' _*           { Printf.eprintf "Error on single line comment: Dual $\n"; lexer lexbuf }

(* mcomment entrypoint catches multi line comments. Triggered after a $$ is detected *)
and mcomment = parse
  | [^ '$' '$']* "$$"   { Printf.eprintf "MultiLineComment\n"; lexer lexbuf                     }
  | [^ '$' '$']*        { Printf.eprintf "Error on multiline comment\n"; lexer lexbuf           }
