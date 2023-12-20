type symbol =
  string

type env_entry =
  | IntEntry of int option
  | CharEntry of char option
  | NoneEntry
  | IntArrayEntry of int list * int list (* list1 is dimensions, list2 is values *)
  | CharArrayEntry of int list * char list (* list1 is dimensions, list2 is values *)
  | FunEntry of Ast.typ * env_entry list 
  (* | FunEntry of  *)

exception Symbol of Ast.var

module SymbolTable = Map.Make(struct
    type t = symbol
    let compare = Stdlib.compare
  end)


let emptyTbl = SymbolTable.empty

let insertTbl mapping k v = 
  SymbolTable.add k v mapping

let lookupST k mapping = 
  let entry = SymbolTable.find_opt k mapping in
    match entry with
    | Some value -> value
    | None       -> raise Symbol k