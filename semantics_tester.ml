open Lexing
open Abstract_syntax_tree
open Parser
open Lexer
open Utils
open Semantics
open Validate

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
    ["location"; "item"],
    [
        LetExp ("firstLoc", GetLoc (CharExp PlayerC));
        ActionExp (Goto, (VarExp "location"));
        ActionExp (Get, (VarExp "item"));
        ActionExp (Goto, (VarExp "firstLoc"))
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

let worldQs = {|World
  Location Forest
  Location Desert
  NPC Player at Forest
  NPC Wolf at Forest
  Item Sword at Desert
  Wolf Vulnerable to (Sword)

|};;

let fullQl1 = worldQs ^ {|Quest
  goto Desert
  get Sword
  goto Forest
  kill Wolf|};;

let fullQl1Bad = worldQs ^ {|Quest
  goto Desert
  get Sword
  kill Wolf|};;

let fullQl2 = worldQs ^ {|Subquest RoundTrip (location, item)
  let firstLoc = getloc Player
  goto location
  get item
  goto firstLoc

Quest
  run RoundTrip (Location Desert, Item Sword)
  kill Wolf|};;

let testParsing expectedAST ql testName =
    let lexbuf = Lexing.from_string ql in
    let parserRawData = Parser.main Lexer.token lexbuf in
    let actualAST = buildFullAST parserRawData in
    if actualAST = expectedAST
        then print_string ("\027[32mParser test case \"" ^ testName ^"\" passed successfully!\n\027[0m")
        else print_string ("\027[31mParser test case \"" ^ testName ^"\" failed!\n\027[0m");;


(* This function tests a given AST by "running" it and checking the output against an expected output*)
(* The test name is provided in order to give information to the users about which test passed or failed *)
let testAST expectedOutput ast testName =
    let actualOutput = evalAST ast in
    if actualOutput = expectedOutput
        then print_string ("\027[32mSemantic test case \"" ^ testName ^"\" passed successfully!\n\027[0m")
        else print_string ("\027[31mSemantic test case \"" ^ testName ^"\" failed! This is the actual output:\n    " ^ actualOutput ^ "vs the expected output:\n    " ^ expectedOutput ^ "\n\027[0m");;

let testASTExpectSuccess = testAST "Quest was validated successfully!\n";;

(** Evaluate the ASTs **)

let _ = print_string "\n\nUnit testing the semantics...\n\n";;

let _ = testASTExpectSuccess fullAST1 "Simple quest";;
let _ = testASTExpectSuccess fullAST2 "Simple quest using subquest";;
let _ = testAST
    "Quest invalidation occured at instruction 3: NPC does not exist at player's location\n"
    fullBadAST1
    "Simple invalid quest";;

let _ = print_string "\n\nUnit testing the lexer/parser...\n\n";;

let _ = testParsing fullAST1 fullQl1 "Simple quest parsing";;
let _ = testParsing fullAST2 fullQl2 "Simple quest using subquests parsing";;
let _ = testParsing fullBadAST1 fullQl1Bad "Simple bad quest parsing";;