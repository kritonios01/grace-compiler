(* module type Symbol = sig
  type symbol
  val symbol : string -> symbol
  val name : symbol -> string
  (* type 'a table *)
  val empty : 'a table
  val enter : 'a table * symbol * 'a -> 'a table
  val look : 'a table * symbol * 'a -> 'a option
end *)


(* we use the hashtable in order to compare integers and not strings for each var *)
module M : Symbol = struct
  type symbol = string * int (* string should be var? *)
  exception Symbol
  let next = ref 0
  let hashtable = Hashtbl.create 64
  let symbol name =
    let entry = Hashtbl.find_opt hashtable name in
    match entry with
    | Some v -> (name, v)
    | None   -> let i = !next in
                  incr next; (* next++ *)
                  Hashtbl.add hashtable name i;
                  (name, i)

  let name (s, i) = s
  (* type 'a table = 'a  *)
  module SymbolMap = Map.Make(struct
      type t = int
      let compare = Stdlib.compare
    end)

  let t = SymbolMap.type
  let empty = symbolMap.empty
  let enter k v = symbolMap.add 

end