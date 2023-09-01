lexer: lexer.ml
	ocamlc -o lexer lexer.ml

lexer.ml: lexer.mll
	ocamllex lexer.mll

.PHONY: clean distclean

#removes all byproducts of the rules above
clean:
	-rm *.cmi *cmo *.ml
#removes all files produced by the rules above
distclean: clean
	rm lexer

