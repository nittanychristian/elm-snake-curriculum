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
    , status : GameStatus
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
                    if isOutOfBounds newHead || hitsItself newHead model.body then
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


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick _ ->
            ( tickGame model, Cmd.none )

        -- Stretch challenge: ignore direction reversals
        KeyPressed dir ->
            if isOpposite model.direction dir then
                ( model, Cmd.none )

            else
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
                (\col -> drawCell "#1a1a2e" { x = col, y = row })
                (List.range 0 (gridSize - 1))
        )
        (List.range 0 (gridSize - 1))


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
        , style "background" "#0f0f23"
        , style "padding" "16px"
        , style "display" "inline-block"
        ]
        ([ p
            [ style "color" "#4ade80", style "margin" "0 0 4px 0" ]
            [ text ("Score: " ++ String.fromInt model.score) ]
         , p
            [ style "color" "#94a3b8", style "margin" "0 0 8px 0" ]
            [ text ("Length: " ++ String.fromInt (List.length model.body + 1)) ]
         , svg
            [ SA.width (String.fromInt (gridSize * cellSize))
            , SA.height (String.fromInt (gridSize * cellSize))
            ]
            (drawBoard
                ++ List.map (drawCell "#22c55e") model.body
                ++ [ drawCell "#4ade80" model.head
                   , drawCell "#f87171" model.food
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
