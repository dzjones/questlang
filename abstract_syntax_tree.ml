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
    | GetCharLoc of characterId
    | GetItemLoc of itemId;;

type worldEntry =
    | CharWorldEntry of characterId * locationId
    | ItemWorldEntry of itemId * locationId
    | LocationWorldEntry of locationId;;

type unaryAction =
    | Require
    | Goto
    | Get
    | Kill
    | Interact;;

type questExp =
    | ActionExp of unaryAction * paramExp
    | LetExp of var * paramExp
    | RunSubquestExp of subquestId * (paramExp list);;

type subquestEntry = subquestId * (var list) * (questExp list);;

type _AST = {
    world : worldEntry list;
    subquests : subquestEntry list;
    mainQuest : questExp list;
};;