(* This is just an idea, it's not currently implemented: *)
(* support for checking types of arguments passed to subquests at call time
type dataType =
    | LocationTy
    | ItemTy
    | CharTy

type formalArg = dataType * var
*)


(* basic types for representing identifiers for our quest parameters *)
type var = string;;
type locationId = LocationLiteral of string | NullLocation;;
type characterId = NPCLiteral of string | PlayerC;;
type itemId = string;;
type subquestId = string;;

(* Predicates are statements about the state of the world.
   They evaluate to booleans at a particular world state *)
type predicate =
    | HeldPred of itemId
    | DeadPred of characterId
    | AlivePred of characterId
    | AtPred of characterId * locationId;;

(* Conditions take the idea of predicates further by adding logical connectives to them *)
type condition =
    | CondAnd of condition * condition
    | CondOr of condition * condition
    | CondImplies of condition * condition
    | CondNot of condition
    | CondPred of predicate;;

(* The type of parameter expressions that will be evaluated when encountered while running the quest *)
type paramExp =
    | VarExp of var
    | LocationExp of locationId
    | ItemExp of itemId
    | CharExp of characterId
    (* Builtin function for getting the location of another parameter *)
    | GetLoc of paramExp
    | CondExp of condition;;

(* A world entry describing something about the world.
   A list of these is used to construct the initial world state *)
type worldEntry =
    | CharWorldEntry of characterId * locationId
    | ItemWorldEntry of itemId * locationId
    | LocationWorldEntry of locationId
    | VulnerabilityWorldEntry of characterId * (itemId list);;

(* Actions that the player can take *)
type unaryAction =
    | Require
    | Goto
    | Get
    | Kill
    | Use;;

(* One atomic component of a Quest: It can be either an action,
   a variable binding or a call to an external subquest*)
type questExp =
    | ActionExp of unaryAction * paramExp
    | LetExp of var * paramExp
    | RunSubquestExp of subquestId * (paramExp list);;

(* The type of subquests. Subquests can be tought of as functions
   that are called from the body of a quest with a list of arguments
   to be substituted for the formal arguments when running the subquest *)
type subquestEntry = subquestId * ((var list) * (questExp list));;

(* The main AST that we get from parsing, bundling together all that we've seen earlier *)
type _AST = {
    world : worldEntry list;
    subquests : subquestEntry list;
    (* We may have multiple quests that are each validated individually
       against the same starting world state *)
    mainQuests : (questExp list) list;
};;

(* Helper type used for parsing *)
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