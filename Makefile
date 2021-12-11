
questlang:
	ocamlyacc parser.mly
	ocamllex lexer.mll
	ocamlopt -o questlang abstract_syntax_tree.ml parser.mli lexer.ml parser.ml utils.ml semantics.ml validate.ml

%.out : %.q
	./$< > $@

test: tester.out.golden tester.out
	diff $^

clean:
	rm -rf *.o *.cmi *.cmx *.q *.out questlang

.PHONY: clean test