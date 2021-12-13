open Lexing
open Abstract_syntax_tree
open Parser
open Lexer
open Utils
open Semantics

let findWorld = List.find_opt (fun x -> match x with Abstract_syntax_tree.ParserWorldEntry _ -> true | _ -> false)
let findMainQuest = List.find_opt (fun x -> match x with Abstract_syntax_tree.ParserQuestExp _ -> true | _ -> false)

let rec findSubquests parserResult accumulator =
  match parserResult with
  | [] -> accumulator
  | x::xs -> (
    match x with
      | Abstract_syntax_tree.ParserSubquestExp y -> findSubquests xs (y::accumulator)
      | _ -> findSubquests xs accumulator
  )

let buildFullAST parserResult =
  let firstWorld = findWorld parserResult
  and subquests = findSubquests parserResult []
  and mainQuest = findMainQuest parserResult in
  match firstWorld, mainQuest with
  | (None, _) -> None | (_, None) -> None
  | (Some Abstract_syntax_tree.ParserWorldEntry fw, Some Abstract_syntax_tree.ParserQuestExp mq) -> (
    Some {
      Abstract_syntax_tree.world = fw;
      Abstract_syntax_tree.subquests = subquests;
      Abstract_syntax_tree.mainQuest = mq;
    }
  );;

let validateQuestFile (qfile: string) =
  let channel = open_in qfile in
  let lexbuf = Lexing.from_channel channel in
  let ast = buildFullAST (Parser.main Lexer.token lexbuf) in (
    match ast with
    | Some actualAST -> evalAST actualAST
    | None -> "Parsing AST failed"
  );;