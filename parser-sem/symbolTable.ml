(* module type Symbol = sig
  type symbol
  val symbol : string -> symbol
  val name : symbol -> string
  (* type 'a table *)
  val empty : 'a table
  val enter : 'a table * symbol * 'a -> 'a table
  val look : 'a table * symbol * 'a -> 'a option
end *)

exception UnknownVar


type enventry =
  | VarEntry
  | FunEntry

(* we use the hashtable in order to compare integers and not strings for each var *)
module M (*: Symbol*) = struct
  type symbol = string * int (* string should be var? symbol is the tuple of var and its mapping i *)
  exception Symbol
  let next = ref 0
  let hashtable: (string, int) Hashtbl.t = Hashtbl.create 128
  let symbol name = (* returns the name and its mapping *)
    let entry = Hashtbl.find_opt hashtable name in
    match entry with
    | Some v -> (name, v)
    | None   -> let i = !next in
                  incr next; (* next++ *)
                  Hashtbl.add hashtable name i;
                  (name, i)

  (* kapou prepei na ginei to handling ths allaghs mias metavlitis*)
  let name (s, i) = s

  module SymbolMap = Map.Make(struct (* maps ints (vars) to their values*)
      type t = int   (* var? *)
      let compare = Stdlib.compare (* h compare function prepei na xrhsimopoiei to hashtable *)
    end)

  (* type 'a table = 'a SymbolMap.map *)

  let initST = SymbolMap.empty
  let insertST k v mapping = 
    SymbolMap.add k v mapping

  let lookupST k mapping = 
    let entry = SymbolMap.find_opt k mapping in
      match entry with
      | Some value -> value
      | None       -> raise UnknownVar

end