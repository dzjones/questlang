type literalExp =
    | LocationLiteralExp of string
    | ItemLiteralExp of string
    | NPCLiteralExp of string

type questExp =
    | RequireActionExp of literalExp
    | GotoActionExp of literalExp
    | GetActionExp of literalExp
    | KillActionExp of literalExp
    | InteractActionExp of literalExp

type worldObjExp =
    | NPCWorldExp of literalExp * literalExp
    | ItemWorldExp of literalExp * literalExp
    | LocationWorldExp of literalExp

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
*)