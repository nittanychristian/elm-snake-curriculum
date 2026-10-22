module Main exposing (main)

import Browser
import Game exposing (FoodType)
import Html exposing (Html, button, div, h1, img, p, text)
import Html.Attributes exposing (alt, src, style)
import Html.Events exposing (onClick)
import Random
import Task
import Time


type alias Model =
    { foodType : FoodType
    , seed : Random.Seed
    , choices : Int
    }


type Msg
    = ChooseNext
    | ClockReady Time.Posix


initialModel : Model
initialModel =
    { foodType = Game.Mouse, seed = Random.initialSeed 0, choices = 0 }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChooseNext ->
            let
                ( next, nextSeed ) =
                    Random.step (Game.differentFood model.foodType) model.seed
            in
            ( { model | foodType = next, seed = nextSeed, choices = model.choices + 1 }, Cmd.none )

        ClockReady now ->
            let
                ( first, nextSeed ) =
                    Random.step
                        (Random.uniform Game.Mouse (List.drop 1 Game.allFoodTypes))
                        (Random.initialSeed (Time.posixToMillis now))
            in
            ( { model | foodType = first, seed = nextSeed }, Cmd.none )


view : Model -> Html Msg
view model =
    div
        [ style "font-family" "sans-serif"
        , style "background" "#0a1628"
        , style "color" "#fff0ce"
        , style "padding" "24px"
        , style "max-width" "520px"
        , style "border-radius" "16px"
        ]
        [ h1 [] [ text "Choose the next prey" ]
        , img
            [ src (Game.foodIcon model.foodType)
            , alt (Game.foodName model.foodType)
            , style "width" "100px"
            , style "height" "100px"
            ]
            []
        , p [] [ text (Game.foodName model.foodType) ]
        , button [ onClick ChooseNext ] [ text "Catch it and choose another" ]
        , p [] [ text ("Choices made: " ++ String.fromInt model.choices) ]
        , p [] [ text "The next type always differs from the current type. Earlier types can return later." ]
        , p [] [ text (String.join ", " (List.map Game.foodName Game.allFoodTypes)) ]
        ]


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( initialModel, Task.perform ClockReady Time.now )
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }
