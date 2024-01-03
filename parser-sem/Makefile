# Instructions:
# 1) Select the ocaml compiler as you like by commenting the appropriate lines
#    (see below for semantic and semantic_opt)
# 2) In bash type `make depend` and then `make` 


OCAMLC=ocamlc
OCAMLOPT=ocamlopt
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
	$(OCAMLOPT) $(FLAGS) -c $<


# semantic is the final target compiled with ocamlc and semantic_opt is the final target compiled natively
# uncomment the variant you want and comment the other
#semantic_opt: ast.cmx parser.cmx lexer.cmx symbol.cmx semantic.cmx main.cmx
#	$(OCAMLOPT) $(FLAGS) -o $@ $^
semantic: ast.cmo parser.cmo lexer.cmo symbol.cmo semantic.cmo main.cmo
	$(OCAMLC) $(FLAGS) -o $@ $^


# Rules to produce .ml files from ocamllex and menhir
lexer.ml: lexer.mll
	ocamllex lexer.mll
parser.ml parser.mli: parser.mly ast.cmi
	menhir --infer parser.mly



.PHONY: clean distclean

#removes all byproducts of the rules above
clean:
	-rm *.cmi *.cmo *.cmx *.o lexer.ml parser.mli parser.ml

#removes all files produced by the rules above
distclean: clean
	rm semantic semantic_opt .depend

depend: lexer.ml parser.ml parser.mli
	$(OCAMLDEP) $(INCLUDES) *.mli *.ml > .depend

-include .depend
