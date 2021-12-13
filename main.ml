open Lexing
open Abstract_syntax_tree
open Parser
open Lexer
open Utils
open Semantics
open Validate

let usage_msg = "questlang <file.ql>";;
let input_file = ref "";;
let anon_fn filename =
  input_file := filename

let () =
  Arg.parse [] anon_fn usage_msg;;

  print_string "Validating...\n";;
  print_string (validateQuestFile !input_file)