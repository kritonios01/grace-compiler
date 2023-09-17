open Printf

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

type ast_type = (* helper for S_return *)
  | Int
  | Char
  | Nothing

type ast_datatypes =
  | Data_type of ast_type * int list

type ast_expr =
  | E_int of int
  | E_char of char
  | E_op1 of operator * ast_expr
  | E_op2 of ast_expr * operator * ast_expr
  | C_bool1 of operator * ast_expr
  | C_bool2 of ast_expr * operator * ast_expr

type ast_lvalue =
  | L_id of string   (* edw paizetai: char list h string? *)
  | L_string of string
  | L_matrix of ast_lvalue * ast_expr

type ast_params =
  | F_params of bool * string list * ast_datatypes       (* bool->ref? string->ids ast_ptype->ptype *)

type ast_header = F_head of string * ast_params list * ast_type (* string->id ast_params->F_params ast_return einai to return type ths f *)

and ast_stmt =
  | F_def of ast_header * ast_stmt list * ast_stmt   (* ast_stmt -> f_def, f_decl, v_def *)
  | F_decl of ast_header
  | F_call of string * ast_expr list
  | V_def of string list * ast_datatypes     (* ast_params->Vparams *)

  | S_assign of ast_lvalue * ast_expr
  | S_block of ast_stmt list
  | S_if of ast_expr * ast_stmt
  | S_ifelse of ast_expr * ast_stmt * ast_stmt
  | S_while of ast_expr * ast_stmt
  | S_return of ast_expr






(* helper function: converts a string list to comma-seperated values string *)
let rec list_to_string l =
  match l with
  | [] -> ""
  | [a] -> a
  | (h::t) -> h ^ ", " ^ (list_to_string t)




let ops_string ast =
  match ast with
  | Op_plus      -> "+"
  | Op_minus     -> "-"
  | Op_times     -> "*"
  | Op_div       -> "/"
  | Op_mod       -> "%"
  | Op_not       -> "NOT"
  | Op_and       -> "AND"
  | Op_or        -> "OR"
  | Op_eq        -> "="
  | Op_hash      -> "#"
  | Op_less      -> "<"
  | Op_lesseq    -> "<="
  | Op_greater   -> ">"
  | Op_greatereq -> ">="

let type_string ast =
  match ast with
  | Int     -> "int"
  | Char    -> "char"
  | Nothing -> "nothing"

let datatype_string ast =
  match ast with
  | Data_type (type_, dims) -> let s = List.map string_of_int dims in type_string type_ ^ "(" ^ list_to_string s ^ ")"

let rec expr_string ast =
  match ast with
  | E_int e               -> string_of_int e
  | E_char e              -> Char.escaped e      (* prepei na testaristei to escaped *)
  | E_op1 (op, e)         -> ops_string op ^ expr_string e
  | E_op2 (e1, op, e2)    -> expr_string e1 ^ ops_string op ^ expr_string e2
  | C_bool1 (op, e)       -> ops_string op ^ expr_string e
  | C_bool2 (e1, op, e2)  -> expr_string e1 ^ ops_string op ^ expr_string e2

let rec lvalue_string ast =
  match ast with
  | L_id s          -> s
  | L_string s      -> s
  | L_matrix (l, e) -> lvalue_string l ^ expr_string e

let params_string ast = 
  match ast with
  | F_params (ref, ids, type_) -> let ref = if ref then "ref" else "noref"
                                      and ids = list_to_string ids
                                      and type_ = datatype_string type_ 
                                  in ref ^ " [" ^ ids ^ ": " ^ type_ ^ "]"

let rec header_string ast =
  match ast with
  | F_head (id, params, ret) -> let paramAST = let list = List.map params_string params in list_to_string list
                                    and retAST = type_string ret
                                in id ^ ": " ^ paramAST ^ ": " ^ retAST
                              (* in printf "%s : [%s] : %s)" id paramAST retAST *)

let rec stmt_string ast =
  match ast with
  | F_def (h, l, block)  -> let s = List.map stmt_string l in "FUNC(" ^ header_string h ^ list_to_string s ^ stmt_string block ^ ")"
  | F_decl h             -> "F_DECL(" ^ header_string h ^ ")"
  | F_call (id, e)       -> let s = List.map expr_string e in "F_CALL(" ^ id ^ list_to_string s ^ ")" 
  | V_def (ids, t)       -> "VARs(" ^ list_to_string ids ^ ") of type " ^ datatype_string t
  | S_assign (l, e)      -> "ASSIGN(" ^ lvalue_string l ^ ", " ^ expr_string e ^ ")"
  | S_block l            -> let s = List.map stmt_string l in "BLOCK(" ^ list_to_string s ^ ")"
  | S_if (e, s)          -> "IF(" ^ expr_string e ^ ") -> " ^ stmt_string s
  | S_ifelse (e, s1, s2) -> "IF(" ^ expr_string e ^ ") -> " ^ stmt_string s1 ^ ": ELSE -> " ^ stmt_string s2
  | S_while (e, s)       -> "WHILE(" ^ expr_string e ^ ") -> " ^ stmt_string s
  | S_return e           -> "RETURN" ^ expr_string e



let rec printAST asts =
  match asts with
  | []       -> ()
  | (h::t)   -> let s = stmt_string h in printf "%s" s ; printAST t