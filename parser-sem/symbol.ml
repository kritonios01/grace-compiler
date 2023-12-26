type symbol =
  string

type env_entry =
  | IntEntry
  | CharEntry
  | ArrayEntry of Ast.typ * int list (* * int list*) (* list1 is dimensions, list2 is values *)
  | FunEntry of Ast.typ * Ast.typ list (* string -> ref or noref *)
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