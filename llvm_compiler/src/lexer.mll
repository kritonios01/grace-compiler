{
  open Lexing
  open Parser

  let num_lines = ref 0

  let to_esc_seq c =
    match c with
    | 'n' -> '\n'
    | 't' -> '\t'
    | 'r' -> '\r'
    | '0' -> Char.chr 0
    | '\\' -> '\\'
    | '\'' -> '\''
    | '"' -> '"'
    | _   -> assert false


  (* let fix_esqsecs str =
    let open Str in
    let regex = regexp "\\\\n" in
    let str = global_replace regex "\n" str in
    let regex = regexp "\\\\t" in
    let str = global_replace regex "\t" str in
    let regex = regexp "\\\\r" in
    let str = global_replace regex "\r" str in
    (* let regex = regexp "\\\\0" in
    let str = global_replace regex "\0" str in *)
    let regex = regexp "\\\\\\\\" in
    let str = global_replace regex "\\\\" str in
    let regex = regexp "\\\\'" in
    let str = global_replace regex "\'" str in
    let regex = regexp "\\\\\"" in
    let str = global_replace regex "\"" str in
    let regex = regexp "\(\\\\x..\)" in
    let str = global_replace regex "\1" str in

    str *)

  exception LexingError of string
}

(* definitions of useful regexps *)
let id             = ['a'-'z' 'A'-'Z'] ['a'-'z' 'A'-'Z' '0'-'9' '_']*
let digit          = ['0'-'9']
let common_chars   = [^ '\'' '\"' '\\']
let hex            = digit | ['A'-'F'] | ['a'-'f']
let escseq         = '\\'  ('n' | 't' | 'r' | '0' | '\\' | '\'' | '\"' | ('x' hex hex))

let letter = ['a'-'z' 'A'-'Z']
let white  = [' ' '\t' '\r']



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
  | id                                    { T_id (lexeme lexbuf)    }

  (* int constants unsigned *)
  | digit+                                { T_consti (int_of_string (lexeme lexbuf)) }
  
  (* char and string constants *)
  | '\'' common_chars  '\''    { T_constc (lexeme_char lexbuf 1) (*let slen = String.length (lexeme lexbuf) in
                                            T_constc (String.sub (lexeme lexbuf) 1 (slen- 2))*)}

  | '\'' escseq as s '\''               {
      match (String.length s) with
      | 2 -> T_constc (to_esc_seq s.[1])
      | 4 -> T_constc (Char.chr (Scanf.sscanf (String.sub s 2 2) "%x" (fun x -> x)))
      | _ -> assert false
  }

  | '\"'    { strings "" lexbuf }
                                            (*let s = (lexeme lexbuf) in
                                            let slen = String.length (s) in
                                            let correct_s = String.sub (s) 1 (slen - 2) in
                                            let fixed_s = fix_esqsecs correct_s in
                                            T_consts (fixed_s) }*)

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
  |  _            { raise (LexingError ("Illegal token: '" ^ lexeme lexbuf ^ "' at line " ^ (string_of_int (!num_lines + 1)))) }


(* comment entrypoint catches single line comments. Triggered after a $ is detected *)
and comment = parse
  | '\n'       { incr num_lines; lexer lexbuf }
  | _          { comment lexbuf               }

(* mcomment entrypoint catches multi line comments. Triggered after a $$ is detected *)
and mcomment = parse
  | "$$"       { lexer lexbuf                    }
  | '\n'       { incr num_lines; mcomment lexbuf }
  | _          { mcomment lexbuf                 }
  | eof        { raise (LexingError "Reached EOF: Missing closing '$$'") }

(* and strings = parse
  | "\\x" (hex as d1) (hex as d2)   { !char_list := (Char.chr (int_of_hex) d1 d2)::char_list; 
                                      strings lexbuf }
  | escsec as c  {
      let correct_c =
        match c with
        | "\\n" -> '\n'
        | "\\t" -> '\t'
        | "\\r" -> 
    } *)

and strings current = parse
  | '"'    { T_consts current }
  | '\n'   {
      raise (LexingError "String literals must be closed in the same line");
      strings current lexbuf
  }
  | common_chars as chr { strings (current ^ (String.make 1 chr)) lexbuf }
  | escseq as esc {
    if (String.length esc == 2) then
        strings (current ^ (String.make 1 (to_esc_seq esc.[1]))) lexbuf
    else if (String.length esc == 4) then
        strings (current ^ (String.make 1 (Char.chr (Scanf.sscanf (String.sub esc 2 2) "%x" (fun x-> x))))) lexbuf
    else assert false
  }
  | _ as x { raise (LexingError ("Invalid character with ascii code" ^ (String.make 1 ( x)) ^ "inside string literal"))  }