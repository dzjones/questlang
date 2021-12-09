.PHONY: clean

CORE_MODULES = abstract_syntax_tree utils semantics

$(CORE_MODULES:=.cmx) : $(CORE_MODULES:=.ml)
	ocamlopt -c $^

%.q : %.ml $(CORE_MODULES:=.cmx)
	ocamlopt -c $<
	ocamlopt -o $@ $(CORE_MODULES:=.cmx) $*.cmx

clean:
	rm -rf *.o *.cmi *.cmx *.q