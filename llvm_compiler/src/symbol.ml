type symbol =
  string

exception SymbolExc of symbol * string



type env_entry =
  | IntEntry of int option
  | CharEntry of char option
  | ArrayEntry of Ast.typ * int list * string option(* * int list*) (* list1 is dimensions, list2 is values *)
  | FunEntry of Ast.typ * Ast.typ list (* string -> ref or noref *)
  (* | FunEntry of  *)



module SymbolTable = Map.Make(struct
    type t = symbol
    let compare = Stdlib.compare
  end)


let emptyST = SymbolTable.empty

let insertST mapping k v = 
  SymbolTable.add k v mapping

let duplicateST key mapping = 
  SymbolTable.find key mapping
(* epeidh otan vazoume metavlites den jeroume poies einai duplicate
   (otan yparxoun apo prin kanoume overwrite kai otan orizontai 
   sto idio block einai duplicate) mporoume na ftiaxnoume ena 
   neo symboltable kathe fora kai me merge h union sto telos na 
   krataw ayta poy prepei *)

let lookupST k mapping = 
  let entry = SymbolTable.find_opt k mapping in
    match entry with
    | Some value -> value
    | None       -> raise (SymbolExc (k, "Unknown variable/function"))

let rec list_to_string l =
  match l with
  | [] -> ""
  | [a] -> a
  | (h::t) -> h ^ ", " ^ (list_to_string t)

(* helper for debugging *)
let printST mapping =
  let string_of_value v =
    let rec string_of_typ s t =
      match t with
      | Ast.TY_int   -> s ^ "int "
      | Ast.TY_char  -> s ^ "char "
      | Ast.TY_none  -> s ^ "none "
      | Ast.TY_array (ty,l) -> s ^ "TY_array(t:" ^ string_of_typ "" ty ^ ", dims:" ^ list_to_string (List.map string_of_int l) ^ ") " in
    match v with
    | IntEntry _ -> "IntEntry"
    | CharEntry _ -> "CharEntry"
    | ArrayEntry (t, l1, l2) -> "ArrayEntry(type:" ^ string_of_typ "" t ^ ", dims:" ^ list_to_string (List.map string_of_int l1) ^ ")"
    | FunEntry (t, l)   -> "FunEntry(type:" ^ string_of_typ "" t ^ ", params:" ^ (List.fold_left string_of_typ "" l) ^ ")" in
  let helper (k, v) = 
    Printf.printf "%s -> %s\n" k (string_of_value v) in
  let mapList = SymbolTable.bindings mapping in
  List.map helper mapList

let printllvmST mapping =
  let open Llvm in
  let keys, values = List.split (SymbolTable.bindings mapping) in
  let (vs, _) = List.split values in
  let vs = List.map (fun x -> string_of_lltype (type_of x)) vs in
  List.iter2 (Printf.printf "%s -> %s | ") keys vs;
  Printf.printf "\n"

let llvmSTvalues mapping =
  let keys, values = List.split (SymbolTable.bindings mapping) in
  let values, _ = List.split values in
  keys, values