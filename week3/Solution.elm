-- Eagle Strike — Week 3 solution: moving snake head.
-- The box from Main.elm has been transformed into a game:
--   - Direction custom type replaces MoveUp/MoveDown/… messages
--   - Position type alias names the { x, y } record
--   - Time.every fires a Tick every 200 ms — head moves automatically
--   - Arrow keys change direction; the head moves on its own
-- Next week: add body, food, and collision detection.
module Solution exposing (main)

import Browser
import Browser.Events exposing (onKeyDown)
import Html exposing (Html, div, p, text)
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
    div
        [ style "font-family" "monospace"
        , style "background" "#0a1628"
        , style "padding" "16px"
        , style "display" "inline-block"
        , style "border" "3px solid #1d4ed8"
        , style "border-radius" "10px"
        ]
        [ p
            [ style "color" "#16a34a"
            , style "margin" "0 0 8px 0"
            , style "font-size" "20px"
            , style "text-align" "center"
            , style "letter-spacing" "2px"
            ]
            [ text "EAGLE STRIKE" ]
        , svg
            [ SA.width (String.fromInt (gridSize * cellSize))
            , SA.height (String.fromInt (gridSize * cellSize))
            ]
            (drawBoard ++ [ drawCell "#f0ede0" model.head ])
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
