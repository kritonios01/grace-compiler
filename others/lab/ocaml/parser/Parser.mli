
(* The type of tokens. *)

type token = 
  | T_var
  | T_times
  | T_then
  | T_rparen
  | T_print
  | T_plus
  | T_minus
  | T_lparen
  | T_let
  | T_if
  | T_for
  | T_eq
  | T_eof
  | T_end
  | T_do
  | T_const
  | T_begin

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val program: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (unit)
