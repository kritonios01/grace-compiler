open Ast
open Symbol

exception TypeError of string


(* helper *)
(* let bind_operator op =
  match op with
  | Op_eq -> (=)
  | Op_hash -> (<>)
  | Op_less -> (<)
  | Op_lesseq -> (<=)
  | Op_greater -> (>)
  | Op_greatereq -> (>=)
  | _ -> raise (Failure "aa") *)


let rec sem_expr env expr =
  match expr with
  | E_int_const i        -> TY_int
  | E_char_const c       -> TY_char
  | L_string_lit s       -> TY_array (TY_char, [String.length s + 1])
  | L_id var             -> (match (lookupST var env) with
                            | IntEntry                -> TY_int
                            | CharEntry               -> TY_char
                            | ArrayEntry (t, dims)  -> TY_array (t, dims) 
                            | _                       -> raise (TypeError "Expected var name but found function name as l-value"))
  | L_matrix (e1, e2)    -> let t1 = sem_expr env e1 in (* !!!have to check for index out of bounds!!!*)
                            let t2 = sem_expr env e2 in
                            (match t2 with
                            | TY_int -> t1     (* needs checking *)
                            | _      -> raise (TypeError "index of array/matrix is not an int"))
  | E_fcall stmt         -> TY_int               (*dummy    (sem_stmt stmt) -> ftype*)
  | E_op1 (op, e)        -> (match op with
                            | Op_plus  
                            | Op_minus -> let t = sem_expr env e in
                                          if t = TY_int then TY_int
                                          else raise (TypeError "Using non-integer values on arithmetic operation")
                            | _        -> raise (Failure "Reached unreachable :("))
  | E_op2 (e1, op, e2)   -> match op with
                            | Op_plus 
                            | Op_minus 
                            | Op_times
                            | Op_div
                            | Op_mod   -> let t1 = sem_expr env e1 in
                                          let t2 = sem_expr env e2 in
                                          if (t1 = TY_int && t2 = TY_int) then TY_int
                                          else raise (TypeError "Using non-integer values on arithmetic operation")
                            | _        -> raise (Failure "Reached unreachable :(")

let rec sem_cond cond env = (* this entire fucntion could well be useless... On second thought... C_expr case is useful*)
  match cond with
  | C_bool1 (op, c)      -> (match op with
                            | Op_not -> sem_cond c env
                            | _      -> raise (Failure "Reached unreachable :("))
  | C_bool2 (c1, op, c2) -> (match op with
                            | Op_and -> let t1 = sem_cond c1 env in
                                        let t2 = sem_cond c2 env in
                                        (match t1, t2 with TY_bool, TY_bool -> TY_bool)
                            | _      -> raise (Failure "Reached unreachable :("))
  | C_expr (e1, op, e2)  -> match op with
                            | Op_eq
                            | Op_hash
                            | Op_less
                            | Op_lesseq
                            | Op_greater
                            | Op_greatereq   -> let t1 = sem_expr env e1 in
                                                let t2 = sem_expr env e2 in (* handle the case of chars nad check both t1 and t2*)
                                                (match t1, t2 with 
                                                | TY_int, TY_int   -> TY_bool
                                                | TY_char, TY_char -> TY_bool
                                                | _, _             -> raise (TypeError "Comparing non-integer (or non-char) values on condition"))
                            | _              -> raise (Failure "Reached unreachable :(")
      
(* helpers. check what is needed and move to top *)
let paramsToEnventry params =
  match params with
  | F_params (ref, vars, t)  
  -> (match t with
      | TY_int             -> (match ref with
                              | Some _ -> ("ref", List.map (function _ -> IntEntry) vars)
                              | None   -> ("noref", List.map (function _ -> IntEntry) vars))
      | TY_char            -> (match ref with
                              | Some _ -> ("ref", List.map (function _ -> CharEntry) vars)
                              | None   -> ("noref", List.map (function _ -> CharEntry) vars))
      | TY_array (t, dims) -> (match ref with
                              | Some _ -> ("ref", List.map (function _ -> ArrayEntry(t, dims)) vars)
                              | None   -> ("noref", List.map (function _ -> ArrayEntry(t, dims)) vars))
      | _                  -> raise (Failure "Reached unreachable :("))
  | _ -> raise (Failure "Reached unreachable :(")

let rec addVars env vars t =
  match vars with
  | hd::tl  -> addVars (insertST env hd t) tl t
  | []      -> env

let rec paramsToTypes fparams acc =
  match fparams with
  | hd::tl -> (match hd with
              | F_params (ref, params, t) -> paramsToTypes tl (List.map (function _ -> t) params) @ acc
              | _                         -> raise (Failure "Reached unreachable :("))
  | []     -> acc

  (* ------------------------------------------------- *)



  (* na dw pws nasymperifertai se fdecl kai se fdef*)
let rec sem_decl env decl =
  match decl with
  | F_params (_, vars, t)    -> (match t with  (* prepei na kanw check gia duplicate variable!!!!*)
                                | TY_int             -> addVars env vars IntEntry
                                | TY_char            -> addVars env vars CharEntry
                                | TY_array (t, dims) -> addVars env vars (ArrayEntry (t, dims))
                                | _                  -> raise (Failure "Reached unreachable :("))
  | F_head (name, params, t) -> (match params with
                                | Some ps  -> let env = List.fold_left sem_decl env ps in
                                              let types = paramsToTypes ps [] in
                                              insertST env name (FunEntry(t, types))
                                | None     -> insertST env name (FunEntry(t, [])))
  | F_def (h, locals, block) -> let env = sem_decl env h in
                                let env = List.fold_left sem_decl env locals in
                                if sem_stmt env block then env else raise (TypeError "aa") (*dummy error, look into this when using this in main*)
  | F_decl decl              -> raise (Failure "aa")     (* dummy*)
  | V_def (vars, t)          -> (match t with  (* prepei na kanw check gia duplicate variable!!!!*)
                                | TY_int             -> addVars env vars IntEntry
                                | TY_char            -> addVars env vars CharEntry
                                | TY_array (t, dims) -> addVars env vars (ArrayEntry (t, dims))
                                | _                  -> raise (Failure "Reached unreachable :("))

and sem_stmt env stmt =
  match stmt with
  | S_fcall (name, exprs)  -> let func = lookupST name env in
                              let types = match exprs with
                                          | Some es -> List.map (sem_expr env) es
                                          | None    -> [] in
                              (match func with 
                              | FunEntry (t, params) -> if types = params then true else raise (TypeError "Wrong parameters were given to function when called")
                              | _               -> raise (TypeError (name ^ " is a variable, not a function")))
  | S_colon _              -> true
  | S_assign (e1, e2)      -> let t1 = sem_expr env e1 in
                              let t2 = sem_expr env e2 in
                              if t1 = t2 then true else raise (TypeError "Assignment with different types")
  | S_block stmts          -> let checkList = List.map (sem_stmt env) stmts in (* if false in list raise error else true*)
                              not (List.mem false checkList)
  | S_if (c, s)            -> let t = sem_cond c env in
                              if t = TY_bool then sem_stmt env s else raise (TypeError "if statement doesn't have condition")
  | S_ifelse (c, s1, s2)   -> let t = sem_cond c env in
                              if t = TY_bool then sem_stmt env s1 && sem_stmt env s2 else raise (TypeError "if/else statement doesn't have condition")
  | S_while (c, s)         -> let t = sem_cond c env in
                              if t = TY_bool then sem_stmt env s else raise (TypeError "while statement doesn't have condition")
  | S_return e             -> raise (Failure "aa") (*dummy*)