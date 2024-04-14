(* Here we define a bunch of helper functions, types (and whatever else)
   that is needed for the compiler so that compiler.ml is not bloated *)

open Llvm
open Symbol

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
  stack_frames : llvalue FunctionsToFrames.t;
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
let extract_ST_llv x = (* Some matches are pending!! *)
  match x with
  | BasicEntry (llv, _)          -> llv
  | CompositeEntry (llv, _, _)   -> llv
  | FuncParamEntry (llv, _)      -> llv
  | StackFrameEntry (_, struct_, _) -> struct_
  | _ -> assert false

let extract_ST_llt ptr =
  match ptr with
  | BasicEntry (_, ty)        -> ty
  | CompositeEntry (_, _, ty) -> ty
  | FuncParamEntry (_, ty)    ->
      (match ty with
      | Some llt -> llt
      | None     -> assert false)
  | StackFrameEntry (_, _, _) -> assert false
  | FuncEntry ty              -> ty

(* ST entries have a type because pointers in LLVM are opaque so we need to store and retrieve their type from a higher level structure *)
let classify_ptr ptr =
  extract_ST_llt ptr |> classify_type



let extract_struct_info x =
  match x with
  | StackFrameEntry (orig, _, pos) -> (orig, pos)  (* isos na min xreiazetai katholou to original, px sto S_assign *)
  | _ -> assert false





(* --- Helper functions for LLVM IR ---------------------------------------*)

(* Calculate linear index with array linearization algorithm *)
let compute_linear_index llvm dims indices =
  let folder (acc, prod) (dim, index) =
    let dim_val = llvm.c64 dim in
    let offset = build_mul index prod "multmp" llvm.bd in
    let new_acc = build_add acc offset "addtmp" llvm.bd in
    let new_prod = build_mul prod dim_val "prodtmpp" llvm.bd in
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