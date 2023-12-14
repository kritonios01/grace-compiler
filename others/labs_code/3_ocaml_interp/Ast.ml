(* We treat all vars as globals. Also, remember that var a states that a will be defined later and the definition happens with S_let *)

type var  = char   (* to var einai onoma metavlitis you programmatos*)
type oper = O_plus | O_minus | O_times

type ast_stmt =
| S_print of ast_expr
| S_let of var * ast_expr
| S_for of ast_expr * ast_stmt
| S_block of ast_stmt list
| S_if of ast_expr * ast_stmt

and ast_expr =
| E_const of int
| E_var of var
| E_op of ast_expr * oper * ast_expr

let vars = Array.create 26 0

let rec run_expr ast =
  match ast with
  | E_const n         -> n
  | E_var x           -> vars.(int_of_char x - int_of_char 'a')
  | E_op (e1, op, e2) -> let v1 = run_expr e1
                         and v2 = run_expr e2 in
                            match op with
                            | O_plus  -> v1 + v2
                            | O_minus -> v1 - v2
                            | O_times -> v1 * v2

let rec run_stmt ast =
  match ast with
  | S_print e    -> let v = run_expr e in
                      Printf.printf "%d\n" v
  | S_let (x, e) -> let v = run_expr e in
                      vars.(int_of_char x - int_of_char 'a') <- v
  | S_for (e, s) -> let v = run_expr e in
                      for i = 1 to v do
                        run_stmt s
                      done
  | S_block b    -> run b
  | S_if (e, s)  -> let v = run_expr e in
                      if v <> 0 then run_stmt s

and run asts = List.iter run_stmt asts
