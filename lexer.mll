{
open Abstract_syntax_tree;;
open Parser;;

}

let numeric = ['0' - '9']
let lowercase = ['a' - 'z']
let uppercase = ['A' - 'Z']
let letter = ['a' - 'z' 'A' - 'Z' '_']
let indent = "    "

rule token = parse
  | [' ' '\t' '\n'] { token lexbuf }  (* skip over whitespace *)
  | eof             { EOF }
  | "World"         { TknWorld }
  | "Quest"         { TknQuest }
  | "Location"      { TknLocation }
  | "NPC"           { TknNPC }
  | "Item"          { TknItem }
  | "Player"        { TknPlayer }
  | "Vulnerable"    { TknVulnerable }
  | "at"            { TknAt }
  | "to"            { TknTo }
  | "goto"          { TknGoto }
  | "get"           { TknGet }
  | "kill"          { TknKill }
  | "require"       { TknRequire }
  | "use"           { TknUse }
  | "let " (lowercase (letter | numeric | "'")* as var) { TknLet var }
  | "="             { TknEq }
  | "getloc"        { TknGetLoc }
  | "Subquest " (uppercase (letter | numeric | "'")* as subquest) { TknSubquest subquest }
  | "run " (uppercase (letter | numeric | "'")* as subquest) { TknSubquestRun subquest }
  | lowercase (letter | numeric | "'")* as var { TknVar var }
  | uppercase (letter | numeric | "'")* as literal { TknLiteral literal }
  | ")"             { raise (Failure "mismatched bracket!") }
  | "("             { brackets lexbuf }
  | ","             { brackets lexbuf }
and brackets = parse
  | ")"             { token lexbuf }
  | "("             { raise (Failure "brackets can only be one level deep") }
  | (lowercase (letter | numeric | "'")* as var) ")"? { TknFormalParam var }
  | (uppercase (letter | numeric | "'")* as literal) ")"? { TknArgument literal }
  | "Location " (uppercase (letter | numeric | "'")* as literal) ")"? { TknArgumentLoc literal }
  | "NPC " (uppercase (letter | numeric | "'")* as literal) ")"? { TknArgumentNPC literal }
  | "NPC Player" ")"? { TknArgumentPlayer }
  | "Item " (uppercase (letter | numeric | "'")* as literal) ")"? { TknArgumentItem literal }
  | ' '             { brackets lexbuf }

{
 let lextest s = token (Lexing.from_string s)

 let get_all_tokens s =
     let b = Lexing.from_string (s^"\n") in
     let rec g () = 
     match token b with EOF -> []
     | t -> t :: g () in
     g ()

let try_get_all_tokens s =
    try (Some (get_all_tokens s), true)
    with Failure "unmatched open comment" -> (None, true)
       | Failure "unmatched closed comment" -> (None, false)
 }

