
module MenhirBasics = struct
  
  exception Error
  
  let _eRR =
    fun _s ->
      raise Error
  
  type token = 
    | T_var
    | T_times
    | T_then
    | T_rparen
    | T_print
    | T_plus
    | T_minus
    | T_lparen
    | T_let
    | T_if
    | T_for
    | T_eq
    | T_eof
    | T_end
    | T_do
    | T_const
    | T_begin
  
end

include MenhirBasics

type ('s, 'r) _menhir_state = 
  | MenhirState00 : ('s, _menhir_box_program) _menhir_state
    (** State 00.
        Stack shape : .
        Start symbol: program. *)

  | MenhirState01 : (('s, _menhir_box_program) _menhir_cell1_T_print, _menhir_box_program) _menhir_state
    (** State 01.
        Stack shape : T_print.
        Start symbol: program. *)

  | MenhirState03 : (('s, _menhir_box_program) _menhir_cell1_T_lparen, _menhir_box_program) _menhir_state
    (** State 03.
        Stack shape : T_lparen.
        Start symbol: program. *)

  | MenhirState06 : (('s, _menhir_box_program) _menhir_cell1_expr, _menhir_box_program) _menhir_state
    (** State 06.
        Stack shape : expr.
        Start symbol: program. *)

  | MenhirState09 : (('s, _menhir_box_program) _menhir_cell1_expr, _menhir_box_program) _menhir_state
    (** State 09.
        Stack shape : expr.
        Start symbol: program. *)

  | MenhirState11 : (('s, _menhir_box_program) _menhir_cell1_expr, _menhir_box_program) _menhir_state
    (** State 11.
        Stack shape : expr.
        Start symbol: program. *)

  | MenhirState16 : (('s, _menhir_box_program) _menhir_cell1_T_let, _menhir_box_program) _menhir_state
    (** State 16.
        Stack shape : T_let.
        Start symbol: program. *)

  | MenhirState18 : (('s, _menhir_box_program) _menhir_cell1_T_if, _menhir_box_program) _menhir_state
    (** State 18.
        Stack shape : T_if.
        Start symbol: program. *)

  | MenhirState20 : ((('s, _menhir_box_program) _menhir_cell1_T_if, _menhir_box_program) _menhir_cell1_expr, _menhir_box_program) _menhir_state
    (** State 20.
        Stack shape : T_if expr.
        Start symbol: program. *)

  | MenhirState21 : (('s, _menhir_box_program) _menhir_cell1_T_for, _menhir_box_program) _menhir_state
    (** State 21.
        Stack shape : T_for.
        Start symbol: program. *)

  | MenhirState23 : ((('s, _menhir_box_program) _menhir_cell1_T_for, _menhir_box_program) _menhir_cell1_expr, _menhir_box_program) _menhir_state
    (** State 23.
        Stack shape : T_for expr.
        Start symbol: program. *)

  | MenhirState24 : (('s, _menhir_box_program) _menhir_cell1_T_begin, _menhir_box_program) _menhir_state
    (** State 24.
        Stack shape : T_begin.
        Start symbol: program. *)

  | MenhirState27 : (('s, _menhir_box_program) _menhir_cell1_stmt, _menhir_box_program) _menhir_state
    (** State 27.
        Stack shape : stmt.
        Start symbol: program. *)


and ('s, 'r) _menhir_cell1_expr = 
  | MenhirCell1_expr of 's * ('s, 'r) _menhir_state * (
# 29 "Parser.mly"
      (unit)
# 105 "Parser.ml"
)

and ('s, 'r) _menhir_cell1_stmt = 
  | MenhirCell1_stmt of 's * ('s, 'r) _menhir_state * (
# 28 "Parser.mly"
      (unit)
# 112 "Parser.ml"
)

and ('s, 'r) _menhir_cell1_T_begin = 
  | MenhirCell1_T_begin of 's * ('s, 'r) _menhir_state

and ('s, 'r) _menhir_cell1_T_for = 
  | MenhirCell1_T_for of 's * ('s, 'r) _menhir_state

and ('s, 'r) _menhir_cell1_T_if = 
  | MenhirCell1_T_if of 's * ('s, 'r) _menhir_state

and ('s, 'r) _menhir_cell1_T_let = 
  | MenhirCell1_T_let of 's * ('s, 'r) _menhir_state

and ('s, 'r) _menhir_cell1_T_lparen = 
  | MenhirCell1_T_lparen of 's * ('s, 'r) _menhir_state

and ('s, 'r) _menhir_cell1_T_print = 
  | MenhirCell1_T_print of 's * ('s, 'r) _menhir_state

and _menhir_box_program = 
  | MenhirBox_program of (
# 26 "Parser.mly"
      (unit)
# 137 "Parser.ml"
) [@@unboxed]

let _menhir_action_01 =
  fun () ->
    (
# 44 "Parser.mly"
                    ( () )
# 145 "Parser.ml"
     : (
# 29 "Parser.mly"
      (unit)
# 149 "Parser.ml"
    ))

let _menhir_action_02 =
  fun () ->
    (
# 45 "Parser.mly"
                  ( () )
# 157 "Parser.ml"
     : (
# 29 "Parser.mly"
      (unit)
# 161 "Parser.ml"
    ))

let _menhir_action_03 =
  fun () ->
    (
# 46 "Parser.mly"
                            ( () )
# 169 "Parser.ml"
     : (
# 29 "Parser.mly"
      (unit)
# 173 "Parser.ml"
    ))

let _menhir_action_04 =
  fun () ->
    (
# 47 "Parser.mly"
                      ( () )
# 181 "Parser.ml"
     : (
# 29 "Parser.mly"
      (unit)
# 185 "Parser.ml"
    ))

let _menhir_action_05 =
  fun () ->
    (
# 48 "Parser.mly"
                       ( () )
# 193 "Parser.ml"
     : (
# 29 "Parser.mly"
      (unit)
# 197 "Parser.ml"
    ))

let _menhir_action_06 =
  fun () ->
    (
# 49 "Parser.mly"
                       ( () )
# 205 "Parser.ml"
     : (
# 29 "Parser.mly"
      (unit)
# 209 "Parser.ml"
    ))

let _menhir_action_07 =
  fun () ->
    (
# 33 "Parser.mly"
                            ( () )
# 217 "Parser.ml"
     : (
# 26 "Parser.mly"
      (unit)
# 221 "Parser.ml"
    ))

let _menhir_action_08 =
  fun () ->
    (
# 38 "Parser.mly"
                         ( () )
# 229 "Parser.ml"
     : (
# 28 "Parser.mly"
      (unit)
# 233 "Parser.ml"
    ))

let _menhir_action_09 =
  fun () ->
    (
# 39 "Parser.mly"
                                  ( () )
# 241 "Parser.ml"
     : (
# 28 "Parser.mly"
      (unit)
# 245 "Parser.ml"
    ))

let _menhir_action_10 =
  fun () ->
    (
# 40 "Parser.mly"
                            ( () )
# 253 "Parser.ml"
     : (
# 28 "Parser.mly"
      (unit)
# 257 "Parser.ml"
    ))

let _menhir_action_11 =
  fun () ->
    (
# 41 "Parser.mly"
                             ( () )
# 265 "Parser.ml"
     : (
# 28 "Parser.mly"
      (unit)
# 269 "Parser.ml"
    ))

let _menhir_action_12 =
  fun () ->
    (
# 42 "Parser.mly"
                           ( () )
# 277 "Parser.ml"
     : (
# 28 "Parser.mly"
      (unit)
# 281 "Parser.ml"
    ))

let _menhir_action_13 =
  fun () ->
    (
# 35 "Parser.mly"
                          ( () )
# 289 "Parser.ml"
     : (
# 27 "Parser.mly"
      (unit)
# 293 "Parser.ml"
    ))

let _menhir_action_14 =
  fun () ->
    (
# 36 "Parser.mly"
                           ( () )
# 301 "Parser.ml"
     : (
# 27 "Parser.mly"
      (unit)
# 305 "Parser.ml"
    ))

let _menhir_print_token : token -> string =
  fun _tok ->
    match _tok with
    | T_begin ->
        "T_begin"
    | T_const ->
        "T_const"
    | T_do ->
        "T_do"
    | T_end ->
        "T_end"
    | T_eof ->
        "T_eof"
    | T_eq ->
        "T_eq"
    | T_for ->
        "T_for"
    | T_if ->
        "T_if"
    | T_let ->
        "T_let"
    | T_lparen ->
        "T_lparen"
    | T_minus ->
        "T_minus"
    | T_plus ->
        "T_plus"
    | T_print ->
        "T_print"
    | T_rparen ->
        "T_rparen"
    | T_then ->
        "T_then"
    | T_times ->
        "T_times"
    | T_var ->
        "T_var"

let _menhir_fail : unit -> 'a =
  fun () ->
    Printf.eprintf "Internal failure -- please contact the parser generator's developers.\n%!";
    assert false

include struct
  
  [@@@ocaml.warning "-4-37"]
  
  let _menhir_run_31 : type  ttv_stack. ttv_stack -> _ -> _menhir_box_program =
    fun _menhir_stack _tok ->
      match (_tok : MenhirBasics.token) with
      | T_eof ->
          let _v = _menhir_action_07 () in
          MenhirBox_program _v
      | _ ->
          _eRR ()
  
  let rec _menhir_run_01 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _menhir_stack = MenhirCell1_T_print (_menhir_stack, _menhir_s) in
      let _menhir_s = MenhirState01 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | T_var ->
          _menhir_run_02 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | T_lparen ->
          _menhir_run_03 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | T_const ->
          _menhir_run_04 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_run_02 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _tok = _menhir_lexer _menhir_lexbuf in
      let _v = _menhir_action_02 () in
      _menhir_goto_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_goto_expr : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match _menhir_s with
      | MenhirState21 ->
          _menhir_run_22 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState18 ->
          _menhir_run_19 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState16 ->
          _menhir_run_17 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState01 ->
          _menhir_run_13 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState11 ->
          _menhir_run_12 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState09 ->
          _menhir_run_10 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState06 ->
          _menhir_run_07 _menhir_stack _menhir_lexbuf _menhir_lexer _tok
      | MenhirState03 ->
          _menhir_run_05 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_22 : type  ttv_stack. ((ttv_stack, _menhir_box_program) _menhir_cell1_T_for as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      let _menhir_stack = MenhirCell1_expr (_menhir_stack, _menhir_s, _v) in
      match (_tok : MenhirBasics.token) with
      | T_times ->
          _menhir_run_06 _menhir_stack _menhir_lexbuf _menhir_lexer
      | T_plus ->
          _menhir_run_09 _menhir_stack _menhir_lexbuf _menhir_lexer
      | T_minus ->
          _menhir_run_11 _menhir_stack _menhir_lexbuf _menhir_lexer
      | T_do ->
          let _menhir_s = MenhirState23 in
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | T_print ->
              _menhir_run_01 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | T_let ->
              _menhir_run_14 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | T_if ->
              _menhir_run_18 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | T_for ->
              _menhir_run_21 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | T_begin ->
              _menhir_run_24 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | _ ->
              _eRR ())
      | _ ->
          _eRR ()
  
  and _menhir_run_06 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_expr -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer ->
      let _menhir_s = MenhirState06 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | T_var ->
          _menhir_run_02 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | T_lparen ->
          _menhir_run_03 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | T_const ->
          _menhir_run_04 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_run_03 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _menhir_stack = MenhirCell1_T_lparen (_menhir_stack, _menhir_s) in
      let _menhir_s = MenhirState03 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | T_var ->
          _menhir_run_02 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | T_lparen ->
          _menhir_run_03 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | T_const ->
          _menhir_run_04 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_run_04 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _tok = _menhir_lexer _menhir_lexbuf in
      let _v = _menhir_action_01 () in
      _menhir_goto_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_09 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_expr -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer ->
      let _menhir_s = MenhirState09 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | T_var ->
          _menhir_run_02 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | T_lparen ->
          _menhir_run_03 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | T_const ->
          _menhir_run_04 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_run_11 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_expr -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer ->
      let _menhir_s = MenhirState11 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | T_var ->
          _menhir_run_02 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | T_lparen ->
          _menhir_run_03 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | T_const ->
          _menhir_run_04 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_run_14 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _menhir_stack = MenhirCell1_T_let (_menhir_stack, _menhir_s) in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | T_var ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | T_eq ->
              let _menhir_s = MenhirState16 in
              let _tok = _menhir_lexer _menhir_lexbuf in
              (match (_tok : MenhirBasics.token) with
              | T_var ->
                  _menhir_run_02 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
              | T_lparen ->
                  _menhir_run_03 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
              | T_const ->
                  _menhir_run_04 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
              | _ ->
                  _eRR ())
          | _ ->
              _eRR ())
      | _ ->
          _eRR ()
  
  and _menhir_run_18 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _menhir_stack = MenhirCell1_T_if (_menhir_stack, _menhir_s) in
      let _menhir_s = MenhirState18 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | T_var ->
          _menhir_run_02 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | T_lparen ->
          _menhir_run_03 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | T_const ->
          _menhir_run_04 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_run_21 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _menhir_stack = MenhirCell1_T_for (_menhir_stack, _menhir_s) in
      let _menhir_s = MenhirState21 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | T_var ->
          _menhir_run_02 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | T_lparen ->
          _menhir_run_03 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | T_const ->
          _menhir_run_04 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_run_24 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _menhir_stack = MenhirCell1_T_begin (_menhir_stack, _menhir_s) in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | T_print ->
          _menhir_run_01 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState24
      | T_let ->
          _menhir_run_14 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState24
      | T_if ->
          _menhir_run_18 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState24
      | T_for ->
          _menhir_run_21 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState24
      | T_begin ->
          _menhir_run_24 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState24
      | T_end ->
          let _ = _menhir_action_13 () in
          _menhir_run_25 _menhir_stack _menhir_lexbuf _menhir_lexer _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_25 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_T_begin -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _tok ->
      match (_tok : MenhirBasics.token) with
      | T_end ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          let MenhirCell1_T_begin (_menhir_stack, _menhir_s) = _menhir_stack in
          let _v = _menhir_action_11 () in
          _menhir_goto_stmt _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_goto_stmt : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match _menhir_s with
      | MenhirState20 ->
          _menhir_run_30 _menhir_stack _menhir_lexbuf _menhir_lexer _tok
      | MenhirState23 ->
          _menhir_run_29 _menhir_stack _menhir_lexbuf _menhir_lexer _tok
      | MenhirState00 ->
          _menhir_run_27 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState27 ->
          _menhir_run_27 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState24 ->
          _menhir_run_27 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_30 : type  ttv_stack. ((ttv_stack, _menhir_box_program) _menhir_cell1_T_if, _menhir_box_program) _menhir_cell1_expr -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _tok ->
      let MenhirCell1_expr (_menhir_stack, _, _) = _menhir_stack in
      let MenhirCell1_T_if (_menhir_stack, _menhir_s) = _menhir_stack in
      let _v = _menhir_action_12 () in
      _menhir_goto_stmt _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_29 : type  ttv_stack. ((ttv_stack, _menhir_box_program) _menhir_cell1_T_for, _menhir_box_program) _menhir_cell1_expr -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _tok ->
      let MenhirCell1_expr (_menhir_stack, _, _) = _menhir_stack in
      let MenhirCell1_T_for (_menhir_stack, _menhir_s) = _menhir_stack in
      let _v = _menhir_action_10 () in
      _menhir_goto_stmt _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_27 : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      let _menhir_stack = MenhirCell1_stmt (_menhir_stack, _menhir_s, _v) in
      match (_tok : MenhirBasics.token) with
      | T_print ->
          _menhir_run_01 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState27
      | T_let ->
          _menhir_run_14 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState27
      | T_if ->
          _menhir_run_18 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState27
      | T_for ->
          _menhir_run_21 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState27
      | T_begin ->
          _menhir_run_24 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState27
      | T_end | T_eof ->
          let _ = _menhir_action_13 () in
          _menhir_run_28 _menhir_stack _menhir_lexbuf _menhir_lexer _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_28 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_stmt -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _tok ->
      let MenhirCell1_stmt (_menhir_stack, _menhir_s, _) = _menhir_stack in
      let _ = _menhir_action_14 () in
      _menhir_goto_stmt_list _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s _tok
  
  and _menhir_goto_stmt_list : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s _tok ->
      match _menhir_s with
      | MenhirState00 ->
          _menhir_run_31 _menhir_stack _tok
      | MenhirState27 ->
          _menhir_run_28 _menhir_stack _menhir_lexbuf _menhir_lexer _tok
      | MenhirState24 ->
          _menhir_run_25 _menhir_stack _menhir_lexbuf _menhir_lexer _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_19 : type  ttv_stack. ((ttv_stack, _menhir_box_program) _menhir_cell1_T_if as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      let _menhir_stack = MenhirCell1_expr (_menhir_stack, _menhir_s, _v) in
      match (_tok : MenhirBasics.token) with
      | T_times ->
          _menhir_run_06 _menhir_stack _menhir_lexbuf _menhir_lexer
      | T_then ->
          let _menhir_s = MenhirState20 in
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | T_print ->
              _menhir_run_01 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | T_let ->
              _menhir_run_14 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | T_if ->
              _menhir_run_18 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | T_for ->
              _menhir_run_21 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | T_begin ->
              _menhir_run_24 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | _ ->
              _eRR ())
      | T_plus ->
          _menhir_run_09 _menhir_stack _menhir_lexbuf _menhir_lexer
      | T_minus ->
          _menhir_run_11 _menhir_stack _menhir_lexbuf _menhir_lexer
      | _ ->
          _eRR ()
  
  and _menhir_run_17 : type  ttv_stack. ((ttv_stack, _menhir_box_program) _menhir_cell1_T_let as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | T_times ->
          let _menhir_stack = MenhirCell1_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_06 _menhir_stack _menhir_lexbuf _menhir_lexer
      | T_plus ->
          let _menhir_stack = MenhirCell1_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_09 _menhir_stack _menhir_lexbuf _menhir_lexer
      | T_minus ->
          let _menhir_stack = MenhirCell1_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_11 _menhir_stack _menhir_lexbuf _menhir_lexer
      | T_begin | T_end | T_eof | T_for | T_if | T_let | T_print ->
          let MenhirCell1_T_let (_menhir_stack, _menhir_s) = _menhir_stack in
          let _v = _menhir_action_09 () in
          _menhir_goto_stmt _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_13 : type  ttv_stack. ((ttv_stack, _menhir_box_program) _menhir_cell1_T_print as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | T_times ->
          let _menhir_stack = MenhirCell1_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_06 _menhir_stack _menhir_lexbuf _menhir_lexer
      | T_plus ->
          let _menhir_stack = MenhirCell1_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_09 _menhir_stack _menhir_lexbuf _menhir_lexer
      | T_minus ->
          let _menhir_stack = MenhirCell1_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_11 _menhir_stack _menhir_lexbuf _menhir_lexer
      | T_begin | T_end | T_eof | T_for | T_if | T_let | T_print ->
          let MenhirCell1_T_print (_menhir_stack, _menhir_s) = _menhir_stack in
          let _v = _menhir_action_08 () in
          _menhir_goto_stmt _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_12 : type  ttv_stack. ((ttv_stack, _menhir_box_program) _menhir_cell1_expr as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | T_times ->
          let _menhir_stack = MenhirCell1_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_06 _menhir_stack _menhir_lexbuf _menhir_lexer
      | T_begin | T_do | T_end | T_eof | T_for | T_if | T_let | T_minus | T_plus | T_print | T_rparen | T_then ->
          let MenhirCell1_expr (_menhir_stack, _menhir_s, _) = _menhir_stack in
          let _v = _menhir_action_05 () in
          _menhir_goto_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_10 : type  ttv_stack. ((ttv_stack, _menhir_box_program) _menhir_cell1_expr as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | T_times ->
          let _menhir_stack = MenhirCell1_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_06 _menhir_stack _menhir_lexbuf _menhir_lexer
      | T_begin | T_do | T_end | T_eof | T_for | T_if | T_let | T_minus | T_plus | T_print | T_rparen | T_then ->
          let MenhirCell1_expr (_menhir_stack, _menhir_s, _) = _menhir_stack in
          let _v = _menhir_action_04 () in
          _menhir_goto_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_07 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_expr -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _tok ->
      let MenhirCell1_expr (_menhir_stack, _menhir_s, _) = _menhir_stack in
      let _v = _menhir_action_06 () in
      _menhir_goto_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_05 : type  ttv_stack. ((ttv_stack, _menhir_box_program) _menhir_cell1_T_lparen as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | T_times ->
          let _menhir_stack = MenhirCell1_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_06 _menhir_stack _menhir_lexbuf _menhir_lexer
      | T_rparen ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          let MenhirCell1_T_lparen (_menhir_stack, _menhir_s) = _menhir_stack in
          let _v = _menhir_action_03 () in
          _menhir_goto_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | T_plus ->
          let _menhir_stack = MenhirCell1_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_09 _menhir_stack _menhir_lexbuf _menhir_lexer
      | T_minus ->
          let _menhir_stack = MenhirCell1_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_11 _menhir_stack _menhir_lexbuf _menhir_lexer
      | _ ->
          _eRR ()
  
  let _menhir_run_00 : type  ttv_stack. ttv_stack -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer ->
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | T_print ->
          _menhir_run_01 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState00
      | T_let ->
          _menhir_run_14 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState00
      | T_if ->
          _menhir_run_18 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState00
      | T_for ->
          _menhir_run_21 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState00
      | T_begin ->
          _menhir_run_24 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState00
      | T_eof ->
          let _ = _menhir_action_13 () in
          _menhir_run_31 _menhir_stack _tok
      | _ ->
          _eRR ()
  
end

let program =
  fun _menhir_lexer _menhir_lexbuf ->
    let _menhir_stack = () in
    let MenhirBox_program v = _menhir_run_00 _menhir_stack _menhir_lexbuf _menhir_lexer in
    v
