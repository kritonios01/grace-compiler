%{
#include <cstdio>
#include <cstdlib>
#include "ast.hpp"
#include "lexer.hpp"

SymbolTable st;

std::map<char, int> globals;
%}

%token T_begin "begin"
%token T_do    "do"
%token T_else  "else"
%token T_end   "end"
%token T_for   "for"
%token T_if    "if"
%token T_let   "let"
%token T_print "print"
%token T_then  "then"
%token T_var   "var"
%token T_int   "int"
%token T_bool  "bool"
%token T_true  "true"
%token T_false "false"

%token<var> T_id
%token<num> T_const

%nonassoc<op> '=' '<' '>'
%left<op> '+' '-'
%left<op> '*' '/' '%'

%expect 1

%union {
  Stmt *stmt;
  Expr *expr;
  Block *blk;
  Decl *decl;
  Type type;
  char var;
  int num;
  char op;
}

%type<expr> expr
%type<decl> decl
%type<stmt> stmt
%type<type> type
%type<blk>  block decl_list stmt_list

%%

program : block   {
	auto prg = $1;
	// std::cout << "AST: " << *prg << std::endl;
	$1->sem();
	// $1->execute(); 
	delete prg;
    }
;

block : decl_list stmt_list     { $1->merge($2); $$ = $1; }
;

decl_list : /* nothing */       { $$ = new Block(); }
| decl_list decl                { $1->append_decl($2); $$ = $1; }
;

decl : "var" T_id ':' type      { $$ = new Decl($2, $4); }
;

type : "int"                    { $$ = TYPE_int; }
|      "bool"                   { $$ = TYPE_bool; }
;

stmt_list : /* nothing */ 	{ $$ = new Block(); }
| stmt_list stmt		{ $1->append_stmt($2); $$ = $1; }
;

stmt :
  "begin" block "end"	             { $$ = $2; }
| "for" expr "do" stmt		     { $$ = new For($2, $4); }
| "if" expr "then" stmt		     { $$ = new If($2, $4); }
| "if" expr "then" stmt "else" stmt  { $$ = new If($2, $4, $6); }
| "let" T_id '=' expr		     { $$ = new Let($2, $4); }
| "print" expr	                     { $$ = new Print($2); }
;

expr :
   T_id		                     { $$ = new Id($1); }
|  T_const	                     { $$ = new IntConst($1); } 
|  '(' expr ')'			     { $$ = $2; }
|  expr '+' expr		     { $$ = new BinOp($1, $2, $3); }
|  expr '-' expr		     { $$ = new BinOp($1, $2, $3); }
|  expr '*' expr		     { $$ = new BinOp($1, $2, $3); }
|  expr '/' expr		     { $$ = new BinOp($1, $2, $3); }
|  expr '%' expr		     { $$ = new BinOp($1, $2, $3); }
|  expr '<' expr		     { $$ = new BinOp($1, $2, $3); }
|  expr '=' expr		     { $$ = new BinOp($1, $2, $3); }
|  expr '>' expr		     { $$ = new BinOp($1, $2, $3); }
| "true"                             { $$ = new BoolConst(true); }
| "false"                            { $$ = new BoolConst(false); }
;

%%


void yyerror(const char *msg) {
  printf("Error: %s\n", msg);
  exit(42);
}

int main() {
  int res = yyparse();
  if (res == 0) printf("Successful semantic analysis\n");
  return res;
}
