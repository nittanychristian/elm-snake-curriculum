-- Eagle Strike — Week 5 solution with school colors (blue & green) and eagle mascot.
-- Changes from Week 4:
--   - School color scheme: navy board, green body, white eagle head, gold beak
--   - Embedded head SVG rotates in the direction of travel
--   - Renamed: "Eagle Strike", score says "Prey caught"
--   - "GO EAGLES!" on game over
--   - Restart on R key (high score preserved)
--   - Wrap-around walls instead of game over on wall hit
--   - Speed increases with score


module Game exposing (main)

import Browser
import Browser.Events exposing (onKeyDown)
import Html exposing (Html, div, h1, p, text)
import Html.Attributes exposing (style)
import Json.Decode as Decode
import Svg exposing (Svg, rect, svg)
import Svg.Attributes as SA
import Time


cellSize : Int
cellSize =
    20


gridSize : Int
gridSize =
    20


type Direction
    = Up
    | Down
    | Left
    | Right


type GameStatus
    = Playing
    | GameOver


type alias Position =
    { x : Int, y : Int }


type alias Model =
    { head : Position
    , body : List Position
    , direction : Direction
    , food : Position
    , score : Int
    , highScore : Int
    , status : GameStatus
    }


initialModel : Model
initialModel =
    { head = { x = 10, y = 10 }
    , body = [ { x = 9, y = 10 }, { x = 8, y = 10 } ]
    , direction = Right
    , food = { x = 5, y = 5 }
    , score = 0
    , highScore = 0
    , status = Playing
    }


type Msg
    = Tick Time.Posix
    | KeyPressed Direction
    | Restart
    | Ignore



-- GAME LOGIC --


nextHead : Direction -> Position -> Position
nextHead dir pos =
    case dir of
        Up ->
            { pos | y = modBy gridSize (pos.y - 1) }

        Down ->
            { pos | y = modBy gridSize (pos.y + 1) }

        Left ->
            { pos | x = modBy gridSize (pos.x - 1) }

        Right ->
            { pos | x = modBy gridSize (pos.x + 1) }


hitsItself : Position -> List Position -> Bool
hitsItself head body =
    List.member head body


respawnFood : Position -> Position
respawnFood current =
    { x = modBy gridSize (current.x * 7 + 3)
    , y = modBy gridSize (current.y * 13 + 7)
    }


isOpposite : Direction -> Direction -> Bool
isOpposite a b =
    case ( a, b ) of
        ( Up, Down ) ->
            True

        ( Down, Up ) ->
            True

        ( Left, Right ) ->
            True

        ( Right, Left ) ->
            True

        _ ->
            False


tickGame : Model -> Model
tickGame model =
    case model.status of
        GameOver ->
            model

        Playing ->
            let
                newHead =
                    nextHead model.direction model.head

                ateFood =
                    newHead == model.food

                newBody =
                    if ateFood then
                        model.head :: model.body

                    else
                        model.head :: List.take (List.length model.body - 1) model.body

                newFood =
                    if ateFood then
                        respawnFood model.food

                    else
                        model.food

                newScore =
                    if ateFood then
                        model.score + 1

                    else
                        model.score

                newStatus =
                    if hitsItself newHead model.body then
                        GameOver

                    else
                        Playing
            in
            { model
                | head = newHead
                , body = newBody
                , food = newFood
                , score = newScore
                , highScore = max model.highScore newScore
                , status = newStatus
            }



-- UPDATE --


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick _ ->
            ( tickGame model, Cmd.none )

        KeyPressed dir ->
            if isOpposite model.direction dir then
                ( model, Cmd.none )

            else
                ( { model | direction = dir }, Cmd.none )

        Restart ->
            ( { initialModel | highScore = model.highScore }, Cmd.none )

        Ignore ->
            ( model, Cmd.none )



-- VIEW --


drawCell : String -> Position -> Svg msg
drawCell color pos =
    rect
        [ SA.x (String.fromInt (pos.x * cellSize))
        , SA.y (String.fromInt (pos.y * cellSize))
        , SA.width (String.fromInt cellSize)
        , SA.height (String.fromInt cellSize)
        , SA.fill color
        , SA.rx "3"
        ]
        []


headIcon : String
headIcon =
    "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB4bWxuczpzdmc9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48dGl0bGU+ZHJhZ29uPC90aXRsZT48ZyBjbGFzcz0ibGF5ZXIiPjx0aXRsZT5MYXllciAxPC90aXRsZT48cGF0aCBmaWxsPSIjMDBmZjAwIiBzdHJva2U9IiMwMDAwMDAiIHN0cm9rZS13aWR0aD0iNSIgaWQ9InN2Z18yIiBkPSJtNjEsMzFjMS4wNiwwLjY1IDEuOCwwLjk4IDIuNywxYzAuODYsMC4wMiAxLjQxLDAuNjggMi4xLDEuMDhjMC44MywwLjQ4IDEuMjgsMS4zMSAyLjIsMS43NWMwLjY1LDAuMzEgMS42NSwwLjE1IDIuNDgsMC40NWMwLjcxLDAuMjUgMS42MywwLjY3IDIuNjIsMC43MmMwLjksMC4wNCAxLjQ1LDAuNDUgMi4xOSwwLjkxYzAuNjksMC40NCAxLjczLC0wLjAxIDIuNDcsMC4xNGMwLjkzLDAuMTkgMS42NCwwLjY1IDIuNjQsMS4xNGMwLjU4LDAuMjggMS42MiwwLjU2IDIuNCwwLjg5YzAuNzUsMC4zMSAxLjUzLDAuNjkgMi40LDAuOTJjMC44LDAuMjEgMS4zOCwwLjcgMi4xOSwxLjAxYzAuNzQsMC4yOCAwLjg0LDEuNSAxLjcxLDEuODdjMC44NCwwLjM1IDEuNTEsMC40OCAyLjE5LDEuMDRjMC42NywwLjU2IDEuNDgsMC43MyAyLjEsMS40OGMwLjU1LDAuNjYgMC44NCwxLjU2IDEuMjYsMi4zYzAuNDIsMC43NSAxLjE3LDEuMjkgMS4zNSwyLjA2YzAuMiwwLjg3IDAsMS43NSAwLDIuNzJjMCwwLjgyIDAuMzksMS42NiAwLjcyLDIuMzJjMC40MiwwLjg0IDAuMjgsMS44IDAuMjgsMi43YzAsMC45IDAsMS44IDAsMi43YzAsMC45NyAtMC4yMywxLjc2IC0wLjY1LDIuNWMtMC40MywwLjc2IC0wLjcsMS42MSAtMS4zNSwyLjNjLTAuNTksMC42MSAtMS4xNywxLjI0IC0xLjc2LDEuN2MtMC44NSwwLjY3IC0xLjY0LDEuMDEgLTIuMjIsMS42MmMtMC41OCwwLjYxIC0xLjE4LDEuMzYgLTIsMS42NmMtMC44NSwwLjMxIC0xLjQ3LDAuOTggLTIsMS41MmMtMC40NywwLjQ4IC0xLjM3LDAuNDMgLTIsMC45M2MtMC42MiwwLjQ5IC0xLjUxLDAuNTcgLTIuMjQsMC41N2MtMC45OSwwIC0xLjc3LDAgLTIuNzcsMGMtMS4wMiwwIC0xLjgyLDAgLTIuNzIsMGMtMC45LDAgLTEuNzIsLTAuMDkgLTIuMzMsLTAuNTdjLTAuNjIsLTAuNSAtMS41NywtMC40MyAtMi40NSwtMC40M2MtMC45NiwwIC0xLjgyLDAgLTIuNzIsMGMtMC45LDAgLTEuOCwwIC0yLjYsMGMtMC45LDAgLTEuNzUsLTAuMDIgLTIuNzQsMC4yMmMtMC43MiwwLjE3IC0xLjQzLDAuNTEgLTIuNDksMC42OWMtMC45NiwwLjE3IC0xLjc3LDAuMDkgLTIuNjcsMC4wOWMtMC45LDAgLTEuOCwwIC0yLjcsMGwtMC45LDBsLTAuOSwwbC0wLjksMCIvPjxwYXRoIGZpbGw9IiNmZjAwMDAiIHN0cm9rZT0iIzAwMDAwMCIgc3Ryb2tlLXdpZHRoPSI1IiBpZD0ic3ZnXzMiIGQ9Im01NSwyM2MtMC4xNywtMC44MyAtMS4wMywtMS4xMyAtMS42LC0xLjYxYy0wLjc1LC0wLjY0IC0xLjQsLTEuMzkgLTEuOSwtMS44OWMtMC43LC0wLjcgLTAuOTgsLTEuNDQgLTEuNTUsLTIuMTRjLTAuNTksLTAuNzMgLTEuMjUsLTEuMTggLTIuMDUsLTEuMzZjLTAuODQsLTAuMTkgLTEuMzUsLTAuODQgLTIuMDksLTEuMDNjLTEuMDcsLTAuMjcgLTEuODUsLTAuNzIgLTIuNTEsLTEuMDNjLTAuODQsLTAuMzkgLTEuMDMsLTEuMzEgLTEuMzMsLTIuMDljLTAuMzQsLTAuOSAtMS4zNiwtMC44NyAtMS45NywtMS4zNmMtMC42MSwtMC40OSAtMS4zOSwtMC43MyAtMi4wNSwtMS4xNWMtMC42OCwtMC40MyAtMC43NiwwLjcyIC0xLjEyLDEuNGMtMC40NywwLjg4IC0xLjM3LDEuMjUgLTEuNzcsMS43Yy0wLjc4LDAuODkgLTAuOTQsMS43NiAtMS4xLDIuNTNjLTAuMjIsMS4wNSAtMC42OSwxLjczIC0wLjksMi42N2MtMC4xNywwLjczIC0wLjM0LDEuNzQgLTAuNjMsMi41MWMtMC4zMSwwLjgxIC0wLjkxLDEuNDQgLTEuMzQsMi4xMmMtMC41MSwwLjc5IDAuMTcsMS45NCAtMC4zMSwyLjU5Yy0wLjUxLDAuNyAtMC43OCwxLjMyIC0wLjc4LDIuMjJjMCwwLjkgMCwxLjcgMCwyLjY2YzAsMC45IC0wLjE3LDEuNzggMC4wMiwyLjcyYzAuMTgsMC44NyAwLjY3LDEuNDEgMC45NiwyLjM1YzAuMzIsMS4wMiAwLjk1LDEuNDcgMS40NSwyLjA2YzAuNTgsMC42OSAwLjYyLDEuNzQgMS4yOCwyLjM2YzAuNjEsMC41NyAxLjY3LDAuOTggMi4yNiwxLjI0YzAuOTgsMC40MyAxLjc5LDAuNTQgMi42NywwLjg3YzAuNzEsMC4yNyAxLjY1LDAuNDYgMi41NSwwLjkzYzAuNjYsMC4zNCAxLjUsMC42NiAyLjMsMC4yMmMwLjgsLTAuNDQgMS44LC0wLjMxIDIuNDIsLTAuNzhjMC42OCwtMC41MiAwLjk3LC0xLjMgMS40NCwtMi4wMmMwLjUzLC0wLjc5IDEuMjUsLTEuMzUgMS45NiwtMS44YzAuNjcsLTAuNDIgMS42OCwtMC43MSAyLjQ2LC0wLjg3YzAuOTksLTAuMjEgMS4yMiwtMS4wMyAxLjIyLC0xLjgzYzAsLTAuOSAwLjE5LC0xLjY5IDAuNzIsLTIuMjhjMC41NCwtMC42IDAuOTUsLTEuMzkgMS42NywtMS44OWMwLjY3LC0wLjQ3IDEuMiwtMS4zNCAxLjQ5LC0yLjEzYzAuMzIsLTAuODUgLTAuMTYsLTEuNTggLTAuODgsLTIuMjNjLTAuNDksLTAuNDQgLTAuOTUsLTEuNTUgLTEuNDEsLTIuMDNjLTAuNjgsLTAuNzEgLTEuNDMsLTEuMDUgLTIuMDUsLTEuMzRjLTAuOTUsLTAuNDMgLTEuNzcsLTAuNjkgLTIuNTksLTFjLTEuMDMsLTAuMzkgLTEuNzMsLTAuNjYgLTIuNDcsLTEuMWMtMC44OSwtMC41NCAtMS42NiwtMC45OSAtMi40NywtMS4yYy0wLjg3LC0wLjIzIC0xLjQ0LC0wLjk2IC0xLjIyLC0xbDAuOSwwIi8+PHBhdGggZmlsbD0iI2ZmZmYwMCIgc3Ryb2tlPSIjMDAwMDAwIiBzdHJva2Utd2lkdGg9IjUiIGlkPSJzdmdfNCIgZD0ibTUyLDY5Yy0wLjkxLDAuMjkgLTAuOTUsMS4xIC0xLDJjLTAuMDQsMC44IC0wLjY3LDEuNDcgLTEuMzksMS45N2MtMC42NiwwLjQ2IC0wLjY4LDEuNDYgLTEuMTksMi4wNWMtMC41NCwwLjYzIC0wLjkxLDEuNDkgLTEuMzcsMi4yN2MtMC4zOSwwLjY2IC0xLjQsMC44OCAtMS44OSwxLjdjLTAuMzgsMC42NSAtMC45NCwxLjI3IC0xLjM5LDIuMWMtMC4zNSwwLjY1IC0wLjg5LDEuMzcgLTEuNDMsMS45NWMtMC41NywwLjYyIC0wLjkzLDEuNDMgLTEuNTQsMi4xNmMtMC42NSwwLjc4IC0xLjA1LDEuMzkgLTEuNTEsMi4xM2MtMC40OSwwLjc4IC0wLjk2LDEuNDggLTEuMzYsMi4zNmMtMC4zMywwLjczIC0xLjE1LDEuMzIgLTEuNTksMmMtMC41MSwwLjc5IC0wLjk2LDEuMzkgLTEuNTIsMi4wNmMtMC42NCwwLjc2IC0xLjM0LDEuMjQgLTEuODMsMS41M2MtMSwwLjU5IC0yLjA0LDAuNTQgLTIuOCwwLjhjLTAuNzUsMC4yNiAtMS40OSwwLjkxIC0yLjQsMC45MWMtMC45LDAgLTEuOCwwIC0yLjYsMGMtMC45MSwwIC0xLjgxLDAuMDEgLTIuNywwYy0wLjksLTAuMDEgLTEuNjEsLTAuNDQgLTIuMSwtMS4xOWMtMC41MSwtMC43OSAtMC45OSwtMS4zOSAtMS45LC0xLjgxYy0wLjc5LC0wLjM3IC0xLjA5LC0xLjE1IC0xLjY3LC0xLjgzYy0wLjU3LC0wLjY3IC0xLjMxLC0wLjkyIC0yLjEzLC0xLjE3Yy0wLjc2LC0wLjI0IC0xLjI0LC0wLjk2IC0yLjAxLC0xLjM1Yy0wLjg4LC0wLjQ0IC0xLjc5LC0wLjQyIC0yLjUzLC0wLjkzYy0wLjY5LC0wLjQ4IC0xLjE3LC0xLjA1IC0xLjE3LC0xLjljMCwtMC45MyAwLjI1LC0xLjkxIC0wLjE3LC0yLjYxYy0wLjQ2LC0wLjc4IC0xLjQ2LC0wLjY3IC0yLjI5LC0xLjJjLTAuNjgsLTAuNDQgLTAuNDgsLTEuNzcgLTEuMTksLTJjLTAuODMsLTAuMjcgLTIuMDcsMC4xMSAtMi4zNCwtMC42MmMtMC4zMiwtMC44MyAtMC4wMSwtMS43OSAtMC4wMSwtMi42OWMwLC0wLjkgLTAuNjEsLTEuNDQgLTAuOTYsLTIuMTVjLTAuMzksLTAuNzggLTAuMDEsLTEuNzIgLTAuNDYsLTIuNWMtMC40NiwtMC44IC0wLjIzLC0xLjY0IC0wLjYsLTIuNTFjLTAuMzEsLTAuNzMgLTEuNDcsLTEuMTUgLTEuOTgsLTQuOThjLTAuMTMsLTAuOTYgMCwtMS44NiAwLC0yLjc2YzAsLTAuOSAtMC4wMywtMS44IDAsLTIuNmMwLjAzLC0wLjkgMC40MSwtMS42MSAwLjkxLC0yLjRjMS45NiwtMy4xMSAyLjQxLC0zLjgzIDIuOCwtNC42YzAuNCwtMC43OSAwLjU5LC0xLjc4IDAuMjcsLTIuNTljLTAuMzEsLTAuNzkgLTAuOTgsLTEuMzIgLTAuOTksLTIuMjFjLTAuMDEsLTAuOSAtMC41NCwtMS42IC0wLjg4LC0yLjVjLTAuMzIsLTAuODUgMC4yNCwtMS44MSAtMC4xOCwtMi41NGMtMC40NywtMC44MSAtMC4yOSwtOS4zIDAuMTEsLTEwYzAuNDcsLTAuODEgMC43OCwtMS40IDEuMDMsLTIuMTZjMC4yNiwtMC43OSAwLjcyLC0xLjcxIDAuOTQsLTIuMzRjMC4zMywtMC45NCAxLjIzLC0xLjQgMS41NCwtMi4wNWMwLjQzLC0wLjkgMC4zNiwtMS45MiAwLjQ0LC0yLjc2YzAuMDgsLTAuOSAwLjk0LC0xLjI3IDEsLTIuMTVjMC4wNiwtMC45IC0wLjAyLC0xLjgyIDAsLTIuNmMwLjAzLC0wLjk0IDAuNDMsLTEuNjYgMS4yMiwtMi4xN2MwLjczLC0wLjQ3IDEuMzksMC4zOSAyLjE0LDAuODJjMC43MywwLjQyIDEuNDcsMC41NCAyLjE2LDEuMDZjMC42OSwwLjUxIDEuNjIsMC43OCAyLjI4LDEuMDhjMC44NywwLjQgMS40LDEuMTIgMiwxLjcyYzAuNjksMC42OCAxLjU1LDEuMDggMi4xNywxLjYzYzAuNTgsMC41IDEuNSwwLjQ5IDIuMjMsMC44NmMwLjY2LDAuMzQgMS41NywwLjkxIDIuMjgsMS4yMWMwLjY3LDAuMjkgMS40NiwxLjE3IDIuMTcsMS41M2MwLjc4LDAuMzkgMS41NywwLjQ1IDIuNTksMC45MmMwLjc0LDAuMzQgMS40NCwwLjg3IDEuNzUsMS42NmMwLjMyLDAuODEgMC43OSwxLjMzIDEuMDEsMi4xMWMwLjI0LDAuODYgMC4xMiwxLjc2IDAuNjUsMi4zNGMwLjYzLDAuNjkgMS4xMiwxLjI2IDEuNzEsMS44OWMwLjUzLDAuNTggMS4wOCwxLjIyIDEuNywxLjdjMC43MSwwLjU1IDEuNzcsLTAuMDYgMi41OSwwLjQxYzAuNjksMC4zOSAwLjksMS4xOSAxLjUyLDEuNzhjMC42MiwwLjU4IDEuMzgsMC42MiAyLjEyLDEuMDhjMC43OCwwLjQ5IDEuODcsLTAuMSAyLjcxLDAuMjVjMC42NywwLjI4IDEuNDgsMC44MiAyLjM2LDAuODNjMC44NCwwLjAxIDEuODIsMC4xIDIuNjQsMGMwLjksLTAuMTEgMS4yOCwtMC45NiAyLjIsLTFjMC45LC0wLjA0IDEuOCwwIDIuNTYsMGMwLjg5LDAgMS43OSwtMC4yNyAyLjQxLC0wLjgzYzAuNjUsLTAuNTkgMS4wMiwtMS4yOSAxLjU0LC0xLjg3YzAuNjYsLTAuNzMgMS40LC0xLjEyIDIuMzIsLTEuM2MwLjg3LC0wLjE3IDAuOTcsLTEuMSAwLjk3LC0yYzAsLTAuOCAwLjQsLTEuODEgLTAuMDQsLTIuNTZjLTAuNCwtMC43IC0wLjk2LDAuMTcgLTAuOTYsMS4wNmMwLDAuOSAwLDEuOCAwLDIuN2MwLDAuOSAtMC4wNCwxLjggMCwyLjZjMC4wNCwwLjkyIDAuOTQsMS40MiAxLDIuM2MwLjA2LDAuODcgLTAuNCwxLjg0IDAuMDksMi42MWMwLjQ2LDAuNzQgMC45MSwxLjI5IDAuOTEsMi4wOWMwLDEuMDMgMCwxLjgxIDAsMi43NmMwLDAuODcgMCwxLjc0IDAsMi42NGMwLDAuOSAwLDEuOCAwLDIuNmMwLDAuOSAwLDEuOCAwLDIuNzZjMCwwLjg3IDAuMTQsMS43OSAtMC4yOCwyLjY0Yy0wLjMzLDAuNjYgLTAuODEsMS40OSAtMS41MiwxLjg4Yy0wLjczLDAuNDEgLTEuNTEsMS4wMyAtMi4yMiwxLjQyYy0wLjk3LDAuNTIgLTEuNTgsMC44IC0yLjM4LDEuMmMtMC44LDAuNCAtMS41LDAuOTQgLTIuNDksMS4yNGMtMC43OSwwLjI1IC0xLjc5LDAuNDkgLTIuMDYsMS4zNmMtMC4yNywwLjg2IC0wLjY3LDEuNDQgLTEuMDIsMi4xNGMtMC4zOSwwLjc3IC0wLjA2LDEuNzYgLTAuMDQsMi42NmMwLjAzLDAuOSAxLDAuOSAxLjcsMC45NmwwLjc4LDAuNDZsMC40NywwLjc3Ii8+PC9nPjwvc3ZnPg=="



-- Keep the right-facing artwork upright horizontally; turn around the cell center.


drawEagleHead : Direction -> Position -> List (Svg msg)
drawEagleHead dir pos =
    let
        px =
            pos.x * cellSize

        py =
            pos.y * cellSize

        orientation =
            case dir of
                Right ->
                    "scale(1 1)"

                Left ->
                    "scale(-1 1)"

                Up ->
                    "rotate(-90)"

                Down ->
                    "rotate(90)"
    in
    [ Svg.g
        [ SA.transform
            ("translate("
                ++ String.fromInt (px + cellSize // 2)
                ++ " "
                ++ String.fromInt (py + cellSize // 2)
                ++ ") "
                ++ orientation
            )
        ]
        [ Svg.image
            [ SA.xlinkHref headIcon
            , SA.x (String.fromInt (negate cellSize // 2))
            , SA.y (String.fromInt (negate cellSize // 2))
            , SA.width (String.fromInt cellSize)
            , SA.height (String.fromInt cellSize)
            ]
            []
        ]
    ]


drawBoard : List (Svg msg)
drawBoard =
    List.concatMap
        (\row ->
            List.map
                (\col -> drawCell "#0a1628" { x = col, y = row })
                (List.range 0 (gridSize - 1))
        )
        (List.range 0 (gridSize - 1))


view : Model -> Html Msg
view model =
    let
        statusText =
            case model.status of
                GameOver ->
                    [ p
                        [ style "color" "#eab308"
                        , style "font-size" "22px"
                        , style "margin" "8px 0 2px 0"
                        , style "text-align" "center"
                        ]
                        [ text "GO EAGLES!" ]
                    , p
                        [ style "color" "#94a3b8"
                        , style "font-size" "14px"
                        , style "margin" "0"
                        , style "text-align" "center"
                        ]
                        [ text "press R to fly again" ]
                    ]

                Playing ->
                    []
    in
    div
        [ style "font-family" "monospace"
        , style "background" "#0a1628"
        , style "padding" "16px"
        , style "display" "inline-block"
        , style "border" "3px solid #1d4ed8"
        , style "border-radius" "10px"
        ]
        ([ h1
            [ style "color" "#16a34a"
            , style "margin" "0 0 8px 0"
            , style "font-size" "20px"
            , style "text-align" "center"
            , style "letter-spacing" "2px"
            ]
            [ text "EAGLE STRIKE" ]
         , div
            [ style "display" "flex"
            , style "justify-content" "space-between"
            , style "margin-bottom" "8px"
            ]
            [ p [ style "color" "#16a34a", style "margin" "0" ]
                [ text ("Prey caught: " ++ String.fromInt model.score) ]
            , p [ style "color" "#1d4ed8", style "margin" "0" ]
                [ text ("Best: " ++ String.fromInt model.highScore) ]
            ]
         , svg
            [ SA.width (String.fromInt (gridSize * cellSize))
            , SA.height (String.fromInt (gridSize * cellSize))
            ]
            (drawBoard
                ++ List.map (drawCell "#15803d") model.body
                ++ drawEagleHead model.direction model.head
                ++ [ drawCell "#dc2626" model.food ]
            )
         ]
            ++ statusText
        )



-- SUBSCRIPTIONS --


keyDecoder : Decode.Decoder Msg
keyDecoder =
    Decode.map toMsg (Decode.field "key" Decode.string)


toMsg : String -> Msg
toMsg key =
    case key of
        "ArrowUp" ->
            KeyPressed Up

        "ArrowDown" ->
            KeyPressed Down

        "ArrowLeft" ->
            KeyPressed Left

        "ArrowRight" ->
            KeyPressed Right

        "r" ->
            Restart

        "R" ->
            Restart

        _ ->
            Ignore


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Time.every (toFloat (max 80 (200 - model.score * 10))) Tick
        , onKeyDown keyDecoder
        ]


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( initialModel, Cmd.none )
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
