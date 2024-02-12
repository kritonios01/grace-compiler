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

(* let rec sem_matrix env expr acc =
  match expr with
  | L_string_lit s     -> sem_expr (L_string_lit s)
  | L_id var           -> sem_expr (L_id var)
  | L_matrix (e1, e2)  -> let t2 = sem_expr env e2 in     (*sem_matrix e1 *)
                          match t2 with
                          | TY_int ->  *)


                          
let rec custom_checklist l1 l2 =
  match l1, l2 with
  | h1::t1, h2::t2 -> if h1=h2 then (true && (custom_checklist t1 t2)) else
                      (match h1, h2 with
                      | TY_array(typ1, _::dims1), TY_array(typ2, 0::dims2) -> typ1=typ2 && dims1=dims2 && (custom_checklist t1 t2)
                      | _, _                                           -> (*let _ = List.map (Printf.printf "%s\n") (List.map printer [h1;h2]) in*) false)
  | [], []         -> true
  | _, _           -> false

let rec sem_expr env expr =
  match expr with
  | E_int_const i        -> TY_int
  | E_char_const c       -> TY_char
  | L_string_lit s       -> TY_array (TY_char, [String.length s + 1])
  | L_id var             -> (match (lookupST var env) with
                            | IntEntry _               -> TY_int
                            | CharEntry _              -> TY_char
                            | ArrayEntry (t, dims, _)    -> TY_array (t, dims) 
                            | _                       -> raise (TypeError "Expected var name but found function name as l-value"))
  | L_matrix (e1, e2)    -> let t1 = sem_expr env e1 in
                            let t2 = sem_expr env e2 in
                            (* printST env; *)
                            (match t2 with
                            | TY_int -> (*t1 *)    (* needs checking for 2+ dims*) (* here check for index out of bounds, difficult currently... have to have values for ints *)
                                        (match t1 with
                                        | TY_array (t, dims) -> t
                                        | TY_int
                                        | TY_char            -> t1(*raise (TypeError "Using a variable of type int or char as an array")*)
                                        | _                  -> t1)
                            | _      -> raise (TypeError "index of array/matrix is not an int"))
  | E_fcall stmt   -> (match stmt with
                      | S_fcall (name, ps) -> let func = lookupST name env in
                                              let types = match ps with
                                                          | Some es -> List.map (sem_expr env) es
                                                          | None    -> [] in
                                              (* Printf.printf "%s\n" name;
                                              printST env; *)
                                              (match func with 
                                              | FunEntry (t, params) -> if custom_checklist types params then t else raise (TypeError "Wrong parameters were given to function when called")
                                              | _               -> raise (TypeError (name ^ " is a variable, not a function")))
                      | _                  -> raise (Failure "1 Reached unreachable :("))
  | E_op1 (op, e)        -> (match op with
                            | Op_plus  
                            | Op_minus -> let t = sem_expr env e in
                                          if t = TY_int then TY_int
                                          else raise (TypeError "Using non-integer values on arithmetic operation")
                            | _        -> raise (Failure "2 Reached unreachable :("))
  | E_op2 (e1, op, e2)   -> match op with
                            | Op_plus 
                            | Op_minus 
                            | Op_times
                            | Op_div
                            | Op_mod   -> let t1 = sem_expr env e1 in
                                          let t2 = sem_expr env e2 in
                                          if (t1 = TY_int && t2 = TY_int) then TY_int
                                          else raise (TypeError "Using non-integer values on arithmetic operation")
                            | _        -> raise (Failure "3 Reached unreachable :(")

let rec sem_cond cond env = (* this entire fucntion could well be useless... On second thought... C_expr case is useful*)
  match cond with
  | C_bool1 (op, c)      -> (match op with
                            | Op_not -> sem_cond c env
                            | _      -> raise (Failure "4 Reached unreachable :("))
  | C_bool2 (c1, op, c2) -> (match op with
                            | Op_and 
                            | Op_or  -> let t1 = sem_cond c1 env in
                                        let t2 = sem_cond c2 env in
                                        (match t1, t2 with TY_bool, TY_bool -> TY_bool)
                            | _      -> raise (Failure "5 Reached unreachable :("))
  | C_expr (e1, op, e2)  -> match op with
                            | Op_eq
                            | Op_hash
                            | Op_less
                            | Op_lesseq
                            | Op_greater
                            | Op_greatereq   -> let t1 = sem_expr env e1 in
                                                let t2 = sem_expr env e2 in (* handle the case of chars nad check both t1 and t2*)
                                                (* printST env; *)
                                                (match t1, t2 with 
                                                | TY_int, TY_int   -> TY_bool
                                                | TY_char, TY_char -> TY_bool
                                                | _, _             -> raise (TypeError "Comparing non-integer (or non-char) values on condition"))
                            | _              -> raise (Failure "6 Reached unreachable :(")
      
(* helpers. check what is needed and move to top *)
(* let paramsToEnventry params =            THIS MAY BE NEEDED for fparams that are passed by reference, but currently not used
  match params with
  | F_params (ref, vars, t)  
  -> (match t with
      | TY_int             -> (match ref with
                              | Some _ -> ("ref", List.map (function _ -> IntEntry 0) vars)
                              | None   -> ("noref", List.map (function _ -> IntEntry 0) vars))
      | TY_char            -> (match ref with
                              | Some _ -> ("ref", List.map (function _ -> CharEntry) vars)
                              | None   -> ("noref", List.map (function _ -> CharEntry) vars))
      | TY_array (t, dims) -> (match ref with
                              | Some _ -> ("ref", List.map (function _ -> ArrayEntry(t, dims)) vars)
                              | None   -> ("noref", List.map (function _ -> ArrayEntry(t, dims)) vars))
      | _                  -> raise (Failure "7 Reached unreachable :("))
  | _ -> raise (Failure "8 Reached unreachable :(") *)

let rec addVars env vars t =
  match vars with
  | hd::tl  -> addVars (insertST env hd t) tl t
  | []      -> env

let rec paramsToTypes fparams acc =
  match fparams with
  | hd::tl -> (match hd with
              | F_params (ref, params, t) -> paramsToTypes tl (acc @ (List.map (function _ -> t) params))
              | _                         -> raise (Failure "9 Reached unreachable :("))
  | []     -> acc

  (* ------------------------------------------------- *)

  (* printer is for debugging only *)
let rec printer e =
  match e with
  | TY_int   -> "int "
  | TY_char  -> "char "
  | TY_none  -> "none "
  | TY_array (t,l) -> "TY_array(t:" ^ printer t ^ ", dims:" ^ list_to_string (List.map string_of_int l) ^ ") "



  (* na dw pws nasymperifertai se fdecl kai se fdef*)
  (* na mpei kanonas oti ta arrays pernoun mono by reference stis synarthseis*)



let rec sem_decl env decl =
  match decl with
  | F_params (_, vars, t)    -> (match t with  (* prepei na kanw check gia duplicate variable!!!!*)
                                | TY_int             -> addVars env vars (IntEntry None)
                                | TY_char            -> addVars env vars (CharEntry None)
                                | TY_array (t, dims) -> addVars env vars (ArrayEntry (t, dims, None))
                                | _                  -> raise (Failure "10 Reached unreachable :("))
  | F_head (name, params, t) -> (match params with (* check oti o typos epistrofhs den einai pinakas *)
                                | Some ps  -> let env = List.fold_left sem_decl env ps in
                                              let types = paramsToTypes ps [] in
                                              insertST env name (FunEntry(t, types))
                                | None     -> insertST env name (FunEntry(t, [])))
  | F_def (h, locals, block) -> let env = sem_decl env h in
                                let env = List.fold_left sem_localdef env locals in
                                if sem_stmt env block then env else raise (TypeError "aa") (*dummy error, look into this when using this in main.ml*)
  | F_decl head              -> (match head with
                                | F_head (name, params, t) -> (match params with
                                                              | Some ps  -> let types = paramsToTypes ps [] in
                                                                            insertST env name (FunEntry(t, types))
                                                              | None     -> insertST env name (FunEntry(t, [])))
                                | _                        -> raise (Failure "11 Reached unreachable :("))
  | V_def (vars, t)          -> (match t with  (* prepei na kanw check gia duplicate variable! dyskolo...*)
                                | TY_int             -> addVars env vars (IntEntry None)
                                | TY_char            -> addVars env vars (CharEntry None)
                                | TY_array (t, dims) -> addVars env vars (ArrayEntry (t, dims, None))
                                | _                  -> raise (Failure "12 Reached unreachable :("))

and sem_localdef env local =
  match local with
  | F_def (h, locals, block) -> let henv = sem_decl env (F_decl h) in (*we return the environment which includes the bindings of the func definition but we ignore its local-bindings as they are not visible to the program outside this func-def *)
                                let _ = sem_decl env (F_def (h, locals, block)) in
                                henv
  | F_decl h                 -> sem_decl env (F_decl h)
  | V_def (vars, t)          -> sem_decl env (V_def (vars, t))
  | _                        -> raise (Failure "13 Reached unreachable :(")
(* handle thn periptwsh pou ginetai F_def alla exei ginei F_decl apo prin *)
(* na tsekarw oti mutually recursive functions exoun ginei decl apo prin *)
and sem_stmt env stmt =
  match stmt with
  | S_fcall (name, exprs)  -> let func = lookupST name env in
                              let types = match exprs with
                                          | Some es -> List.map (sem_expr env) es
                                          | None    -> [] in
                              (* printST env; *)
                              (* Printf.printf "%s" name; *)
                              (* if name = "writeInteger" then printST env else [()]; *)
                              (match func with (* na valw ena kalytero exception message gia to type error me onoma synarthshs ktl*)
                              | FunEntry (t, params) -> if custom_checklist types params then true else (*let _ = printST env in *)raise (TypeError "stmt Wrong parameters were given to function when called") 
                              | _                    -> raise (TypeError (name ^ " is a variable, not a function")))
  | S_colon _              -> true
  | S_assign (e1, e2)      -> let t1 = sem_expr env e1 in
                              let t2 = sem_expr env e2 in
                              begin
                                match t1, t2 with
                                | TY_array(_, _), TY_array(_, _) -> true
                                | TY_int, TY_int -> true
                                | TY_char, TY_char -> true
                                | _, _ -> raise (TypeError "left and right values of assignment do not type-match")
                              end
                              (* if t1 = t2 then true else raise (TypeError "left and right values of assignment do not type-match") *)
  | S_block stmts          -> let checkList = List.map (sem_stmt env) stmts in
                              not (List.mem false checkList)
  | S_if (c, s)            -> let t = sem_cond c env in
                              if t = TY_bool then sem_stmt env s else raise (TypeError "if statement doesn't have condition")
  | S_ifelse (c, s1, s2)   -> let t = sem_cond c env in
                              if t = TY_bool then sem_stmt env s1 && sem_stmt env s2 else raise (TypeError "if/else statement doesn't have condition")
  | S_while (c, s)         -> let t = sem_cond c env in
                              if t = TY_bool then sem_stmt env s else raise (TypeError "while statement doesn't have condition")
  | S_return e             -> true (* have to check for function type and then this type... seems difficult with current grammar *)






let predefined = [
  ("writeInteger", FunEntry(TY_none, [TY_int]));
  ("writeChar", FunEntry(TY_none, [TY_char]));
  ("writeString", FunEntry(TY_none, [TY_array(TY_char, [0])]));
  ("readInteger", FunEntry(TY_int, []));
  ("readChar", FunEntry(TY_char, []));
  ("readString", FunEntry(TY_none, [TY_int; TY_array(TY_char, [0])]));
  ("ascii", FunEntry(TY_int, [TY_char]));
  ("chr", FunEntry(TY_char, [TY_int]));
  ("strlen", FunEntry(TY_int, [TY_array(TY_char, [0])]));
  ("strcmp", FunEntry(TY_int, [TY_array(TY_char, [0]); TY_array(TY_char, [0])]));
  ("strcpy", FunEntry(TY_none, [TY_array(TY_char, [0]); TY_array(TY_char, [0])]));
  ("strcat", FunEntry(TY_none, [TY_array(TY_char, [0]); TY_array(TY_char, [0])]))
]

let addPredefined env =
  let rec addfuncs e funcs =
    match funcs with
    | hd::tl  -> let (k,v) = hd in addfuncs (insertST e k v) tl
    | []      -> e
  in addfuncs env predefined




let sem_ast ast =
  let predefined_env = addPredefined emptyST in 
  sem_decl predefined_env ast
