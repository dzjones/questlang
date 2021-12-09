(* Utils *)
let rec mapRm m x = match m with
    | [] -> []
    | ((x', y) :: rest) -> if x = x' then mapRm rest x else ((x', y) :: (mapRm rest x))

let mapAdd m x y = ((x, y) :: (mapRm m x))

let rec mapUpdate m x f y = match m with
    | [] -> [ (x, y) ]
    | ((x', y) :: rest) -> if x = x' then ((x', f y) :: rest) else ((x', y) :: (mapUpdate rest x f y))

let contains l x = exists (fun x' -> x' = x) l

let rec mapLookup m x = match m with
    | [] -> None
    | ((x', y) :: rest) -> if x = x' then Some y else (mapLookup rest x)

let rec mapExtract l x = match l with
    | [] -> None
    | ((x', y) :: rest) -> if x' = x then Some (y, rest) else (
        match mapExtract rest x with
        | None -> None
        | Some (y', rest') -> Some (y', (x', y) :: rest')
    )

let rec extract l x = match l with
    | [] -> None
    | (x' :: rest) -> if x' = x then Some rest else (
        match extract rest x with
        | None -> None
        | Some rest' -> Some (x' :: rest')
    )



type paramRes =
    | LocationRes of locatonId
    | ItemRes of itemId
    | CharRes of characterId

type playerType = {
    inventory : itemId list
    location : locationId
}

type locMap = (locationId * ((itemId list) * (characterId list) * bool)) list

type worldState = {
    charsAlive : characterId list
    charsDead : characterId list
    player : playerType
    worldMap : locMap
    subquests : subquestEntry list
    memory : (var * paramRes) list
}

let lookupPlayerLoc ws = mapLookup ws.worldMap ws.player.location
let unsafeSetItemsAtPlayerLoc ws items = { ws with
    worldMap = mapUpdate ws.worldMap ws.player.location (fun (_, npcs) -> (items, npcs)) ([], [])
}
let unsafeSetNpcsAtPlayerLoc ws npcs = { ws with
    worldMap = mapUpdate ws.worldMap ws.player.location (fun (items, _) -> (items, npcs)) ([], [])
}


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
}

let rec populateWorldState worldData world = match worldData with
    | [] -> world
    | worldE :: worldData' -> populateWorldState worldData' ( match worldE with
        | CharWorldEntry (chr, loc) -> (match chr with
            | PlayerC -> { world with player = (match world.player.location with
                | NullLocation -> { world.player with location = loc }
                | _ -> raise (Failure "Error: Player's starting location was set twice")) }
            | NPCLiteral npc -> { world with
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
    )

let buildWorldState ast =
    let populated = populateWorldState ast.world emptyWorldState in
    { populated with subquests = ast.subquests }

let evalParamExp ws e = match e with
    | LocationExp loc -> LocationRes loc
    | ItemExp item -> ItemRes item
    | CharExp c -> CharRes c
    | VarExp v -> (match mapLookup ws.memory v with
        | None -> raise (Failure "Error: variable lookup failed")
        | Some r -> r
        )
    | GetCharLoc c -> (match c with
        | PlayerC -> ws.player.location
        | NPCLiteral npc -> raise (Failure "Not yet implemented")
        )
    | GetItemLoc item -> raise (Failure "Not yet implemented")

let rec questEval q ws stepNo = match q with
    | [] -> Right ws
    | qstep :: qs -> let recurse = questEval sq in
                     let nextStep = stepNo + 1 in (
        match qstep with
        | ActionExp (act, e) -> (match (act, evalParamExp e) with
            | (Require, (ItemRes itm)) ->
                if contains ws.player.inventory itm
                    then recurse ws nextStep
                    else Left (stepNo, "Required item not held by player")
            | (Goto, (LocationRes loc)) -> recurse { ws with player = { ws.player with location = loc } } nextStep
            | (Get, (ItemRes itm)) -> (match lookupPlayerLoc ws with
                | None -> Left (stepNo, "Player is at an invalid location")
                | Some (items, _) -> (match extract items itm with
                    | None -> Left (stepNo, "Item does not exist at player's location")
                    | Some items' -> recurse { (unsafeSetItemsAtPlayerLoc ws items') with
                        player = { ws.player with inventory = itm :: ws.player.inventory };
                        } nextStep
                    )
                )
            | (Kill, (CharRes c)) -> (match c with
                | PlayerC -> Left (stepNo, "The player character cannot kill themselves")
                | NPCLiteral npc -> (match lookupPlayerLoc ws with
                    | None -> Left (stepNo, "Player is at an invalid location")
                    | Some (_, npcs) -> (match extract npcs npc with
                        | None -> Left (stepNo, "NPC does not exist at player's location")
                        | Some npcs' -> recurse (unsafeSetNpcsAtPlayerLoc ws npcs') nextStep
                        )
                    )
                )
            | (Interact, (ItemRes itm)) -> (match extract ws.player.inventory itm with
                | None -> Left (stepNo, "Required item not held by player")
                | Some newInv -> recurse { ws with player = { ws.player with inventory = newInv } } nextStep
                )
            )
        | LetExp (v, e) -> raise (Failure "Not yet implemented")
        | RunSubquestExp (sq, args) -> raise (Failure "Not yet implemented")
        | _ -> Left (stepNo, "Basic action got the wrong type of input")
    )

let astEval ast = match questEval ast.mainQuest (buildWorldState ast) 0 with
    | Left (stepNo, err) -> "Quest invalidation occured at instruction " ^ (string_of_int stepNo) ^ ": " ^ err
    | Right _ -> "Quest was validated successfully!"