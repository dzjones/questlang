open Abstract_syntax_tree;;
open Utils;;
open Either;;
open List;;

(* The type of parameter results, returned by parameter expression evaluation *)
type paramRes =
    | LocationRes of locationId
    | ItemRes of itemId
    | CharRes of characterId
    | CondRes of bool;;

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
    vulnerability : (characterId * (itemId list)) list;
    allItems : itemId list;
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
    | (loc, (items, _)) :: rest -> if mem item items
        then Some loc
        else searchItem rest item;;

let rec searchNpc worldMap npc = match worldMap with
    | [] -> None
    | (loc, (_, npcs)) :: rest -> if mem npc npcs
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
    vulnerability = [];
    allItems = [];
};;

let rec populateWorldState worldData world = match worldData with
    | [] -> Right world
    | worldE :: worldData' -> let recurse = populateWorldState worldData' in ( match worldE with
        | CharWorldEntry (chr, loc) -> (match chr with
            | PlayerC -> (match world.player.location with
                | NullLocation -> recurse { world with player = { world.player with location = loc }}
                | _ -> Left "Error: Player's starting location was set twice")
            | npc -> if mem npc world.charsAlive then Left "Error: NPC's location was set twice" else
                recurse { world with
                    charsAlive = npc :: world.charsAlive ;
                    worldMap = mapUpdate world.worldMap loc (fun (items, npcs) -> (items, (npc :: npcs))) ([], [ npc ])
                }
            )
        | ItemWorldEntry (itm, loc) -> if mem itm world.allItems
            then Left "Error: item's location was set twice"
            else recurse { world with
                worldMap = mapUpdate world.worldMap loc (fun (items, npcs) -> ((itm :: items), npcs)) ([ itm ], []);
                allItems = itm :: world.allItems
            }
        | LocationWorldEntry loc -> recurse { world with
            worldMap = mapUpdate world.worldMap loc (fun x -> x) ([], [])
            }
        | VulnerabilityWorldEntry (chr, vItems) -> (match mapLookup world.vulnerability chr with
            | None -> recurse { world with
                vulnerability = (chr, vItems) :: world.vulnerability
                }
            | Some _ -> Left "Error: NPC's vulnerability was set twice")
    );;

let buildWorldState ast =
    match populateWorldState ast.world emptyWorldState with
        | Left err -> Left err
        | Right populated -> Right { populated with subquests = ast.subquests };;

let rec evalParamExp ws e = match e with
    | LocationExp loc -> Right (LocationRes loc)
    | ItemExp item -> Right (ItemRes item)
    | CharExp c -> Right (CharRes c)
    | VarExp v -> (match mapLookup ws.memory v with
        | None -> Left "Error: variable lookup failed"
        | Some r -> Right r
        )
    | GetLoc e' -> (match evalParamExp ws e' with
        | Left err -> Left err
        | Right (LocationRes loc) -> Right (LocationRes loc)
        | Right (CharRes c) -> (match c with
            | PlayerC -> Right (LocationRes ws.player.location)
            | npc -> (match searchNpc ws.worldMap npc with
                | None -> Left "NPC not found"
                | Some loc -> Right (LocationRes loc)
                )
            )
        | Right (ItemRes item) -> (match searchItem ws.worldMap item with
            | None -> Left "Item not found"
            | Some loc -> Right (LocationRes loc)
            )
        | Right (CondRes _) -> Left "Cannot get the location of a condition"
        )
    | CondExp cond' -> (let rec evalCond cond = match cond with
        | CondAnd (cond1, cond2) -> evalCond cond1 && evalCond cond2
        | CondOr (cond1, cond2) -> evalCond cond1 || evalCond cond2
        | CondImplies (cond1, cond2) -> (not (evalCond cond1)) || evalCond cond2
        | CondNot nCond -> not (evalCond nCond)
        | CondPred prd -> (match prd with
            | HeldPred item -> mem item ws.player.inventory
            | DeadPred chr -> mem chr ws.charsDead
            | AlivePred chr -> mem chr ws.charsAlive
            | AtPred (PlayerC, loc) -> ws.player.location = loc
            | AtPred (npc, loc) -> (match mapLookup ws.worldMap loc with
                | Some (_, npcs) -> mem npc npcs
                | _ -> false
                )
            )
        in Right (CondRes (evalCond cond')));;

let [@warning "-11"] rec questEval q stepNo ws = match q with
    | [] -> Right (stepNo, ws)
    | qstep :: qs -> let recurse = questEval qs (stepNo + 1) in (
        match qstep with
        | ActionExp (act, e) -> (match evalParamExp ws e with
            | Left err -> Left (stepNo, err)
            | Right param -> (match (act, param) with
            | (Require, (CondRes b)) -> if b
                then recurse ws
                else Left (stepNo, "Condition is not satisfied")
            (*The pattern below is left in for backwards compatibility*)
            | (Require, (ItemRes itm)) ->
                if mem itm ws.player.inventory
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
                        | Some npcs' -> (match mapLookup ws.vulnerability npc with
                            | None -> Left (stepNo, "NPC is invincible")
                            | Some vItems -> if exists (fun x -> mem x ws.player.inventory) vItems
                                then recurse
                                    { (unsafeSetNpcsAtPlayerLoc ws npcs') with
                                    charsDead = npc :: ws.charsDead;
                                    charsAlive = filter (fun x -> x <> npc) ws.charsAlive
                                    }
                                else Left (stepNo, "Player cannot kill the NPC")
                            )
                        )
                    )
                )
            | (Use, (ItemRes itm)) -> (match extract ws.player.inventory itm with
                | None -> Left (stepNo, "Required item not held by player")
                | Some newInv -> recurse (updateInventory ws (fun _ -> newInv))
                )
            | _ -> Left (stepNo, "Basic action got the wrong type of input")
            ))
        | LetExp (v, e) -> (match evalParamExp ws e with
            | Left err -> Left (stepNo, err)
            | Right param -> recurse (updateMemory ws (mapAdd (v, param))))
        | RunSubquestExp (sqname, args) -> (match mapLookup ws.subquests sqname with
            | None -> Left (stepNo, "Subquest not found")
            | Some (formalArgs, subq) ->
                let oldMemory = ws.memory in
                let newWSE = (fold_left
                    (fun ws'' (v, e) -> match ws'' with
                        | Left err -> Left err
                        | Right ws' -> (match evalParamExp ws e with
                            | Left err -> Left err
                            | Right param -> Right (updateMemory ws' (mapAdd (v, param)))))
                    (Right ws)
                    (combine formalArgs args)) in
                (match newWSE with
                    | Left err -> Left (stepNo, err)
                    | Right newWS -> (match questEval subq (stepNo + 1) newWS with
                        | Left (stepNo', err) -> Left (stepNo', err)
                        | Right (stepNo', newWS') -> questEval qs stepNo' { newWS' with memory = oldMemory }))
            )
        | _ -> Left (stepNo, "A typing error has occured")
    );;

let evalAST ast = String.concat "" (List.map
    (fun mq -> match buildWorldState ast with
        | Left err -> "Error when validating world declaration: " ^ err ^ "\n"
        | Right ws -> (match questEval mq 0 ws with
            | Left (stepNo, err) -> "Quest invalidation occured at instruction " ^ (string_of_int (stepNo + 1)) ^ ": " ^ err ^ "\n"
            | Right _ -> "Quest was validated successfully!\n"
        )
    ) ast.mainQuests);;

let printEvalAST ast = print_string (evalAST ast);;