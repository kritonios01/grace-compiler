
(* The type of tokens. *)

type token = 
  | T_while
  | T_var
  | T_then
  | T_semicolon
  | T_rparen
  | T_return
  | T_ref
  | T_rcbracket
  | T_rbracket
  | T_plus
  | T_or
  | T_nothing
  | T_not
  | T_mul
  | T_mod
  | T_minus
  | T_lparen
  | T_lesseq
  | T_less
  | T_lcbracket
  | T_lbracket
  | T_int
  | T_if
  | T_id
  | T_hash
  | T_greatereq
  | T_greater
  | T_fun
  | T_eq
  | T_eof
  | T_else
  | T_do
  | T_div
  | T_consts
  | T_consti
  | T_constc
  | T_comma
  | T_colon
  | T_char
  | T_assign
  | T_and

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val program: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (unit)
