open Abstract_syntax_tree;;
open Utils;;
open Either;;
open List;;

type paramRes =
    | LocationRes of locationId
    | ItemRes of itemId
    | CharRes of characterId;;

type playerType = {
    inventory : itemId list;
    location : locationId;
};;

type locMap = (locationId * ((itemId list) * (characterId list))) list;;

type worldState = {
    charsAlive : characterId list;
    charsDead : characterId list;
    player : playerType;
    worldMap : locMap;
    subquests : subquestEntry list;
    memory : (var * paramRes) list;
};;

let lookupPlayerLoc ws = mapLookup ws.worldMap ws.player.location;;

let updateMemory ws f = { ws with memory = f ws.memory };;
let updateInventory ws f = { ws with player = { ws.player with inventory = f ws.player.inventory } };;

let unsafeSetItemsAtPlayerLoc ws items = { ws with
    worldMap = mapUpdate ws.worldMap ws.player.location (fun (_, npcs) -> (items, npcs)) ([], [])
};;

let unsafeSetNpcsAtPlayerLoc ws npcs = { ws with
    worldMap = mapUpdate ws.worldMap ws.player.location (fun (items, _) -> (items, npcs)) ([], [])
};;

let rec searchItem worldMap item = match worldMap with
    | [] -> None
    | (loc, (items, _)) :: rest -> if contains items item
        then Some loc
        else searchItem rest item;;

let rec searchNpc worldMap npc = match worldMap with
    | [] -> None
    | (loc, (_, npcs)) :: rest -> if contains npcs npc
        then Some loc
        else searchNpc rest npc;;



let emptyWorldState = {
    charsAlive = [ PlayerC ];
    charsDead = [];
    player = {
        inventory = [];
        location = NullLocation
    };
    worldMap = [];
    subquests = [];
    memory = [];
};;

let rec populateWorldState worldData world = match worldData with
    | [] -> world
    | worldE :: worldData' -> populateWorldState worldData' ( match worldE with
        | CharWorldEntry (chr, loc) -> (match chr with
            | PlayerC -> { world with player = (match world.player.location with
                | NullLocation -> { world.player with location = loc }
                | _ -> raise (Failure "Error: Player's starting location was set twice")) }
            | npc -> { world with
                charsAlive = npc :: world.charsAlive ;
                worldMap = mapUpdate world.worldMap loc (fun (items, npcs) -> (items, (npc :: npcs))) ([], [ npc ])
                }
            )
        | ItemWorldEntry (itm, loc) -> { world with
            worldMap = mapUpdate world.worldMap loc (fun (items, npcs) -> ((itm :: items), npcs)) ([ itm ], [])
            }
        | LocationWorldEntry loc -> { world with
            worldMap = mapUpdate world.worldMap loc (fun x -> x) ([], [])
        }
    );;

let buildWorldState ast =
    let populated = populateWorldState ast.world emptyWorldState in
    { populated with subquests = ast.subquests };;

let rec evalParamExp ws e = match e with
    | LocationExp loc -> LocationRes loc
    | ItemExp item -> ItemRes item
    | CharExp c -> CharRes c
    | VarExp v -> (match mapLookup ws.memory v with
        | None -> raise (Failure "Error: variable lookup failed")
        | Some r -> r
        )
    | GetLoc e' -> (match evalParamExp ws e' with
        | LocationRes loc -> LocationRes loc
        | CharRes c -> (match c with
            | PlayerC -> LocationRes ws.player.location
            | npc -> (match searchNpc ws.worldMap npc with
                | None -> raise (Failure "NPC not found")
                | Some loc -> LocationRes loc
                )
            )
        | ItemRes item -> (match searchItem ws.worldMap item with
            | None -> raise (Failure "Item not found")
            | Some loc -> LocationRes loc
            )
        );;

let [@warning "-11"] rec questEval q stepNo ws = match q with
    | [] -> Right (stepNo, ws)
    | qstep :: qs -> let recurse = questEval qs (stepNo + 1) in (
        match qstep with
        | ActionExp (act, e) -> (match (act, evalParamExp ws e) with
            | (Require, (ItemRes itm)) ->
                if contains ws.player.inventory itm
                    then recurse ws
                    else Left (stepNo, "Required item not held by player")
            | (Goto, (LocationRes loc)) -> recurse { ws with player = { ws.player with location = loc } }
            | (Get, (ItemRes itm)) -> (match lookupPlayerLoc ws with
                | None -> Left (stepNo, "Player is at an invalid location")
                | Some (items, _) -> (match extract items itm with
                    | None -> Left (stepNo, "Item does not exist at player's location")
                    | Some items' -> recurse { (unsafeSetItemsAtPlayerLoc ws items') with
                        player = { ws.player with inventory = itm :: ws.player.inventory };
                        }
                    )
                )
            | (Kill, (CharRes c)) -> (match c with
                | PlayerC -> Left (stepNo, "The player character cannot kill themselves")
                | npc -> (match lookupPlayerLoc ws with
                    | None -> Left (stepNo, "Player is at an invalid location")
                    | Some (_, npcs) -> (match extract npcs npc with
                        | None -> Left (stepNo, "NPC does not exist at player's location")
                        | Some npcs' -> recurse
                            { (unsafeSetNpcsAtPlayerLoc ws npcs') with charsDead = npc :: ws.charsDead }
                        )
                    )
                )
            | (Use, (ItemRes itm)) -> (match extract ws.player.inventory itm with
                | None -> Left (stepNo, "Required item not held by player")
                | Some newInv -> recurse (updateInventory ws (fun _ -> newInv))
                )
            | _ -> Left (stepNo, "Basic action got the wrong type of input")
            )
        | LetExp (v, e) -> recurse (updateMemory ws (mapAdd (v, (evalParamExp ws e))))
        | RunSubquestExp (sqname, args) -> (match mapLookup ws.subquests sqname with
            | None -> Left (stepNo, "Subquest not found")
            | Some (formalArgs, subq) ->
                let oldMemory = ws.memory in
                let newWS = (fold_left
                    (fun ws' (v, e) -> updateMemory ws' (mapAdd (v, (evalParamExp ws e))))
                    ws
                    (combine formalArgs args)) in
                (match questEval subq (stepNo + 1) newWS with
                    | Left (stepNo', err) -> Left (stepNo', err)
                    | Right (stepNo', newWS') -> questEval qs stepNo' { newWS' with memory = oldMemory })
            )
        | _ -> Left (stepNo, "A typing error has occured")
    );;

let evalAST ast = String.concat "" (List.map
    (fun mq -> match questEval mq 0 (buildWorldState ast) with
        | Left (stepNo, err) -> "Quest invalidation occured at instruction " ^ (string_of_int (stepNo + 1)) ^ ": " ^ err ^ "\n"
        | Right _ -> "Quest was validated successfully!\n"
    ) ast.mainQuests);;

let printEvalAST ast = print_string (evalAST ast);;