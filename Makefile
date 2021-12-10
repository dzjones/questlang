CORE_MODULES = abstract_syntax_tree utils semantics

$(CORE_MODULES:=.cmx) : $(CORE_MODULES:=.ml)
	ocamlopt -c $^

%.q : %.ml $(CORE_MODULES:=.cmx)
	ocamlopt -c $<
	ocamlopt -o $@ $(CORE_MODULES:=.cmx) $*.cmx

%.out : %.q
	./$< > $@

test: tester.out.golden tester.out
	diff $^

clean:
	rm -rf *.o *.cmi *.cmx *.q *.out

.PHONY: clean test