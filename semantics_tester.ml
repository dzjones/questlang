open Abstract_syntax_tree;;
open Semantics;;

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

(a)
(a, b)

Subquest RoundTrip (location, item)
    let firstLoc = getloc Player
    goto location
    get item
    goto firstLoc

Quest
    run RoundTrip (Desert, Sword)
    kill Wolf
*)

let exampleWorldAST = [
    LocationWorldEntry (LocationLiteral "Forest");
    LocationWorldEntry (LocationLiteral "Desert");
    CharWorldEntry (PlayerC, LocationLiteral "Forest");
    CharWorldEntry (NPCLiteral "Wolf", LocationLiteral "Forest");
    ItemWorldEntry ("Sword", LocationLiteral "Desert")
];;

let exampleQuestAST = [
    ActionExp (Goto, (LocationExp (LocationLiteral "Desert")));
    ActionExp (Get, (ItemExp "Sword"));
    ActionExp (Goto, (LocationExp (LocationLiteral "Forest")));
    ActionExp (Kill, (CharExp (NPCLiteral "Wolf")))
];;

let exampleBadQuestAST = [
    ActionExp (Goto, (LocationExp (LocationLiteral "Desert")));
    ActionExp (Get, (ItemExp "Sword"));
    ActionExp (Kill, (CharExp (NPCLiteral "Wolf")))
];;

let subquestAST = "RoundTrip", (
    ["loc"; "item"],
    [
        LetExp ("initial", GetLoc (CharExp PlayerC));
        ActionExp (Goto, (VarExp "loc"));
        ActionExp (Get, (VarExp "item"));
        ActionExp (Goto, (VarExp "initial"))
    ]);;

let exampleQuestAST2 =[
    RunSubquestExp ("RoundTrip", [LocationExp (LocationLiteral "Desert"); ItemExp "Sword"]);
    ActionExp (Kill, (CharExp (NPCLiteral "Wolf")))
];;

let fullAST1 = {
    world = exampleWorldAST ;
    subquests = [] ;
    mainQuests = [exampleQuestAST] ;
};;

let fullBadAST1 = {
    world = exampleWorldAST ;
    subquests = [] ;
    mainQuests = [exampleBadQuestAST] ;
};;

let fullAST2 = {
    world = exampleWorldAST ;
    subquests = [subquestAST] ;
    mainQuests = [exampleQuestAST2] ;
};;


let testAST expectedOutput ast testName =
    let actualOutput = evalAST ast in
    if actualOutput = expectedOutput
        then print_string ("\027[32mTest case \"" ^ testName ^"\" passed successfully!\n\027[0m")
        else print_string ("\027[31mTest case \"" ^ testName ^"\" failed! This is the actual output:\n    " ^ actualOutput ^ "vs the expected output:\n    " ^ expectedOutput ^ "\027[0m");;

let testASTExpectSuccess = testAST "Quest was validated successfully!\n";;

(** Evaluate the ASTs **)

let _ = print_string "\n\nUnit testing the semantics...\n\n";;

let _ = testASTExpectSuccess fullAST1 "Simple quest";;
let _ = testASTExpectSuccess fullAST2 "Simple quest using subquest";;
let _ = testAST
    "Quest invalidation occured at instruction 3: NPC does not exist at player's location\n"
    fullBadAST1
    "Simple invalid quest";;