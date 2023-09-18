# parser target is provided first so that make knows it is the final target
parser: ast.cmo parser.cmo lexer.cmo main.cmo
	ocamlc -o parser ast.cmo parser.cmo lexer.cmo main.cmo

# These rules are provided in the order they should be compiled (if they were to be compiled by hand)
lexer.ml: lexer.mll
	ocamllex lexer.mll

ast.cmo ast.cmi: ast.ml ast.mli
	ocamlc -c ast.mli ast.ml

parser.ml parser.mli: parser.mly ast.cmi
	menhir --infer parser.mly

parser.cmo parser.cmi: parser.ml parser.mli ast.cmi
	ocamlc -c parser.mli parser.ml

lexer.cmo lexer.cmi: lexer.ml parser.ml
	ocamlc -c lexer.mli lexer.ml

main.cmo: main.ml
	ocamlc -c main.ml


.PHONY: clean distclean

#removes all byproducts of the rules above
clean:
	-rm *.cmi *cmo lexer.ml parser.mli parser.ml
#removes all files produced by the rules above
distclean: clean
	rm parser
