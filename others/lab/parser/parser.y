%{
#include <stdio.h>
#include <stdlib.h>
#include "lexer.h"
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

%token T_id
%token T_const

%left '+' '-'
%left '*' '/' '%'

%expect 1

%%

program : stmt_list
;

stmt_list : /* nothing */
| stmt_list stmt
;

stmt :
  "begin" stmt_list "end"
| "for" expr "do" stmt
| "if" expr "then" stmt
| "if" expr "then" stmt "else" stmt
| "let" T_id '=' expr
| "print" expr
;

expr :
   T_id
|  T_const
|  '(' expr ')'
|  expr '+' expr
|  expr '-' expr
|  expr '*' expr
|  expr '/' expr
|  expr '%' expr
;

%%


void yyerror(const char *msg) {
  printf("Syntax error: %s\n", msg);
  exit(42);
}

int main() {
  int res = yyparse();
  if (res == 0) printf("Successful parsing\n");
  return res;
}
