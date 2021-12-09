type var = string

(* support for checking types of arguments passed to subquests
type dataType =
    | LocationTy
    | ItemTy
    | CharTy

type formalArg = dataType * var
*)

type locatonId = LocationLiteral of string | NullLocation
type characterId = NPCLiteral of string | PlayerC
type itemId = string
type subquestId = string

type paramExp =
    | VarExp of var
    | LocationExp of locatonId
    | ItemExp of itemId
    | CharExp of characterId
    | GetCharLoc of characterId
    | GetItemLoc of itemId

type worldEntry =
    | CharWorldEntry of characterId * locatonId
    | ItemWorldEntry of itemId * locatonId
    | LocationWorldEntry of locatonId

type subquestEntry = subquestId * (var list) * (questExp list)

type unaryAction =
    | Require
    | Goto
    | Get
    | Kill
    | Interact

type questExp =
    | ActionExp of unaryAction * paramExp
    | LetExp of var * paramExp
    | RunSubquestExp of subquestId * (paramExp list)

type _AST = {
    world : worldEntry list
    subquests : subquestEntry list
    mainQuest : questExp list
}

(*
World
    location Forest
    location Desert
    npc Player at Forest
    npc Wolf at Forest
    item Sword at Desert

Quest
    goto Desert
    get Sword
    goto Forest
    kill Wolf

hypotheticals:

Subquest RoundTrip (location, item)
    let firstLoc = getloc Player
    goto location
    get item
    goto firstLoc

Quest
    RoundTrip (Desert, Sword)
    kill Wolf
*)

let exampleWorldAST = [
    LocationWorldEntry (LocationLiteral "Forest");
    LocationWorldEntry (LocationLiteral "Desert");
    CharWorldEntry (PlayerC, LocationLiteral "Forest")
    CharWorldEntry (NPCLiteral "Wolf", LocationLiteral "Forest");
    ItemWorldEntry ("Sword", LocationLiteral "Desert");
]

let exampleQuestAST = [
    ActionExp (Goto, (LocationExp (LocationLiteral "Desert")));
    ActionExp (Get, (ItemLiteralExp "Sword"));
    ActionExp (Goto, (LocationExp (LocationLiteral "Forest")));
    ActionExp (Kill, (CharExp (NPCLiteral "Wolf")));
]

let subquestAST = "RoundTrip",
    ["loc"; "item"],
    [
        LetExp ("initial", GetCharLoc Player);
        ActionExp (Goto, (VarExp "loc"));
        ActionExp (Get, (VarExp "item"));
        ActionExp (Goto, (VarExp "initial"))
    ]

let exampleQuestAST2 = QuestExp (
    [
        RunSubquestExp ("RoundTrip", [LocationExp (LocationLiteral "Desert"); ItemExp "Sword"]);
        ActionExp (Kill, (CharExp (NPCLiteral "Wolf")))
    ]
)

fullAST1 = {
    world = exampleWorldAST ;
    subquests = [] ;
    mainQuest = exampleQuestAST ;
}

fullAST2 = {
    world = exampleWorldAST ;
    subquests = [subquestAST] ;
    mainQuest = exampleQuestAST2 ;
}