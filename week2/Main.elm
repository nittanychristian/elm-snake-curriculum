module Main exposing (main)

import Html exposing (Html)
import Svg exposing (Svg, circle, rect, svg)
import Svg.Attributes exposing (cx, cy, fill, height, r, stroke, strokeWidth, viewBox, width, x, y)


cellSize : Int
cellSize =
    20


gridSize : Int
gridSize =
    20


-- Draw a single cell at grid coordinates (col, row)
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


-- Draw one full row by mapping over column indices
drawRow : Int -> List (Svg msg)
drawRow row =
    List.map (\col -> drawCell "#1a1a2e" col row) (List.range 0 (gridSize - 1))


-- Draw the full board: map over row indices, flatten the results
drawBoard : List (Svg msg)
drawBoard =
    List.concatMap drawRow (List.range 0 (gridSize - 1))


main : Html msg
main =
    svg
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
            ++ [ drawCell "#4ade80" 10 10  -- snake head
               , drawCell "#f87171" 5 5    -- food
               ]
        )
