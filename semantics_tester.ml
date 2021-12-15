open Abstract_syntax_tree;;
open Semantics;;

(*
    Here we define some sample ASTs in raw form, so we can test the semantics
    functions without having to update the lexer and parser in concert.
*)

let exampleWorldAST = [
    LocationWorldEntry (LocationLiteral "Forest");
    LocationWorldEntry (LocationLiteral "Desert");
    CharWorldEntry (PlayerC, LocationLiteral "Forest");
    CharWorldEntry (NPCLiteral "Wolf", LocationLiteral "Forest");
    ItemWorldEntry ("Sword", LocationLiteral "Desert");
    VulnerabilityWorldEntry (NPCLiteral "Wolf", ["Sword"])
];;

let exampleQuestAST = [
    ActionExp (Goto, (LocationExp (LocationLiteral "Desert")));
    ActionExp (Get, (ItemExp "Sword"));
    ActionExp (Goto, (LocationExp (LocationLiteral "Forest")));
    ActionExp (Kill, (CharExp (NPCLiteral "Wolf")))
];;

let exampleBadQuestAST = [ (* This AST is meant to fail *)
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


(* This function tests a given AST by "running" it and checking the output against an expected output*)
(* The test name is provided in order to give information to the users about which test passed or failed *)
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