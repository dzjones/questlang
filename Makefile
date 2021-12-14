LIB_RAW = utils.ml abstract_syntax_tree.ml lexer.mll parser.mly semantics.ml validate.ml
LIB = utils.ml abstract_syntax_tree.ml parser.mli lexer.ml parser.ml semantics.ml validate.ml
TEST_FILES = quest-example quest-example-2 quest-example-3 quest-example-4

questlang: $(LIB_RAW)
	ocamlyacc parser.mly
	ocamllex lexer.mll
	ocamlopt -o questlang $(LIB) main.ml

test-semantics : semantics_tester.ml questlang $(LIB)
	ocamlopt -o $<.o $(LIB) $<
	./$<.o; rm -f $<.o

%.out : questlang %.ql
	./$^ > $@

%.out.test : %.out %.out.golden
	diff $^

test-integration : $(TEST_FILES:=.out.test)

test: test-semantics test-integration

clean:
	rm -rf *.o *.cmi *.cmx *.out questlang lexer.ml parser.ml parser.mli

.PHONY: clean test test-semantics test-integration