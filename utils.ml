open List;;

(* This module only contains some utility functions *)

let rec mapRm m x = match m with
    | [] -> []
    | ((x', y) :: rest) -> if x = x' then mapRm rest x else ((x', y) :: (mapRm rest x));;

let mapAdd (x, y) m = ((x, y) :: (mapRm m x));;

let rec mapUpdate m x f y = match m with
    | [] -> [ (x, y) ]
    | ((x', y) :: rest) -> if x = x' then ((x', f y) :: rest) else ((x', y) :: (mapUpdate rest x f y));;

let rec mapLookup m x = match m with
    | [] -> None
    | ((x', y) :: rest) -> if x = x' then Some y else (mapLookup rest x);;

let rec mapExtract l x = match l with
    | [] -> None
    | ((x', y) :: rest) -> if x' = x then Some (y, rest) else (
        match mapExtract rest x with
        | None -> None
        | Some (y', rest') -> Some (y', (x', y) :: rest')
    );;

let rec extract l x = match l with
    | [] -> None
    | (x' :: rest) -> if x' = x then Some rest else (
        match extract rest x with
        | None -> None
        | Some rest' -> Some (x' :: rest')
    );;