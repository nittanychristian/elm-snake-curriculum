module Solution exposing (main)

import Html exposing (Html)
import Svg exposing (Svg, circle, rect, svg, text_, text)
import Svg.Attributes exposing (cx, cy, fill, fontSize, height, r, stroke, strokeWidth, textAnchor, viewBox, width, x, y)


cellSize : Int
cellSize =
    20


gridSize : Int
gridSize =
    20


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


drawRow : Int -> List (Svg msg)
drawRow row =
    List.map (\col -> drawCell "#1a1a2e" col row) (List.range 0 (gridSize - 1))


drawBoard : List (Svg msg)
drawBoard =
    List.concatMap drawRow (List.range 0 (gridSize - 1))


-- Students often reach the stretch: drawing the full grid themselves,
-- placing the snake head, food, and maybe a starting body segment.
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
            ++ [ -- Snake body
                 drawCell "#22c55e" 8 10
               , drawCell "#22c55e" 9 10
               , -- Snake head
                 drawCell "#4ade80" 10 10
               , -- Food
                 drawCell "#f87171" 5 5
               ]
        )
