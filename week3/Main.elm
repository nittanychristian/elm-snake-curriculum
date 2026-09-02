module Main exposing (main)

import Browser
import Browser.Events exposing (onKeyDown)
import Html exposing (Html)
import Json.Decode as Decode
import Svg exposing (rect, svg)
import Svg.Attributes as SA


-- THE MODEL: everything the app needs to know
type alias Model =
    { boxX : Int
    , boxY : Int
    }


initialModel : Model
initialModel =
    { boxX = 100, boxY = 100 }


-- MESSAGES: every possible event that can happen
type Msg
    = MoveUp
    | MoveDown
    | MoveLeft
    | MoveRight
    | Other


-- UPDATE: given a message and the OLD model, produce a NEW model.
-- Nothing is changed. A fresh model is returned.
update : Msg -> Model -> Model
update msg model =
    case msg of
        MoveUp ->
            { model | boxY = model.boxY - 10 }

        MoveDown ->
            { model | boxY = model.boxY + 10 }

        MoveLeft ->
            { model | boxX = model.boxX - 10 }

        MoveRight ->
            { model | boxX = model.boxX + 10 }

        Other ->
            model


-- VIEW: turn the model into pixels. Pure function — no side effects.
view : Model -> Html Msg
view model =
    svg
        [ SA.width "400", SA.height "400" ]
        [ rect
            [ SA.x (String.fromInt model.boxX)
            , SA.y (String.fromInt model.boxY)
            , SA.width "30"
            , SA.height "30"
            , SA.fill "#4ade80"
            ]
            []
        ]


-- SUBSCRIPTIONS: what external events should Elm listen for?
keyDecoder : Decode.Decoder Msg
keyDecoder =
    Decode.map toMsg (Decode.field "key" Decode.string)


toMsg : String -> Msg
toMsg key =
    case key of
        "ArrowUp" ->
            MoveUp

        "ArrowDown" ->
            MoveDown

        "ArrowLeft" ->
            MoveLeft

        "ArrowRight" ->
            MoveRight

        _ ->
            Other


subscriptions : Model -> Sub Msg
subscriptions _ =
    onKeyDown keyDecoder


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( initialModel, Cmd.none )
        , view = view
        , update = \msg model -> ( update msg model, Cmd.none )
        , subscriptions = subscriptions
        }
