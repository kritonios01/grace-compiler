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
  | True
  | False

type ast_expr =
  | E_int_const of int
  | E_char_const of char
  | L_string_lit of string
  | L_id of var
  | L_matrix of ast_expr * ast_expr (* first expr is an l-value *)
  | E_fcall of ast_stmt   (* stmt must be S_fcall (or it should be of the same type as S_fcall) *)
  | E_op1 of operator * ast_expr
  | E_op2 of ast_expr * operator * ast_expr

and ast_cond =
  | C_bool1 of operator * ast_cond
  | C_bool2 of ast_cond * operator * ast_cond
  | C_expr of ast_expr  * operator * ast_expr

and ast_decl =
  | F_params of unit option * var list * typ
  | F_head of var * ast_decl list option * typ  (* decl must be f_params*)
  | F_def of ast_decl * ast_decl list * ast_stmt   (* decl must be f_head, ast_decl -> f_def, f_decl, v_def *)
  | F_decl of ast_decl (* decl must be f_head *)
  | V_def of var list * typ     (* ast_params->Vparams *)

and ast_stmt =
  | S_fcall of string * ast_expr list option
  | S_colon of unit
  | S_assign of ast_expr * ast_expr (* first expr must l-value *)
  | S_block of ast_stmt list
  | S_if of ast_cond * ast_stmt
  | S_ifelse of ast_cond * ast_stmt * ast_stmt
  | S_while of ast_cond * ast_stmt
  | S_return of ast_expr option

(* --------------------------------------------------------------------------------------------------- *)

(* helper function: converts a string list to comma-seperated values string *)
(* let rec list_to_string l =
  match l with
  | [] -> ""
  | [a] -> a
  | (h::t) -> h ^ ", " ^ (list_to_string t) *)

(* Constructors *)
(* let ops_string ast =
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
  | L_id s                -> s
  | L_string s            -> s
  | L_matrix (l, dims)    -> expr_string l ^ "[" ^ expr_string dims ^ "]"
  | E_fcall s             -> "EXPR[" ^ stmt_string s ^ "]"
  | E_op1 (op, e)         -> ops_string op ^ expr_string e
  | E_op2 (e1, op, e2)    -> expr_string e1 ^ ops_string op ^ expr_string e2
  | C_bool1 (op, e)       -> ops_string op ^ expr_string e
  | C_bool2 (e1, op, e2)  -> expr_string e1 ^ ops_string op ^ expr_string e2

and params_string ast = 
  match ast with
  | F_params (ref, ids, type_) -> let ref = match ref with
                                            | Some x -> "ref" (*if ref then "ref" else "noref"*)
                                            | None   -> "noref"
                                      and ids = list_to_string ids
                                      and type_ = datatype_string type_ 
                                  in ref ^ " [" ^ ids ^ "] " ^ type_

and poption_string ast =
  match ast with
  | Some x  -> let list = List.map params_string x in "PARAMS(" ^ list_to_string list ^ ")"
  | None    -> "NOPARAMS" 

and header_string ast =
  match ast with
  | F_head (id, params, ret) -> let params = poption_string params
                                    and ret = type_string ret
                                in id ^ ": " ^ params ^ ": " ^ ret

and retoption_string ast =
  match ast with
  | Some x  -> expr_string x
  | None    -> "NOEXPR"

and exproption_string ast =
  match ast with
  | Some x -> let list = List.map expr_string x in list_to_string list
  | None   -> "NOEXPRS"


and stmt_string ast =
  match ast with
  | F_def (h, l, block)  -> let s = List.map stmt_string l in "FUNC[(" ^ header_string h ^ "), LOCAL-DEFS(" ^ list_to_string s ^ "), " ^ stmt_string block ^ "]"
  | F_decl h             -> "F_DECL(" ^ header_string h ^ ")"
  | F_call (id, e)       -> "F_CALL(" ^ id ^ ", " ^ exproption_string e ^ ")"
  | V_def (ids, t)       -> "VARs(" ^ list_to_string ids ^ ") of type " ^ datatype_string t
  | S_colon u             -> ";"
  | S_assign (l, e)      -> "ASSIGN(" ^ expr_string l ^ ", " ^ expr_string e ^ ")"
  | S_block l            -> let s = List.map stmt_string l in "BLOCK(" ^ list_to_string s ^ ")"
  | S_if (e, s)          -> "IF(" ^ expr_string e ^ ") -> " ^ stmt_string s
  | S_ifelse (e, s1, s2) -> "IF(" ^ expr_string e ^ ") -> " ^ stmt_string s1 ^ ": ELSE -> " ^ stmt_string s2
  | S_while (e, s)       -> "WHILE(" ^ expr_string e ^ ") -> " ^ stmt_string s
  | S_return e           -> "RETURN(" ^ retoption_string e ^ ")" *)


let printAST (*asts*) = 
  Printf.printf "%s\n\n" "OOOK"(*(stmt_string asts)*)