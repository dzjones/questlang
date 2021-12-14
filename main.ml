open Lexing
open Abstract_syntax_tree
open Parser
open Lexer
open Utils
open Semantics
open Validate

(* This is the main entry point of our program.
   All it does is parse the command line arguments and pass them
   to the relevant functions in our library *)

let usage_msg = "questlang <file.ql>";;
let input_file = ref "";;
let anon_fn filename =
  input_file := filename

let () =
  Arg.parse [] anon_fn usage_msg;;

  print_string "Validating...\n";;
  print_string (validateQuestFile !input_file)