type paramExp =
    | IdentifierExp of string
    | LocationLiteralExp of string
    | ItemLiteralExp of string
    | NPCLiteralExp of string
    | GetLoc of paramExp

type questExp =
    | RequireActionExp of paramExp
    | GotoActionExp of paramExp
    | GetActionExp of paramExp
    | KillActionExp of paramExp
    | InteractActionExp of paramExp
    | LetExp of string * paramExp (* let x = Location *)
    | DataExp of (string * paramExp) list (* (x = Location, y = Potion) *)
    | QuestExp of (paramExp list) * (questExp list)
    | SubquestExp of string * (paramExp list) * (questExp list)
    | RunSubquestExp of string * (paramExp list)

type worldObjExp =
    | NPCWorldExp of paramExp * paramExp
    | ItemWorldExp of paramExp * paramExp
    | LocationWorldExp of paramExp

let exampleWorldAST = [
    LocationWorldExp (LocationLiteralExp "Forest");
    LocationWorldExp (LocationLiteralExp "Desert");
    NPCWorldExp (NPCLiteralExp "Player", LocationLiteralExp "Forest");
    NPCWorldExp (NPCLiteralExp "Wolf", LocationLiteralExp "Forest");
    ItemWorldExp (ItemLiteralExp "Sword", LocationLiteralExp "Desert");
]

let exampleQuestAST = [
    GotoActionExp (LocationLiteralExp "Desert");
    GetActionExp (ItemLiteralExp "Sword");
    GotoActionExp (LocationLiteralExp "Forest");
    KillActionExp (NPCLiteralExp "Wolf");
]

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

let subquestAST = SubquestExp ("RoundTrip",
    [IdentifierExp "location"; IdentifierExp "item"],
    [
        LetExp ("firstLoc", GetLoc (NPCLiteralExp "Player"));
        GotoActionExp (IdentifierExp "location");
        GetActionExp (IdentifierExp "item");
        GotoActionExp (IdentifierExp "firstLoc")
    ])

let exampleQuestAST2 = QuestExp (
    [],
    [
        RunSubquestExp ("RoundTrip", [LocationLiteralExp "Desert"; ItemLiteralExp "Sword"]);
        KillActionExp (NPCLiteralExp "Wolf")
    ]
)