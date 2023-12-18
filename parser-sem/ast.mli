type operator = 
  | Op_plus
  | Op_minus
  | Op_times
  | Op_div
  | Op_mod
  | Op_not
  | Op_and
  | Op_or
  | Op_eq
  | Op_hash
  | Op_less
  | Op_lesseq
  | Op_greater
  | Op_greatereq

type ast_type =
  | Int
  | Char
  | Nothing

type ast_datatypes =
  | Data_type of ast_type * int list

type ast_expr =
  | E_int of int
  | E_char of char
  | L_id of string
  | L_string of string
  | L_matrix of ast_expr * ast_expr
  | E_fcall of ast_stmt
  | E_op1 of operator * ast_expr
  | E_op2 of ast_expr * operator * ast_expr
  | C_bool1 of operator * ast_expr
  | C_bool2 of ast_expr * operator * ast_expr

and ast_params =
  | F_params of unit option * string list * ast_datatypes

and ast_header = F_head of string * ast_params list option * ast_type

and ast_stmt =
  | F_def of ast_header * ast_stmt list * ast_stmt
  | F_decl of ast_header
  | F_call of string * ast_expr list option
  | V_def of string list * ast_datatypes

  | S_colon of unit
  | S_assign of ast_expr * ast_expr
  | S_block of ast_stmt list
  | S_if of ast_expr * ast_stmt
  | S_ifelse of ast_expr * ast_stmt * ast_stmt
  | S_while of ast_expr * ast_stmt
  | S_return of ast_expr option

val printAST : ast_stmt -> unit