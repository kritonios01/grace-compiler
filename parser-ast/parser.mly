%token T_and       "AND"
%token T_assign    "<-"
%token T_char
%token T_colon     ":"
%token T_comma     ","
%token T_constc
%token T_consti 
%token T_consts
%token T_div       "DIV"
%token T_do 
%token T_else 
%token T_eof
%token T_eq        "="
%token T_fun 
%token T_greater   ">"
%token T_greatereq ">="
%token T_hash      "#"
%token T_id 
%token T_if 
%token T_int 
%token T_less      "<"
%token T_lesseq    "<="
%token T_lbracket  "["
%token T_lcbracket "{"
%token T_lparen    "("
%token T_minus     "-"
%token T_mod       "MOD"
%token T_mul       "*"
%token T_not       "NOT"
%token T_nothing 
%token T_or        "OR"
%token T_plus      "+"
%token T_rbracket  "]"
%token T_rcbracket "}"
%token T_ref 
%token T_return 
%token T_rparen    ")"
%token T_semicolon ";"
%token T_then 
%token T_var 
%token T_while 


%left "OR"
%left "AND"
%nonassoc "NOT"
//%nonassoc "=" "#" ">" "<" "<=" ">="
%left "+" "-"
%left "*" "DIV" "MOD"

%nonassoc T_then
%nonassoc T_else



%start <unit> program

// %type <unit> func_def
// %type <unit> header

%%

let program        := func_def ; T_eof ;                              { () }

let func_def       := header ; local_def* ; block ;                   { () }

let header         := T_fun ; T_id ; "(" ; fpar_defs? ; ")" ; ":" ; ret_type ;  { () }

let fpar_defs      := fpar_def ; more_fpar_defs* ;                    { () }    //

let more_fpar_defs := ";" ; fpar_def ;                                { () }    //

let fpar_def       := T_ref? ; T_id ; more_ids* ; ":" ; fpar_type ;   { () }
            
let more_ids       := "," ; T_id ;                                    { () }    //

let data_type      := T_int ;                                         { () }
                    | T_char ;                                        { () }

let type_          := data_type ; brackets_i* ;                       { () }

let brackets_i     := "[" ; T_consti ; "]" ;                          { () }

let ret_type       := data_type ;                                     { () }
                    | T_nothing ;                                     { () }

let fpar_type      := data_type ; "[" ; "]" ; brackets_i* ;           { () }
                    | data_type ;  brackets_i* ;                      { () }

let local_def      := func_def ;                                      { () }
                    | func_decl ;                                     { () }
                    | var_def ;                                       { () }

let func_decl      := header ; ";" ;                                  { () }

let var_def        := T_var ; T_id ; more_ids* ; ":" ; type_ ; ";" ;  { () }

let stmt           := ";" ;                                           { () }
                    | l_value ; "<-" ; expr ; ";" ;                   { () }
                    | block ;                                         { () }
                    | func_call ; ";" ;                               { () }
                    | T_if ; cond ; T_then ; stmt ;                   { () }
                    | T_if ; cond ; T_then ; stmt ; T_else ; stmt ;   { () }
                    | T_while ; cond ; T_do ; stmt ;                  { () }
                    | T_return ; expr? ; ";" ;                        { () }

let block          := "{" ; stmt* ; "}" ;                             { () }

let func_call      := T_id ; "(" ; exprs? ; ")" ;                     { () }

let exprs          := expr ; more_exprs* ;                            { () }   //

let more_exprs     := "," ; expr ;                                    { () }    //

let l_value        := T_id ;                                          { () }
                    | T_consts ;                                      { () }
                    | l_value ; "[" ; expr ; "]" ;                    { () }

let expr           := T_consti ;               { () }
                    | T_constc ;               { () }
                    | l_value ;                { () }
                    | "(" ; expr ; ")" ;       { () }
                    | func_call ;              { () }
                    | "+" ; expr ;             { () }    //mipos ginei me inline?
                    | "-" ; expr ;             { () }
                    | expr ; "+" ; expr ;      { () }
                    | expr ; "-" ; expr ;      { () }
                    | expr ; "*" ; expr ;      { () }
                    | expr ; "DIV" ; expr ;    { () }
                    | expr ; "MOD" ; expr ;    { () } 
        
let cond           := "(" ; cond ; ")" ;       { () }
                    | "NOT" ; cond ;           { () }
                    | cond ; "AND" ; cond ;    { () }
                    | cond ; "OR" ; cond ;     { () }
                    | expr ; "=" ; expr ;      { () }
                    | expr ; "#" ; expr ;      { () }
                    | expr ; "<" ; expr ;      { () }
                    | expr ; ">" ; expr ;      { () }
                    | expr ; "<=" ; expr ;     { () }
                    | expr ; ">=" ; expr ;     { () }
