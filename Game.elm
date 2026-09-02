-- EAGLE STRIKE — Week 3: Interactive game with timer and Direction type.
--
-- All three weeks of concepts are visible here:
--   Week 1 — pure functions (isInBounds, pointValue, statusMessage)
--   Week 2 — drawing (drawCell, drawBoard)
--   Week 3 — Elm Architecture + Direction type + timer
--
-- The snake head moves automatically every 200 ms.
-- Arrow keys change the direction. No body or food yet — that's Week 4.
module Game exposing (main)

import Browser
import Browser.Events exposing (onKeyDown)
import Html exposing (Html, div, h2, p, text)
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
        [ SA.x (String.fromInt (col * cellSize))
        , SA.y (String.fromInt (row * cellSize))
        , SA.width (String.fromInt cellSize)
        , SA.height (String.fromInt cellSize)
        , SA.fill color
        , SA.rx "3"
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


-- ── WEEK 3: Elm Architecture + Direction type + timer ─────────────

-- Direction is now a proper custom type — no more String mistakes.
type Direction
    = Up
    | Down
    | Left
    | Right


type alias Position =
    { x : Int, y : Int }


type alias Model =
    { head : Position
    , direction : Direction
    }


initialModel : Model
initialModel =
    { head = { x = 10, y = 10 }
    , direction = Right
    }


type Msg
    = Tick Time.Posix
    | KeyPressed Direction
    | Ignore


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


isOutOfBounds : Position -> Bool
isOutOfBounds pos =
    pos.x < 0 || pos.x >= gridSize || pos.y < 0 || pos.y >= gridSize


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick _ ->
            let
                newHead =
                    nextHead model.direction model.head
            in
            if isOutOfBounds newHead then
                ( initialModel, Cmd.none )

            else
                ( { model | head = newHead }, Cmd.none )

        KeyPressed dir ->
            ( { model | direction = dir }, Cmd.none )

        Ignore ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    div
        [ style "font-family" "monospace"
        , style "background" "#0a1628"
        , style "padding" "16px"
        , style "display" "inline-block"
        ]
        [ h2
            [ style "color" "#16a34a", style "margin" "0 0 8px 0" ]
            [ text "Eagle Strike — Week 3" ]
        , p
            [ style "color" "#94a3b8", style "margin" "0 0 8px 0" ]
            [ text "Arrow keys to steer. Head moves on its own!" ]
        , svg
            [ SA.width (String.fromInt (gridSize * cellSize))
            , SA.height (String.fromInt (gridSize * cellSize))
            ]
            (drawBoard
                ++ [ drawCell "#f0ede0" model.head.x model.head.y
                   , drawCell "#dc2626" 5 5
                   ]
            )
        ]


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
