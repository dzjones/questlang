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
    mainQuest = exampleQuestAST ;
};;

let fullBadAST1 = {
    world = exampleWorldAST ;
    subquests = [] ;
    mainQuest = exampleBadQuestAST ;
};;

let fullAST2 = {
    world = exampleWorldAST ;
    subquests = [subquestAST] ;
    mainQuest = exampleQuestAST2 ;
};;


let count : unit -> int =
  let next = ref 1 in
  let next() =
    let n = !next in
    next := n + 1;
    n
  in
  next;;


let printTestOutput ast = print_string ("Test " ^ (string_of_int (count ())) ^ ": " ^ (evalAST ast));;


(** Evaluate the ASTs **)

printTestOutput fullAST1;;
printTestOutput fullAST2;;
printTestOutput fullBadAST1;;