%{
  open Ast
%}

%token T_and          "AND"
%token T_assign       "<-"
%token T_char
%token T_colon        ":"
%token T_comma        ","
%token<char> T_constc
%token<int> T_consti
%token<string> T_consts
%token T_div          "DIV"
%token T_do 
%token T_else 
%token T_eof
%token T_eq           "="
%token T_fun 
%token T_greater      ">"
%token T_greatereq    ">="
%token T_hash         "#"
%token<string> T_id 
%token T_if 
%token T_int 
%token T_less         "<"
%token T_lesseq       "<="
%token T_lbracket     "["
%token T_lcbracket    "{"
%token T_lparen       "("
%token T_minus        "-"
%token T_mod          "MOD"
%token T_mul          "*"
%token T_not          "NOT"
%token T_nothing 
%token T_or           "OR"
%token T_plus         "+"
%token T_rbracket     "]"
%token T_rcbracket    "}"
%token T_ref 
%token T_return 
%token T_rparen       ")"
%token T_semicolon    ";"
%token T_then 
%token T_var 
%token T_while 


%left "OR"
%left "AND"
%nonassoc "NOT"
//%nonassoc "=" "#" ">" "<" "<=" ">="
%left "+" "-"
%left "*" "DIV" "MOD"
%nonassoc T_then //this is just to fix s/r conflict. No actual meaning
%nonassoc T_else //this is just to fix s/r conflict. No actual meaning



%start <ast_decl> program

%%

let program        := ~ = func_def; T_eof;                            <>

let func_def       := ~ = header; ~ = local_def*; ~ = block;          < F_def >   //returns a tuple of these arguments

(* functions and variables *)
let header         := T_fun; ~ = T_id; "("; ~ = fpar_defs?; ")"; ":"; ~ = ret_type;        < F_head >   //function declaration
let fpar_def       := ref = T_ref?; id1 = T_id; ids = more_ids*; ":"; typ = fpar_type;     { F_params (ref, id1::ids, typ)}    //function params
let fpar_defs      := par1 = fpar_def; pars = more_fpar_defs*;                             { par1::pars }    //helper
let more_fpar_defs := ";"; ~ = fpar_def;                                                   { fpar_def }    //helper

let local_def      := func_def                                                               //any of these can are simply replaced according to their corresponding rule, without the need of a semantic action
                    | func_decl                                     
                    | var_def                                       

let func_decl      := ~ = header; ";";                                                     < F_decl >

let var_def        := T_var; id1 = T_id; ids = more_ids*; ":"; ~ = type_; ";";             { V_def (id1::ids, type_) }

let more_ids       := ","; id = T_id;                                                      { id }    //helper
(*        *)

(* All possible data types in grace *)
let ret_type       := ~ = data_type;                                 <>   //function return type
                    | T_nothing;                                     { TY_none }

let fpar_type      := t = data_type; "["; "]"; dims = brackets*;     { TY_array (t, 0::dims) }    //function params type
                    | t = data_type; dims = brackets*;               < TY_array >

let type_          := t = data_type; dims = brackets*;               < TY_array >    //variable type

let data_type      := T_int;                                         { TY_int }    //helper
                    | T_char;                                        { TY_char }

let brackets       := "["; c = T_consti; "]";                        { c }    //helper
(*         *)




let stmt           := ";";                                                  < S_colon >    //na to doume ligo ayto edw
                    | ~ = l_value; "<-"; ~ = expr; ";";                     < S_assign >
                    | block
                    | ~ = func_call; ";";                                   <>
                    | T_if; e = cond; T_then; s = stmt;                     < S_if >
                    | T_if; e = cond; T_then; s1 = stmt; T_else; s2 = stmt; < S_ifelse >
                    | T_while; e = cond; T_do; s = stmt;                    < S_while >
                    | T_return; e = expr?; ";";                             < S_return >

let l_value        := ~ = T_id;                                             < L_id >
                    | ~ = T_consts;                                         < L_string_lit >
                    | ~ = l_value; "["; ~ = expr; "]";                      < L_matrix > 

let block          := "{"; ~ = stmt*; "}";                                  < S_block >

let func_call      := ~ = T_id; "("; ~ = exprs?; ")";                       < S_fcall >
// let func_call      := ~ = T_id; "("; ~ = exprs?; ")";                       <>
let exprs          := e = expr; es = more_exprs*;                           { e::es }    //helper
let more_exprs     := ","; e = expr;                                        { e }    //helper

let expr           := ~ = T_consti;                   < E_int_const >
                    | ~ = T_constc;                   < E_char_const >
                    | l_value
                    | "("; ~ = expr; ")";             <>
                    | ~ = func_call;                  < E_fcall >
                    | "+"; e = expr;                  { E_op1 (Op_plus, e) }    //mipos ginei me inline?
                    | "-"; e = expr;                  { E_op1 (Op_minus, e) }
                    | e1 = expr; "+"; e2 = expr;      { E_op2 (e1, Op_plus, e2) }
                    | e1 = expr; "-"; e2 = expr;      { E_op2 (e1, Op_minus, e2) }
                    | e1 = expr; "*"; e2 = expr;      { E_op2 (e1, Op_times, e2) }
                    | e1 = expr; "DIV"; e2 = expr;    { E_op2 (e1, Op_div, e2) }
                    | e1 = expr; "MOD"; e2 = expr;    { E_op2 (e1, Op_mod, e2) } 
        
let cond           := "("; ~ = cond; ")";             <>
                    | "NOT"; e = cond;                { C_bool1 (Op_not, e) }
                    | e1 = cond; "AND"; e2 = cond;    { C_bool2 (e1, Op_and, e2) }
                    | e1 = cond; "OR"; e2 = cond;     { C_bool2 (e1, Op_or, e2) }
                    | e1 = expr; "="; e2 = expr;      { C_expr (e1, Op_eq, e2) }
                    | e1 = expr; "#"; e2 = expr;      { C_expr (e1, Op_hash, e2) }
                    | e1 = expr; "<"; e2 = expr;      { C_expr (e1, Op_less, e2) }
                    | e1 = expr; ">"; e2 = expr;      { C_expr (e1, Op_greater, e2) }
                    | e1 = expr; "<="; e2 = expr;     { C_expr (e1, Op_lesseq, e2) }
                    | e1 = expr; ">="; e2 = expr;     { C_expr (e1, Op_greatereq, e2) }