open Ast
open Symbol

exception TypeError of string


(* helper *)
let bind_operator op =
  match op with
  | Op_eq -> (=)
  | Op_hash -> (<>)
  | Op_less -> (<)
  | Op_lesseq -> (<=)
  | Op_greater -> (>)
  | Op_greatereq -> (>=)
  | _ -> raise (Failure "aa")  ;;


let rec sem_expr expr env =
  match expr with
  | E_int_const i        -> TY_int
  | E_char_const c       -> TY_char
  | L_string_lit s       -> TY_array (TY_char, [String.length s + 1])
  | L_id var             -> (match (lookupST var env) with
                            | IntEntry i              -> TY_int
                            | CharEntry c             -> TY_char
                            | IntArrayEntry (l1, l2)  -> TY_array (TY_int, l1) 
                            | CharArrayEntry (l1, l2) -> TY_array (TY_char, l1)
                            | _                       -> raise (TypeError "Expected var name but found function name as l-value"))
  | L_matrix (e1, e2)    -> let t1 = sem_expr e1 env in (* !!!have to check for index out of bounds!!!*)
                            let t2 = sem_expr e2 env in
                            (match t2 with
                            | TY_int -> t1     (* needs checking *)
                            | _      -> raise (TypeError "index of array/matrix is not an int"))
  | E_fcall stmt         -> TY_int               (*dummy    (sem_stmt stmt) -> ftype*)
  | E_op1 (op, e)        -> (match op with
                            | Op_plus  
                            | Op_minus -> let t = sem_expr e env in
                                          if t = TY_int then TY_int
                                          else raise (TypeError "Using non-integer values on arithmetic operation")
                            | _        -> raise (Failure "Reached unreachable :("))
  | E_op2 (e1, op, e2)   -> match op with
                            | Op_plus 
                            | Op_minus 
                            | Op_times
                            | Op_div
                            | Op_mod   -> let t1 = sem_expr e1 env in
                                          let t2 = sem_expr e2 env in
                                          if (t1 = TY_int && t2 = TY_int) then TY_int
                                          else raise (TypeError "Using non-integer values on arithmetic operation")
                            | _        -> raise (Failure "Reached unreachable :(")
   
let rec sem_cond cond env =
  match cond with
  | C_bool1 (op, c)      -> (match op with
                            | Op_not -> let t = sem_cond c env in
                                        (match t with TY_bool b -> TY_bool (not b))
                            | _      -> raise (Failure "Reached unreachable :("))
  | C_bool2 (c1, op, c2) -> (match op with
                            | Op_and -> let t1 = sem_cond c1 env in
                                        let t2 = sem_cond c2 env in
                                        (match t1, t2 with (TY_bool b1), (TY_bool b2) -> TY_bool (b1 && b2))
                            | Op_or  -> let t1 = sem_cond c1 env in
                                        let t2 = sem_cond c2 env in
                                        (match t1, t2 with (TY_bool b1), (TY_bool b2) -> TY_bool (b1 || b2))
                            | _      -> raise (Failure "Reached unreachable :("))
  | C_expr (e1, op, e2)  -> match op with
                            | Op_eq
                            | Op_hash
                            | Op_less
                            | Op_lesseq
                            | Op_greater
                            | Op_greatereq   -> let t1 = sem_expr e1 env in
                                                let t2 = sem_expr e2 env in (* handle the case of chars nad check both t1 and t2*)
                                                if (t1=TY_int) then (TY_bool ((bind_operator op) 5 6))
                                                else TY_bool false (* handle this*)
                            | _              -> raise (Failure "Reached unreachable :(")
      



(* let rec sem_stmt stmt =
  match stmt with
  | V_def (ids, t) ->  *)