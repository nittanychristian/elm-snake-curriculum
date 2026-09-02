-- EAGLE STRIKE — Week 2: Pure Logic + Static Board
--
-- Week 1 functions are still here. This week we add SVG drawing.
-- For the first time the game actually looks like a game.
module Game exposing (main)

import Html exposing (Html, div, h2, p, text)
import Svg exposing (Svg, rect, svg)
import Svg.Attributes exposing (fill, height, stroke, strokeWidth, viewBox, width, x, y)


gridSize : Int
gridSize =
    20


cellSize : Int
cellSize =
    20


-- ── WEEK 1: Pure game logic ───────────────────────────────────────

isInBounds : Int -> Int -> Bool
isInBounds col row =
    col >= 0 && col < gridSize && row >= 0 && row < gridSize


pointValue : Int -> Int
pointValue currentScore =
    if currentScore >= 10 then
        2

    else
        1


statusMessage : Bool -> String
statusMessage alive =
    if alive then
        "Playing"

    else
        "Game Over!"


-- ── WEEK 2: Drawing ──────────────────────────────────────────────

drawCell : String -> Int -> Int -> Svg msg
drawCell color col row =
    rect
        [ x (String.fromInt (col * cellSize))
        , y (String.fromInt (row * cellSize))
        , width (String.fromInt cellSize)
        , height (String.fromInt cellSize)
        , fill color
        , stroke "#222"
        , strokeWidth "0.5"
        ]
        []


drawBoardCell : Int -> Int -> Svg msg
drawBoardCell row col =
    drawCell "#0a1628" col row


drawBoardRow : Int -> List (Svg msg)
drawBoardRow row =
    List.map (drawBoardCell row) (List.range 0 (gridSize - 1))


drawBoard : List (Svg msg)
drawBoard =
    List.concatMap drawBoardRow (List.range 0 (gridSize - 1))


main : Html msg
main =
    div []
        [ h2 [] [ text "Eagle Strike — static board (Week 2)" ]
        , p [] [ text ("Status: " ++ statusMessage True) ]
        , p [] [ text ("Points per food: " ++ String.fromInt (pointValue 3)) ]
        , svg
            [ width (String.fromInt (gridSize * cellSize))
            , height (String.fromInt (gridSize * cellSize))
            , viewBox
                ("0 0 "
                    ++ String.fromInt (gridSize * cellSize)
                    ++ " "
                    ++ String.fromInt (gridSize * cellSize)
                )
            ]
            (drawBoard
                ++ [ drawCell "#22c55e" 9 10   -- body
                   , drawCell "#22c55e" 8 10   -- body
                   , drawCell "#f0ede0" 10 10  -- head (eagle white)
                   , drawCell "#dc2626" 5 5    -- food (prey)
                   ]
            )
        ]
