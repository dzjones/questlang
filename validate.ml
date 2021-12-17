open Lexing
open Abstract_syntax_tree
open Parser
open Lexer
open Utils
open Semantics

(* Here we take the list of ParserWorldEntry components that we get from parsing
   and we merge them together as is appropriate.
   For instance, if we parsed multiple World Definition blocks we just concatenate
   all of them and treat it as one singular block describing the whole world *)

let findWorld = List.fold_left
  (fun w x -> match x with
    | Abstract_syntax_tree.ParserWorldEntry w' -> w @ w'
    | _ -> w
  ) []

let findMainQuests = List.fold_left
  (fun qs x -> match x with
    | Abstract_syntax_tree.ParserQuestExp q -> q :: qs
    | _ -> qs
  ) []

let findSubquests = List.fold_left
  (fun qs x -> match x with
    | Abstract_syntax_tree.ParserSubquestExp q -> q :: qs
    | _ -> qs
  ) []

(* The parser uses cons left -> right, so we need to reverse the list of quests
    to ensure the output reflects the order the user defined the quests. *)
let buildFullAST parserResult =
  let completeWorld = findWorld parserResult in
  let subquests = findSubquests parserResult in
  let mainQuests = findMainQuests parserResult in {
    Abstract_syntax_tree.world = completeWorld;
    Abstract_syntax_tree.subquests = subquests;
    Abstract_syntax_tree.mainQuests = List.rev (mainQuests);
  };;

(* This function takes a path to a questlang file, and just successively lexes it,
   parses it, builds the AST and evaluates it*)

let validateQuestFile (qfile: string) =
  let channel = open_in qfile in
  let lexbuf = Lexing.from_channel channel in
  let parserRawData = Parser.main Lexer.token lexbuf in
  let ast = buildFullAST parserRawData in
  evalAST ast;;