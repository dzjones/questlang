%{
    open Abstract_syntax_tree;;
%}

%token <string> TknSubquest TknFormalParam TknSubquestRun TknArgument TknVar
                TknLiteral TknLet TknArgumentLoc TknArgumentNPC TknArgumentItem
%token TknWorld TknQuest TknLocation TknNPC TknItem TknAt TknRequire TknGoto
       TknGet TknKill TknUse TknEq TknGetLoc TknPlayer TknArgumentPlayer EOF
       TknVulnerable TknTo TknAnd TknOr TknImplies TknNot TknLBrac TknRBrac
       TknHolding TknIsAlive TknIsDead TknIsAt

%left TknAnd TknOr TknImplies

%start main
%type <Abstract_syntax_tree._ParserAST list> main

%%

main:
    | TknWorld worldExprs main    { (ParserWorldEntry $2)::$3 }
    | TknWorld worldExprs    { [ParserWorldEntry $2] }
    | TknQuest questExprs main { (ParserQuestExp $2)::$3 }
    | TknQuest questExprs { [ParserQuestExp $2] }
    | TknSubquest parameterList questExprs main { (ParserSubquestExp ($1, ($2, $3)))::$4 }
    | TknSubquest parameterList questExprs { [ParserSubquestExp ($1, ($2, $3))] }

worldExprs:
    | world worldExprs { $1::$2 }
    | world { [$1] }

world:
    | TknLocation TknLiteral { LocationWorldEntry (LocationLiteral $2) }
    | TknNPC TknLiteral TknAt TknLiteral { CharWorldEntry (NPCLiteral $2, LocationLiteral $4) }
    | TknNPC TknPlayer TknAt TknLiteral { CharWorldEntry (PlayerC, LocationLiteral $4) }
    | TknItem TknLiteral TknAt TknLiteral { ItemWorldEntry ($2, LocationLiteral $4) }
    | TknLiteral TknVulnerable TknTo itemList { VulnerabilityWorldEntry (NPCLiteral $1, $4) }

predicateExp:
    | TknHolding TknLiteral { HeldPred $2 }
    | TknLiteral TknIsAlive { DeadPred (NPCLiteral $1) }
    | TknLiteral TknIsDead  { AlivePred (NPCLiteral $1) }
    | TknLiteral TknIsAt TknLiteral { AtPred (NPCLiteral $1, LocationLiteral $3) }
    | TknPlayer TknIsAt TknLiteral { AtPred (PlayerC, LocationLiteral $3) }

conditionExp:
    | conditionExp TknAnd conditionExp { CondAnd ($1, $3) }
    | conditionExp TknOr conditionExp { CondOr ($1, $3) }
    | conditionExp TknImplies conditionExp { CondImplies ($1, $3) }
    | TknNot conditionExp  { CondNot $2 }
    | conditionExpAtomic { $1 }

conditionExpAtomic:
    | TknLBrac conditionExp TknRBrac { $2 }
    | predicateExp { CondPred $1 }

questExprs:
    | quest questExprs { $1::$2 }
    | quest { [$1] }

quest:
    | TknGoto TknLiteral { ActionExp (Goto, (LocationExp (LocationLiteral $2))) }
    | TknGet TknLiteral { ActionExp (Get, (ItemExp $2)) }
    | TknKill TknLiteral { ActionExp (Kill, (CharExp (NPCLiteral $2))) }
    | TknRequire TknLiteral { ActionExp (Require, (ItemExp $2)) }
    | TknRequire TknLBrac conditionExp TknRBrac { ActionExp (Require, CondExp $3) }
    | TknUse TknLiteral { ActionExp (Use, (ItemExp $2)) }
    | TknGoto TknVar { ActionExp (Goto, (VarExp $2)) }
    | TknGet TknVar { ActionExp (Get, (VarExp $2)) }
    | TknKill TknVar { ActionExp (Kill, (VarExp $2)) }
    | TknRequire TknVar { ActionExp (Require, (VarExp $2)) }
    | TknUse TknVar { ActionExp (Use, (VarExp $2)) }
    | TknLet TknEq builtinFunExp { LetExp ($1, $3) }
    | TknSubquestRun argumentList { RunSubquestExp ($1, $2) }

builtinFunExp:
    | TknGetLoc TknLiteral { GetLoc (CharExp (NPCLiteral $2)) }
    | TknGetLoc TknPlayer { GetLoc (CharExp PlayerC) }
    | TknGetLoc TknVar { GetLoc (VarExp $2) }

parameterList:
    | TknFormalParam parameterList { ($1)::$2 }
    | TknFormalParam { [$1] }

argumentList:
    | arg argumentList { $1::$2 }
    | arg { [$1] }

arg:
    | TknArgument { VarExp $1 }
    | TknArgumentLoc { LocationExp (LocationLiteral $1) }
    | TknArgumentNPC { CharExp (NPCLiteral $1) }
    | TknArgumentPlayer { CharExp PlayerC }
    | TknArgumentItem { ItemExp $1 }

itemList:
    | itA itemList { $1::$2 }
    | itA { [$1] }

itA:
    | TknArgument { $1 }
    | TknArgumentItem { $1 }