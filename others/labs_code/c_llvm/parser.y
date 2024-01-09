%{
#include <cstdio>
#include <cstdlib>
#include "ast.hpp"
#include "lexer.hpp"

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

%token<var> T_id
%token<num> T_const

%left<op> '+' '-'
%left<op> '*' '/' '%'

%expect 1

%union {
  Stmt *stmt;
  Expr *expr;
  Block *blk;
  char var;
  int num;
  char op;
}

%type<expr> expr
%type<stmt> stmt
%type<blk>  stmt_list

%%

program : stmt_list	 { $1->llvm_compile_and_dump(); }
;

stmt_list : /* nothing */ 	{ $$ = new Block(); }
| stmt_list stmt		{ $1->append($2); $$ = $1; }
;

stmt :
  "begin" stmt_list "end"	     { $$ = $2; }
| "for" expr "do" stmt		     { $$ = new For($2, $4); }
| "if" expr "then" stmt		     { $$ = new If($2, $4); }
| "if" expr "then" stmt "else" stmt  { $$ = new If($2, $4, $6); }
| "let" T_id '=' expr		     { $$ = new Let($2, $4); }
| "print" expr	                     { $$ = new Print($2); }
;

expr :
   T_id		                     { $$ = new Id($1); }
|  T_const	                     { $$ = new Const($1); } 
|  '(' expr ')'			     { $$ = $2; }
|  expr '+' expr		     { $$ = new BinOp($1, $2, $3); }
|  expr '-' expr		     { $$ = new BinOp($1, $2, $3); }
|  expr '*' expr		     { $$ = new BinOp($1, $2, $3); }
|  expr '/' expr		     { $$ = new BinOp($1, $2, $3); }
|  expr '%' expr		     { $$ = new BinOp($1, $2, $3); }
;

%%


void yyerror(const char *msg) {
  printf("Syntax error: %s\n", msg);
  exit(42);
}

int main() {
  int res = yyparse();
  // if (res == 0) printf("Successful parsing\n");
  return res;
}
