(* Here we define a bunch of helper functions, types (and whatever else)
   that is needed for the compiler so that compiler.ml is not bloated *)

open Llvm
open Symbol_tables

(* this record type helps keep the llvm bureaucracy nice and tidy.
   an object of this type is passed in every AST function in compiler.ml *)
type llvm_info = {
  ctx              : llcontext;
  md               : llmodule;
  bd               : llbuilder;
  i1               : lltype;
  i8               : lltype;
  i32              : lltype;
  i64              : lltype;
  c1               : int -> llvalue;
  c8               : int -> llvalue;
  c32              : int -> llvalue;
  c64              : int -> llvalue;
  void             : lltype;
  ptr              : lltype;
  predefined_fs    : string list;
}

(* maps a function name to its struct so that it can be used when called
   It is unclear for now if this will be used eventually, because as it is 
   it limits local function calls to the parent function only...*)
module FunctionsToFrames = Map.Make(String)

(* this record keeps the parent function's info throughout the 
   code-generation of all its locals and stmts*)
type func_info = {
  the_f   : llvalue;
  name    : symbol;
  stack_frame_ty : lltype option;

  (* stack_frames : llvalue FunctionsToFrames.t; *)
}







(* --- Helper functions and types for the compiler's ST ------------------------ *)

(* we define types for pointers to compensate for LLVM 16's lack of pointer types *)
(* type pointer_types =
  | Array_ptr of Llvm.lltype
  | Int_ptr of Llvm.lltype
  | Struct_ptr *)

(* let classify_ptr ptr = (* !!FuncparamEntry is pending!! *)
  match ptr with
  | BasicEntry (_, ty) -> Int_ptr ty
  | CompositeEntry (_, _, ty) -> Array_ptr ty
      match ty with
      | Some llt -> 
      | None -> assert false
  | StackFrameEntry (_, _, _) -> Struct_ptr
  | _ -> assert false *)



(* these are to extract fields from the ST *)
let rec extract_llv x = (* Some matches are pending!! *)
  match x with
  | BasicEntry (llv, _)          -> llv
  | CompositeEntry (llv, _, _)   -> llv
  | FuncParamEntry (llv, _, _)   -> llv
  | StackFrameEntry (entry, _)   -> extract_llv entry
  | _ -> assert false


let rec extract_llt ptr =
  match ptr with
  | BasicEntry (_, ty)        -> ty
  | CompositeEntry (_, _, ty) -> ty
  | FuncParamEntry (_, _, ty) ->
      (match ty with
      | Some llt -> llt
      | None     -> assert false)
  | StackFrameEntry (entry, _) -> extract_llt entry
  | FuncEntry (ty, _)               -> ty

(* llvm -> the llvm bureaucracy
   func -> func_info for stackframe and its type 
   ptr  -> bool: true doesn't load the pointer and false does *)
let codegen_llenv_entry llvm func ptr entry  =
  match entry with
  | BasicEntry (llv, llt) -> (* if llv is pointer we use llt, otherwise (if llv is integer) llt is useless *)
      (match classify_type (type_of llv) with
      | Pointer ->
          (match classify_type llt with
          | Integer -> if ptr = false then build_load llt llv "beload" llvm.bd else llv
          | _       -> assert false)
      | Integer -> if ptr = false then llv else assert false
      | _       -> assert false)
  | CompositeEntry (llv, _, llt) ->
      (match classify_type llt with
      | Array -> if ptr = true then build_gep llt llv [| llvm.c64 0; llvm.c64 0 |] "arrptr" llvm.bd else assert false
      | _     -> assert false)

  | FuncParamEntry (llv, _, llt) ->
      (match classify_type (type_of llv) with
      | Pointer ->
          let ptr_ty = try Option.get llt with Invalid_argument _ -> assert false in
          (match classify_type ptr_ty with
          | Integer -> if ptr = true then llv else build_load ptr_ty llv "farg" llvm.bd
          | Array   -> if ptr = true then build_gep ptr_ty llv [| llvm.c64 0; llvm.c64 0 |] "arrptr" llvm.bd else assert false
          | _       -> assert false)
      | Integer -> llv (*if ptr = false then llv else assert false*) (* kept llv alone so that this works for stackframes as well *)
      | _       -> assert false)
  | StackFrameEntry (entry, index) -> (* if we put type_of entry instead of entry in the costructor this can get simpler. but is it possible? *)
      let frame_ptr = (params func.the_f).(0) in
      let frame_ty = try Option.get func.stack_frame_ty with Invalid_argument _ -> assert false in
      let frame_element_ptr = build_struct_gep frame_ty frame_ptr index "frame_var" llvm.bd in
      let frame_element_ptr = build_load llvm.ptr frame_element_ptr "test_load" llvm.bd in (* this is not tested...*)
      (match ptr with
      | true  -> frame_element_ptr (* prepei na testaristei oti an einai array to item tou stackframe ti ginetai?*)
      | false ->
          let element_ty = extract_llt entry in
          build_load element_ty frame_element_ptr "farg" llvm.bd)
  | _ -> assert false 

(* ST entries have a type because pointers in LLVM are opaque so we need to store and retrieve their type from a higher level structure *)
let classify_ptr ptr =
  extract_llt ptr |> classify_type

let extract_struct_index x =
  match x with
  | StackFrameEntry (_, pos) -> Some pos  (* isos na min xreiazetai katholou to original, px sto S_assign *)
  | _                        -> None

let rec extract_array_dims x =
  match x with
  | CompositeEntry (_, dims, _) -> dims
  | FuncParamEntry (_, dims, _) -> (try Option.get dims with Invalid_argument _ -> assert false)
  | StackFrameEntry (entry, _)  -> extract_array_dims entry
  | _ -> assert false





(* --- Helper functions for LLVM IR ---------------------------------------*)

(* Calculate linear index with array linearization algorithm *)
let compute_linear_index llvm (indices, dims) =
  let folder (acc, prod) (dim, index) =
    let dim_val = llvm.c64 dim in
    let offset = build_mul index prod "mmultmp" llvm.bd in
    let new_acc = build_add acc offset "maddtmp" llvm.bd in
    let new_prod = build_mul prod dim_val "mprodtmp" llvm.bd in
    (new_acc, new_prod) in
  
  (* Initial accumulator for fold is (0, 1) because index = 0 + i_1 * 1 initially *)
  let (linear_index, _) = List.(fold_left folder (llvm.c64 0, llvm.c64 1) (combine (rev dims) (rev indices))) in
  linear_index




(* this function is no longer needed as array indexes are computed with
   llvm ir now. It is kept here in the unlikely scenario that it will be needed *)
(* helper function to compute index of linearized multi-dim array*)
(* let compute_linear_index dimensions indices =
  let rec aux acc dims indices =
    match dims, indices with
    | [], [] -> acc
    | d :: rest_dims, i :: rest_indices ->
      let acc' = acc * d + i in
      aux acc' rest_dims rest_indices
    | _ -> failwith "Mismatched dimensions and indices"
  in
  aux 0 dimensions indices *)

let rec split3 l (acc1, acc2, acc3) =
  match l with
  | [] -> List.(rev acc1, rev acc2, rev acc3)
  | x::xs ->
      match x with
      | (a, b, c) -> split3 xs (a::acc1, b::acc2, c::acc3)





  (* these helpers are for the compiler's symbol table. It stores llvalues *)
let llvmSTvalues mapping = (* this should probably get removed *)
  let keys, values =
    List.(filter (fun (name, entry) ->
      match entry with
      | FuncEntry _ -> false
      | _ -> true
    ) (SymbolTable.bindings mapping) 
    |> split) in
  let values = List.map extract_llv values in
  keys, values

let llvmST_to_llenv_entries mapping = (* returns all entries in symbol table except FuncEntries *)
  let keys, values =
    List.(filter (fun (name, entry) ->
      match entry with
      | FuncEntry _ -> false
      | _ -> true
    ) (SymbolTable.bindings mapping) 
    |> split) in
  keys, values


let printllvmST mapping =
  let open Llvm in
  let keys, values = llvmSTvalues mapping in
  List.map (fun x -> string_of_lltype (type_of x)) values
  |> List.iter2 (Printf.printf "%s -> %s | ") keys ;
  Printf.printf "\n"

let print_llenv_entry x =
  let open Llvm in
  (match x with
  | BasicEntry (llv, _)         -> "Basic Entry: "^(string_of_llvalue llv)^"\n"
  | CompositeEntry (llv, _, _)  -> "Composite Entry: "^(string_of_llvalue llv)^"\n"
  | FuncParamEntry (llv, _, _)  -> "FuncParam Entry: "^(string_of_llvalue llv)^"\n"
  | StackFrameEntry (llv, _)    -> let x = extract_llv llv in "StackFrame Entry: "^(string_of_llvalue x)^"\n" 
  | _ -> assert false)
  |> print_string



let add_remaining_indices llvm indices dims =
  let rec helper dims indices acc_indices =
    let open List in
    match dims with
    | x::xs when length indices > 0 -> helper xs (tl indices) acc_indices
    | x::xs when length indices = 0 -> helper xs indices ((llvm.c64 0)::acc_indices)
    | _ -> acc_indices
  in indices@(helper dims indices []), dims
  (* last pattern match should be [] but ocaml warns that the pattern-matching is non exhaustive (while it is) *)

let rec remove_left_dims indices dims =
  match indices, dims with
  | i::is, d::ds -> remove_left_dims is ds
  | [], _        -> dims, List.fold_left ( * ) 1 dims
  | _, _         -> assert false