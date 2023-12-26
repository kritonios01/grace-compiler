OCAMLC=ocamlc             #ocamlc or ocamlopt
OCAMLDEP=ocamldep
FLAGS=#                    #-g for debugging


# Rules for OCaml files
%.cmo: %.ml %.mli
	$(OCAMLC) $(FLAG	S) -c $<

%.cmi: %.mli
	$(OCAMLC) $(FLAGS) -c $<

%.cmo %.cmi: %.ml
	$(OCAMLC) $(OCAMLC_FLAGS) -c $<

%.cmx: %.ml
	$(OCAMLC) $(FLAGS) -c $<


# Rules to produce .ml files from ocamllex and menhir. parser is the final target
parser: ast.cmo parser.cmo lexer.cmo main.cmo
	$(OCAMLC) $(FLAGS) -o $@ $^

lexer.ml: lexer.mll
	ocamllex lexer.mll

parser.ml parser.mli: parser.mly ast.cmi
	menhir --infer parser.mly



.PHONY: clean distclean

#removes all byproducts of the rules above
clean:
	-rm *.cmi *cmo lexer.ml parser.mli parser.ml
#removes all files produced by the rules above
distclean: clean
	rm parser .depend

depend: lexer.ml parser.ml parser.mli
	$(OCAMLDEP) $(INCLUDES) *.mli *.ml > .depend

-include .depend