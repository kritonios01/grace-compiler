exception LexingError of string

val num_lines : int ref

val lexer : Lexing.lexbuf -> Parser.token