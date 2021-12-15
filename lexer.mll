{
open Abstract_syntax_tree;;
open Parser;;

}

(* Some helper definitions, mostly for lowercaseId and uppercaseId *)
let numeric = ['0' - '9']
let lowercase = ['a' - 'z']
let uppercase = ['A' - 'Z']
let letter = ['a' - 'z' 'A' - 'Z' '_']
let lowercaseId = lowercase (letter | numeric | "'")*
let uppercaseId = uppercase (letter | numeric | "'")*

(* Main parser *)
rule token = parse
  | [' ' '\t' '\n'] { token lexbuf } (* this language is whitespace agnostic *)
  | eof             { EOF }
  | "World"         { TknWorld } (* Language keywords *)
  | "Quest"         { TknQuest }
  | "Location"      { TknLocation }
  | "NPC"           { TknNPC }
  | "Item"          { TknItem }
  | "Player"        { TknPlayer }
  | "Vulnerable"    { TknVulnerable }
  | "at"            { TknAt }
  | "to"            { TknTo }
  | "and"           { TknAnd }
  | "or"            { TknOr }
  | "Holding"       { TknHolding }
  | "is Alive"      { TknIsAlive }
  | "is Dead"       { TknIsDead }
  | "is at"         { TknIsAt }
  | "=>"            { TknImplies }
  | "not"           { TknNot }
  | "goto"          { TknGoto }
  | "get"           { TknGet }
  | "kill"          { TknKill }
  | "require"       { TknRequire }
  | "use"           { TknUse }
  | "let " (lowercaseId as var) { TknLet var } (* For let expressions *)
  | "="             { TknEq }
  | "getloc"        { TknGetLoc }
  | "Subquest " (uppercaseId as subquest) { TknSubquest subquest } (* Defining and running subquests *)
  | "run " (uppercaseId as subquest) { TknSubquestRun subquest }
  | lowercaseId as var { TknVar var }
  | uppercaseId as literal { TknLiteral literal }
  | ")"             { raise (Failure "mismatched bracket!") }
  | "("             { brackets lexbuf }
  | ","             { brackets lexbuf }
  | "["             { TknLBrac }
  | "]"             { TknRBrac }
and brackets = parse (* This lets us assign special tokens to strings in parentheses/brackets *)
  | ")"             { token lexbuf }
  | "("             { raise (Failure "brackets can only be one level deep") }
  | (lowercaseId as var) ")"? { TknFormalParam var }
  | (uppercaseId as literal) ")"? { TknArgument literal }
  | "Location " (uppercaseId as literal) ")"? { TknArgumentLoc literal }
  | "NPC " (uppercaseId as literal) ")"? { TknArgumentNPC literal }
  | "NPC Player" ")"? { TknArgumentPlayer }
  | "Item " (uppercaseId as literal) ")"? { TknArgumentItem literal }
  | ' '             { brackets lexbuf }

{

 }

