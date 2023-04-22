lexer: lexer.ml
	ocamlc -o lexer lexer.ml

lexer.ml: lexer.mll
	ocamllex lexer.mll
