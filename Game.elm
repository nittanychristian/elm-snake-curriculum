-- EAGLE STRIKE — Week 1: Pure Game Logic
--
-- No display yet — just the functions that will power the game.
-- Each week we add a new layer until we have a complete game.
-- Load this in Ellie to see the functions working.
module Game exposing (main)

import Html exposing (Html, div, h2, p, text)


gridSize : Int
gridSize =
    20


-- Is this grid position inside the board?
isInBounds : Int -> Int -> Bool
isInBounds col row =
    col >= 0 && col < gridSize && row >= 0 && row < gridSize


-- Points earned per food item eaten
pointValue : Int -> Int
pointValue currentScore =
    if currentScore >= 10 then
        2
    else
        1


-- Text to show the player based on game state
statusMessage : Bool -> String
statusMessage alive =
    if alive then
        "Playing"
    else
        "Game Over!"


-- Direction as a String for now.
-- Notice the problem: nothing stops us from writing "Diagonal" by mistake.
-- We'll fix this in Week 3 with a proper custom type.
describeMove : String -> String
describeMove direction =
    case direction of
        "Up" ->
            "The eagle flies north"

        "Down" ->
            "The eagle dives south"

        "Left" ->
            "The eagle banks left"

        "Right" ->
            "The eagle banks right"

        _ ->
            "Unknown direction"


showBool : Bool -> String
showBool b =
    if b then
        "True"

    else
        "False"


main : Html msg
main =
    div []
        [ h2 [] [ text "Eagle Strike — game logic (Week 1)" ]
        , p [] [ text ("Grid size: " ++ String.fromInt gridSize ++ " x " ++ String.fromInt gridSize) ]
        , p [] [ text ("isInBounds 5 5 = " ++ showBool (isInBounds 5 5)) ]
        , p [] [ text ("isInBounds 25 5 = " ++ showBool (isInBounds 25 5)) ]
        , p [] [ text ("isInBounds -1 10 = " ++ showBool (isInBounds -1 10)) ]
        , p [] [ text ("pointValue 3 = " ++ String.fromInt (pointValue 3)) ]
        , p [] [ text ("pointValue 15 = " ++ String.fromInt (pointValue 15)) ]
        , p [] [ text ("statusMessage True = " ++ statusMessage True) ]
        , p [] [ text ("statusMessage False = " ++ statusMessage False) ]
        , p [] [ text ("describeMove \"Up\" = " ++ describeMove "Up") ]
        , p [] [ text ("describeMove \"Left\" = " ++ describeMove "Left") ]
        ]
