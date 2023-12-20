open Ast
open Symbol

exception TypeError of string

let sem_expr expr env =
  match expr with
  | E_int_const i   -> i
  | E_char_const c  -> c
  | L_id var  -> _
  | E_op1 (op, e)        -> match op with
                            | Op_plus  
                            | Op_minus -> let t = sem_expr e env in
                                          if t = TY_int then TY_int
                                          else raise TypeError "Using non-integer values on arithmetic operation"
                            | _        -> raise Failure "Reached unreachable :("
  | E_op2 (e1, op, e2)   -> match op with
                            | Op_plus 
                            | Op_minus 
                            | Op_times
                            | Op_div
                            | Op_mod   -> let t1 = sem_expr e1 env in
                                          let t2 = sem_expr e2 env in
                                          if (t1 = TY_int && t2 = TY_int) then TY_int
                                          else raise TypeError "Using non-integer values on arithmetic operation"
                            | _        -> raise Failure "Reached unreachable :("
  | C_bool1 (op, e)      -> match op with
                            | Op_not   -> 
      



let rec sem_stmt stmt =
  match stmt with
  | V_def (ids, t) -> 