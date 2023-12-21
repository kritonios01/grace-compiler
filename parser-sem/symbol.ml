type symbol =
  string

type env_entry =
  | IntEntry of int option
  | CharEntry of char option
  | IntArrayEntry of int list * int list (* list1 is dimensions, list2 is values *)
  | CharArrayEntry of int list * char list (* list1 is dimensions, list2 is values *)
  | NoneEntry
  | FunEntry of Ast.typ * env_entry list 
  (* | FunEntry of  *)

exception Symbol of symbol

module SymbolTable = Map.Make(struct
    type t = symbol
    let compare = Stdlib.compare
  end)


let emptyST = SymbolTable.empty

let insertST mapping k v = 
  SymbolTable.add k v mapping

let lookupST k mapping = 
  let entry = SymbolTable.find_opt k mapping in
    match entry with
    | Some value -> value
    | None       -> raise (Symbol k)