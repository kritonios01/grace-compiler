%token T_and
%token T_assign
%token T_char
%token T_colon 
%token T_comma 
%token T_constc 
%token T_consti 
%token T_consts
%token T_div 
%token T_do 
%token T_else 
%token T_eof
%token T_eq 
%token T_fun 
%token T_greater 
%token T_greatereq 
%token T_hash 
%token T_id 
%token T_if 
%token T_int 
%token T_less 
%token T_lesseq 
%token T_lbracket (* [ *)
%token T_lcbracket (* curly bracket: { *)
%token T_lparen 
%token T_minus 
%token T_mod 
%token T_mul 
%token T_not 
%token T_nothing 
%token T_or 
%token T_plus 
%token T_rbracket 
%token T_rcbracket 
%token T_ref 
%token T_return 
%token T_rparen 
%token T_semicolon 
%token T_then 
%token T_var 
%token T_while 

%start program

%type <unit> program
// %type <unit> func_def
// %type <unit> header

%%

program        : func_def T_eof  { () }

func_def       : header local_def_List block  { () }

local_def_List : /* nothing */             { () } (* side-effect of converting ebnf->bnf *)
               | local_def_List local_def  { () }

header         : T_fun T_id T_lparen func_args T_rparen T_colon ret_type  { () }

func_args      : /* nothing */            { () } (* side-effect of converting ebnf->bnf *)
               | fpar_def more_args_List  { () }

more_args_List : /* nothing */                        { () } (* side-effect of converting ebnf->bnf *)
               | more_args_List T_semicolon fpar_def  { () }

fpar_def       : ref_opt T_id more_ids_List T_colon fpar_type  { () }

ref_opt        : /* nothing */  { () } (* side-effect of converting ebnf->bnf *)
               | T_ref          { () }
            
more_ids_List  : /* nothing */               { () } (* side-effect of converting ebnf->bnf *)
               | more_ids_List T_comma T_id  { () }

data_type      : T_int   { () }
               | T_char  { () }

type_           : data_type brackets_List  { () }

brackets_List  : /* nothing */                                 { () } (* side-effect of converting ebnf->bnf *)
               | brackets_List T_lbracket T_consti T_rbracket  { () }

ret_type       : data_type  { () }
               | T_nothing  { () }

fpar_type      : data_type brackets_opt brackets_List  { () }

brackets_opt   : /* nothing */          { () } (* side-effect of converting ebnf->bnf *)
               | T_lbracket T_rbracket  { () }

local_def      : func_def   { () }
               | func_decl  { () }
               | var_def    { () }

func_decl      : header T_semicolon  { () }

var_def        : T_var T_id more_ids_List T_colon type_ T_semicolon  { () }

stmt           : T_semicolon                        { () }
               | l_value T_assign expr T_semicolon  { () }
               | block                              { () }
               | func_call T_semicolon              { () }
               | T_if cond T_then stmt else_opt     { () }
               | T_while cond T_do stmt             { () }
               | T_return expr_opt T_semicolon      { () }

else_opt       : /* nothing */ (* side-effect of converting ebnf->bnf *)
               | T_else stmt  { () }

expr_opt       : /* nothing */ (* side-effect of converting ebnf->bnf *)
               | expr  { () }

block          : T_lcbracket stmt_List T_rcbracket  { () }

stmt_List      : /* nothing */ (* side-effect of converting ebnf->bnf *)
               | stmt_List stmt  { () }

func_call      : T_id T_lparen exprs_opt T_rparen  { () }

exprs_opt      : /* nothing */ (* side-effect of converting ebnf->bnf *)
               | expr more_exprs_List  { () }

more_exprs_List: /* nothing */ (* side-effect of converting ebnf->bnf *)
               | more_exprs_List T_comma expr  { () }

l_value        : T_id                                { () }
               | T_consts                            { () }
               | l_value T_lbracket expr T_rbracket  { () }

expr           : T_consti                { () }
               | T_constc                { () }
               | l_value                 { () }
               | T_lparen expr T_rparen  { () }
               | func_call               { () }
               | T_plus expr             { () }
               | T_minus expr            { () }
               | expr T_plus expr        { () }
               | expr T_minus expr       { () }
               | expr T_mul expr         { () }
               | expr T_div expr         { () }
               | expr T_mod expr         { () } 
        
cond           : T_lparen cond T_rparen  { () }
               | T_not cond              { () }
               | cond T_and cond         { () }
               | cond T_or cond          { () }
               | expr T_eq expr          { () }
               | expr T_hash expr        { () }
               | expr T_less expr        { () }
               | expr T_greater expr     { () }
               | expr T_lesseq expr      { () }
               | expr T_greatereq expr   { () }
              