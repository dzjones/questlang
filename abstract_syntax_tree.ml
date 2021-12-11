(* support for checking types of arguments passed to subquests
type dataType =
    | LocationTy
    | ItemTy
    | CharTy

type formalArg = dataType * var
*)

type var = string;;
type locationId = LocationLiteral of string | NullLocation;;
type characterId = NPCLiteral of string | PlayerC;;
type itemId = string;;
type subquestId = string;;

type paramExp =
    | VarExp of var
    | LocationExp of locationId
    | ItemExp of itemId
    | CharExp of characterId
    | GetLoc of paramExp;;

type worldEntry =
    | CharWorldEntry of characterId * locationId
    | ItemWorldEntry of itemId * locationId
    | LocationWorldEntry of locationId;;

type unaryAction =
    | Require
    | Goto
    | Get
    | Kill
    | Use;;

type questExp =
    | ActionExp of unaryAction * paramExp
    | LetExp of var * paramExp
    | RunSubquestExp of subquestId * (paramExp list);;

type subquestEntry = subquestId * ((var list) * (questExp list));;

type _AST = {
    world : worldEntry list;
    subquests : subquestEntry list;
    mainQuest : questExp list;
};;

type _ParserAST =
    | ParserWorldEntry of worldEntry list
    | ParserQuestExp of questExp list
    | ParserSubquestExp of subquestEntry

(*
type token =
    | TknWorld
    | TknQuest
    | TknSubquest of string
    | TknFormalParam of string
    | TknSubquestRun of string
    | TknArgument of string
    | TknLocation
    | TknNPC
    | TknItem
    | TknAt
    | TknVar of string
    | TknLiteral of string
    | TknRequire
    | TknGoto
    | TknGet
    | TknKill
    | TknUse
    | TknLet of string
    | TknEq
    | TknGetLoc
    | EOF
    *)