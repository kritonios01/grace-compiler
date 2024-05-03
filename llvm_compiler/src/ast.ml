type var =
  string

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

type typ =
  | TY_int
  | TY_char
  | TY_none
  | TY_array of typ * int list (* list is for dimensions *)

type boolean =
  | TY_bool

type ast_expr =
  | E_int_const of int
  | E_char_const of char
  | L_string_lit of string
  | L_id of var
  | L_matrix of ast_expr * ast_expr (* first expr is an l-value *)
  | E_fcall of ast_stmt             (* stmt is S_fcall *)
  | E_op1 of operator * ast_expr
  | E_op2 of ast_expr * operator * ast_expr

and ast_cond =
  | C_bool1 of operator * ast_cond
  | C_bool2 of ast_cond * operator * ast_cond
  | C_expr of ast_expr  * operator * ast_expr

and ast_decl =
  | F_params of unit option * var list * typ
  | F_head of var * ast_decl list option * typ    (* decl must be f_params*)
  | F_def of ast_decl * ast_decl list * ast_stmt  (* decl must be f_head, ast_decl -> f_def, f_decl, v_def *)
  | F_decl of ast_decl                            (* decl must be f_head *)
  | V_def of var list * typ                       (* ast_params -> Vparams *)

and ast_stmt =
  | S_fcall of var * ast_expr list option
  | S_colon of unit
  | S_assign of ast_expr * ast_expr (* first expr must l-value *)
  | S_block of ast_stmt list
  | S_if of ast_cond * ast_stmt
  | S_ifelse of ast_cond * ast_stmt * ast_stmt
  | S_while of ast_cond * ast_stmt
  | S_return of ast_expr option