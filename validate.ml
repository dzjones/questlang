open Lexing
open Abstract_syntax_tree
open Parser
open Lexer
open Utils
open Semantics

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

let buildFullAST parserResult =
  let completeWorld = findWorld parserResult in
  let subquests = findSubquests parserResult in
  let mainQuests = findMainQuests parserResult in {
    Abstract_syntax_tree.world = completeWorld;
    Abstract_syntax_tree.subquests = subquests;
    Abstract_syntax_tree.mainQuests = mainQuests;
  };;

let validateQuestFile (qfile: string) =
  let channel = open_in qfile in
  let lexbuf = Lexing.from_channel channel in
  let ast = buildFullAST (Parser.main Lexer.token lexbuf) in
  evalAST ast;;