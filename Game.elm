-- EAGLE STRIKE — Week 4: Complete Game
--
-- All four weeks of concepts in one file:
--   Week 1 — pure logic functions (isInBounds, pointValue, respawnFood)
--   Week 2 — SVG drawing (drawCell, drawBoard)
--   Week 3 — Elm Architecture + Direction type + timer (Model, Msg, update, subscriptions)
--   Week 4 — Body as List, collision detection, food, score, game over
module Game exposing (main)

import Browser
import Browser.Events exposing (onKeyDown)
import Html exposing (Html, div, p, text)
import Html.Attributes exposing (style)
import Json.Decode as Decode
import Svg exposing (Svg, rect, svg)
import Svg.Attributes as SA
import Time


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


-- ── WEEK 2: Drawing ──────────────────────────────────────────────

drawCell : String -> { x : Int, y : Int } -> Svg msg
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


drawBoardCell : Int -> Int -> Svg msg
drawBoardCell row col =
    drawCell "#0a1628" { x = col, y = row }


drawBoardRow : Int -> List (Svg msg)
drawBoardRow row =
    List.map (drawBoardCell row) (List.range 0 (gridSize - 1))


drawBoard : List (Svg msg)
drawBoard =
    List.concatMap drawBoardRow (List.range 0 (gridSize - 1))


-- ── WEEK 3: Direction type + model ──────────────────────────────────

type Direction
    = Up
    | Down
    | Left
    | Right


type alias Position =
    { x : Int, y : Int }


-- ── WEEK 4: Game status type + full model ────────────────────────

type GameStatus
    = Playing
    | GameOver


type alias Model =
    { head : Position
    , body : List Position      -- Week 4: body is a List
    , direction : Direction
    , food : Position
    , score : Int
    , status : GameStatus       -- Week 4: track game over state
    }


initialModel : Model
initialModel =
    { head = { x = 10, y = 10 }
    , body = [ { x = 9, y = 10 }, { x = 8, y = 10 } ]
    , direction = Right
    , food = { x = 5, y = 5 }
    , score = 0
    , status = Playing
    }


type Msg
    = Tick Time.Posix
    | KeyPressed Direction
    | Ignore


-- ── WEEK 3: Movement ─────────────────────────────────────────────

nextHead : Direction -> Position -> Position
nextHead dir pos =
    case dir of
        Up ->
            { pos | y = pos.y - 1 }

        Down ->
            { pos | y = pos.y + 1 }

        Left ->
            { pos | x = pos.x - 1 }

        Right ->
            { pos | x = pos.x + 1 }


-- ── WEEK 4: Collision + food ─────────────────────────────────────

hitsItself : Position -> List Position -> Bool
hitsItself head body =
    List.member head body


respawnFood : Position -> Position
respawnFood current =
    { x = modBy gridSize (current.x * 7 + 3)
    , y = modBy gridSize (current.y * 13 + 7)
    }


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

                -- Week 4: body grows on eat, shrinks on move
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

                -- Week 1: pointValue used here for scoring
                newScore =
                    if ateFood then
                        model.score + pointValue model.score

                    else
                        model.score

                newStatus =
                    if not (isInBounds newHead.x newHead.y) || hitsItself newHead model.body then
                        GameOver

                    else
                        Playing
            in
            { model
                | head = newHead
                , body = newBody
                , food = newFood
                , score = newScore
                , status = newStatus
            }


-- ── WEEK 3: Update, view, subscriptions ──────────────────────────

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick _ ->
            ( tickGame model, Cmd.none )

        KeyPressed dir ->
            ( { model | direction = dir }, Cmd.none )

        Ignore ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    let
        gameOverText =
            case model.status of
                GameOver ->
                    [ p
                        [ style "color" "#f87171"
                        , style "font-size" "24px"
                        , style "margin" "8px 0 0 0"
                        ]
                        [ text "GAME OVER" ]
                    ]

                Playing ->
                    []
    in
    div
        [ style "font-family" "monospace"
        , style "background" "#0a1628"
        , style "padding" "16px"
        , style "display" "inline-block"
        ]
        ([ p
            [ style "color" "#16a34a", style "margin" "0 0 8px 0" ]
            [ text ("Score: " ++ String.fromInt model.score) ]
         , svg
            [ SA.width (String.fromInt (gridSize * cellSize))
            , SA.height (String.fromInt (gridSize * cellSize))
            ]
            (drawBoard
                ++ List.map (drawCell "#22c55e") model.body
                ++ [ drawCell "#f0ede0" model.head
                   , drawCell "#dc2626" model.food
                   ]
            )
         ]
            ++ gameOverText
        )


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

        _ ->
            Ignore


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Time.every 200 Tick
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
