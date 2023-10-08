%{
#include "ast.hpp"
#include "lexer.hpp"
#include "parser.hpp"

#define T_eof   0

int lineno = 1;
%}

L [a-z]
D [0-9]
W [ \t\r]

%option noyywrap

%%

"begin"	{ return T_begin; }
"do"	{ return T_do; }
"else"	{ return T_else; }
"end"	{ return T_end; }
"for"	{ return T_for; }
"if"	{ return T_if; }
"let"	{ return T_let; }
"print"	{ return T_print; }
"then"	{ return T_then; }
"var"	{ return T_var; }
"int"	{ return T_int; }
"bool"	{ return T_bool; }
"true"	{ return T_true; }
"false"	{ return T_false; }

[\=\+\-\*\/\%\(\)\:\<\>] { yylval.op = yytext[0]; return yytext[0]; }

{L}	{ yylval.var = yytext[0]; return T_id; }
{D}+	{ yylval.num = atoi(yytext); return T_const; }

\n	{ ++lineno; }
{W}+	{ /* return nothing */ }
'.*\n	{ ++lineno; }

.	{ fprintf(stderr, "Illegal character %c at line %d\n", yytext[0], lineno); exit(42); }

%%

