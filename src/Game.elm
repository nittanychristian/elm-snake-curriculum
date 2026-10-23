-- Eagle Strike — Week 5 solution with school colors (blue & green) and eagle mascot.
-- Changes from Week 4:
--   - Navy board, brown feathers, white eagle head, gold beak
--   - Embedded eagle head, body, and tail follow the direction of each segment
--   - Renamed: "Eagle Strike", score says "Prey caught"
--   - "GO EAGLES!" on game over
--   - Restart on R key (high score preserved)
--   - Wrap-around walls instead of game over on wall hit
--   - Speed increases with score
--   - Ten illustrated prey types, with a different random type after every catch
--   - Every fifth prey has a golden halo and is worth three points


module Game exposing
    ( Direction(..)
    , EaglePart(..)
    , FoodType(..)
    , GameStatus(..)
    , Model
    , Msg(..)
    , Position
    , Segment
    , allFoodTypes
    , bodySegments
    , cornerColors
    , cornerRotation
    , differentFood
    , directionToward
    , eagleSegments
    , foodIcon
    , foodName
    , foodPoints
    , gridSize
    , initialModel
    , isGoldenFood
    , main
    , nextHead
    , tickGame
    , update
    )

import Browser
import Browser.Events exposing (onKeyDown)
import Html exposing (Html, div, h1, node, p, text)
import Html.Attributes exposing (class, style)
import Json.Decode as Decode
import Random
import Svg exposing (Svg, rect, svg)
import Svg.Attributes as SA
import Task
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


type FoodType
    = Mouse
    | Vole
    | Rat
    | Rabbit
    | Squirrel
    | Duck
    | Quail
    | Snake
    | Lizard
    | Frog


type alias Position =
    { x : Int, y : Int }


type EaglePart
    = EagleHead
    | EagleBody
    | EagleBend Direction
    | EagleTail


type alias Segment =
    { part : EaglePart
    , direction : Direction
    , position : Position
    }


type alias Model =
    { head : Position
    , body : List Position
    , direction : Direction
    , food : Position
    , foodType : FoodType
    , randomSeed : Random.Seed
    , score : Int
    , foodEaten : Int
    , highScore : Int
    , status : GameStatus
    }


initialModel : Model
initialModel =
    { head = { x = 10, y = 10 }
    , body = [ { x = 9, y = 10 }, { x = 8, y = 10 } ]
    , direction = Right
    , food = { x = 5, y = 5 }
    , foodType = Mouse
    , randomSeed = Random.initialSeed 0
    , score = 0
    , foodEaten = 0
    , highScore = 0
    , status = Playing
    }


type Msg
    = Tick Time.Posix
    | KeyPressed Direction
    | Restart
    | InitializeFood Time.Posix
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


allFoodTypes : List FoodType
allFoodTypes =
    [ Mouse, Vole, Rat, Rabbit, Squirrel, Duck, Quail, Snake, Lizard, Frog ]


foodName : FoodType -> String
foodName foodType =
    case foodType of
        Mouse ->
            "Mouse"

        Vole ->
            "Vole"

        Rat ->
            "Rat"

        Rabbit ->
            "Rabbit"

        Squirrel ->
            "Squirrel"

        Duck ->
            "Duck"

        Quail ->
            "Quail"

        Snake ->
            "Snake"

        Lizard ->
            "Lizard"

        Frog ->
            "Frog"


differentFood : FoodType -> Random.Generator FoodType
differentFood current =
    case List.filter ((/=) current) allFoodTypes of
        first :: rest ->
            Random.uniform first rest

        [] ->
            -- Unreachable with our ten-type catalogue; Random.uniform needs a first choice.
            Random.constant Mouse


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


isGoldenFood : Int -> Bool
isGoldenFood foodEaten =
    modBy 5 (foodEaten + 1) == 0


foodPoints : Int -> Int
foodPoints foodEaten =
    if isGoldenFood foodEaten then
        3

    else
        1


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

                ( newFoodType, newSeed ) =
                    if ateFood then
                        Random.step (differentFood model.foodType) model.randomSeed

                    else
                        ( model.foodType, model.randomSeed )

                newScore =
                    if ateFood then
                        model.score + foodPoints model.foodEaten

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
                , foodType = newFoodType
                , randomSeed = newSeed
                , score = newScore
                , foodEaten =
                    if ateFood then
                        model.foodEaten + 1

                    else
                        model.foodEaten
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
            let
                ( newFoodType, newSeed ) =
                    Random.step (differentFood model.foodType) model.randomSeed
            in
            ( { initialModel
                | highScore = model.highScore
                , foodType = newFoodType
                , randomSeed = newSeed
              }
            , Cmd.none
            )

        InitializeFood now ->
            let
                ( newFoodType, newSeed ) =
                    Random.step
                        (Random.uniform Mouse (List.drop 1 allFoodTypes))
                        (Random.initialSeed (Time.posixToMillis now))
            in
            ( { model | foodType = newFoodType, randomSeed = newSeed }, Cmd.none )

        Ignore ->
            ( model, Cmd.none )



-- VIEW --


foodIcon : FoodType -> String
foodIcon foodType =
    case foodType of
        Mouse ->
            "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIiB2aWV3Qm94PSIwIDAgMTAwIDEwMCIgcm9sZT0iaW1nIiBhcmlhLWxhYmVsbGVkYnk9InRpdGxlIj4KICA8dGl0bGUgaWQ9InRpdGxlIj5Nb3VzZTwvdGl0bGU+CiAgPHBhdGggZD0iTTI5IDY1QzAgODUgNiAzOCAyNCA0NCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjZTlhNmFkIiBzdHJva2Utd2lkdGg9IjciIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIvPgogIDxlbGxpcHNlIGN4PSI0NyIgY3k9IjU4IiByeD0iMjgiIHJ5PSIyMSIgZmlsbD0iI2FlYjdjNyIvPgogIDxwYXRoIGQ9Ik01NCA0MFE3NyAzNyA5MyA2MVE3OSA3OSA1OCA3M1oiIGZpbGw9IiNjZGQzZGYiLz4KICA8Y2lyY2xlIGN4PSI1NyIgY3k9IjM0IiByPSIxNiIgZmlsbD0iI2NkZDNkZiIvPgogIDxjaXJjbGUgY3g9IjU3IiBjeT0iMzQiIHI9IjkiIGZpbGw9IiNmMWI1YmQiLz4KICA8ZWxsaXBzZSBjeD0iNjkiIGN5PSI1NCIgcng9IjQiIHJ5PSI1IiBmaWxsPSIjMjczMzRhIi8+CiAgPGNpcmNsZSBjeD0iNzAiIGN5PSI1MiIgcj0iMS40IiBmaWxsPSJ3aGl0ZSIvPgogIDxjaXJjbGUgY3g9IjkxIiBjeT0iNjEiIHI9IjQiIGZpbGw9IiNlNTkzYTUiLz4KICA8cGF0aCBkPSJNODEgNjVMOTYgNzJNODAgNjBMOTcgNTYiIHN0cm9rZT0iI2YzZThkYyIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiLz4KICA8cGF0aCBkPSJNMzUgNzZINDdNNjEgNzZINzIiIHN0cm9rZT0iI2U5YTZhZCIgc3Ryb2tlLXdpZHRoPSI1IiBzdHJva2UtbGluZWNhcD0icm91bmQiLz4KPC9zdmc+Cg=="

        Vole ->
            "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIiB2aWV3Qm94PSIwIDAgMTAwIDEwMCIgcm9sZT0iaW1nIiBhcmlhLWxhYmVsbGVkYnk9InRpdGxlIj4KICA8dGl0bGUgaWQ9InRpdGxlIj5Wb2xlPC90aXRsZT4KICA8cGF0aCBkPSJNMjQgNjZROCA3NCAxMCA2MCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjZDVhYjg2IiBzdHJva2Utd2lkdGg9IjYiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIvPgogIDxlbGxpcHNlIGN4PSI0NiIgY3k9IjU4IiByeD0iMzIiIHJ5PSIyNSIgZmlsbD0iIzliNjQ0NyIvPgogIDxlbGxpcHNlIGN4PSI1MCIgY3k9IjY1IiByeD0iMjUiIHJ5PSIxNiIgZmlsbD0iI2M1OTI2MCIvPgogIDxwYXRoIGQ9Ik01NCA0MFE4MCAzNyA5MiA2MlE4MiA3OSA1OCA3N1oiIGZpbGw9IiNiNjdiNTEiLz4KICA8Y2lyY2xlIGN4PSI2MiIgY3k9IjM5IiByPSI5IiBmaWxsPSIjOWI2NDQ3Ii8+CiAgPGNpcmNsZSBjeD0iNjIiIGN5PSIzOSIgcj0iNCIgZmlsbD0iI2Q2YTE4MCIvPgogIDxjaXJjbGUgY3g9Ijc1IiBjeT0iNTUiIHI9IjQiIGZpbGw9IiMyYzI2MzIiLz4KICA8Y2lyY2xlIGN4PSI3NiIgY3k9IjU0IiByPSIxLjIiIGZpbGw9IndoaXRlIi8+CiAgPGVsbGlwc2UgY3g9IjkwIiBjeT0iNjMiIHJ4PSI0IiByeT0iMyIgZmlsbD0iI2UwYWFhMCIvPgogIDxwYXRoIGQ9Ik0zNCAzOEwzMCA0NU00MyAzNUwzOSA0M001MiAzNkw0OCA0MyIgc3Ryb2tlPSIjZDRhNDZlIiBzdHJva2Utd2lkdGg9IjMiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIvPgogIDxwYXRoIGQ9Ik0zMiA4MUg0NE02MiA4MUg3NCIgc3Ryb2tlPSIjZDVhYjg2IiBzdHJva2Utd2lkdGg9IjUiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIvPgo8L3N2Zz4K"

        Rat ->
            "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIiB2aWV3Qm94PSIwIDAgMTAwIDEwMCIgcm9sZT0iaW1nIiBhcmlhLWxhYmVsbGVkYnk9InRpdGxlIj4KICA8dGl0bGUgaWQ9InRpdGxlIj5SYXQ8L3RpdGxlPgogIDxwYXRoIGQ9Ik0zMCA2NkMzIDkwIDAgNTIgMTIgNDVDMjUgMzggMTQgMjAgNSAyNyIgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjYzU5YTllIiBzdHJva2Utd2lkdGg9IjYiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIvPgogIDxlbGxpcHNlIGN4PSI0OSIgY3k9IjU4IiByeD0iMjkiIHJ5PSIyMiIgZmlsbD0iIzY2NWI2YyIvPgogIDxwYXRoIGQ9Ik01OCA0Mkw5NCA2NEw3MyA3N0w1MSA3MFoiIGZpbGw9IiM4YzdkOGQiLz4KICA8Y2lyY2xlIGN4PSI2MyIgY3k9IjM5IiByPSIxMSIgZmlsbD0iIzhjN2Q4ZCIvPgogIDxjaXJjbGUgY3g9IjYzIiBjeT0iMzkiIHI9IjYiIGZpbGw9IiNjNTlhOWUiLz4KICA8cGF0aCBkPSJNMzEgNDlRNDIgMzkgNTUgNDMiIGZpbGw9Im5vbmUiIHN0cm9rZT0iI2EzOTJhMSIgc3Ryb2tlLXdpZHRoPSI0IiBzdHJva2UtbGluZWNhcD0icm91bmQiLz4KICA8Y2lyY2xlIGN4PSI3NiIgY3k9IjU3IiByPSIzLjUiIGZpbGw9IiMyNjFmMmMiLz4KICA8Y2lyY2xlIGN4PSI3NyIgY3k9IjU2IiByPSIxIiBmaWxsPSJ3aGl0ZSIvPgogIDxjaXJjbGUgY3g9Ijk0IiBjeT0iNjQiIHI9IjMuNSIgZmlsbD0iI2RmYWNiMCIvPgogIDxwYXRoIGQ9Ik04NCA2N0w5OCA3NU04NCA2M0w5OCA1OSIgc3Ryb2tlPSIjZGZkN2RkIiBzdHJva2Utd2lkdGg9IjIiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIvPgogIDxwYXRoIGQ9Ik00MCA3OUg1ME02NyA3OUg3OCIgc3Ryb2tlPSIjYzU5YTllIiBzdHJva2Utd2lkdGg9IjUiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIvPgo8L3N2Zz4K"

        Rabbit ->
            "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIiB2aWV3Qm94PSIwIDAgMTAwIDEwMCIgcm9sZT0iaW1nIiBhcmlhLWxhYmVsbGVkYnk9InRpdGxlIj4KICA8dGl0bGUgaWQ9InRpdGxlIj5SYWJiaXQ8L3RpdGxlPgogIDxlbGxpcHNlIGN4PSI1OSIgY3k9IjI4IiByeD0iOSIgcnk9IjI0IiB0cmFuc2Zvcm09InJvdGF0ZSgtMTIgNTkgMjgpIiBmaWxsPSIjZTVkOWM2Ii8+CiAgPGVsbGlwc2UgY3g9Ijc3IiBjeT0iMjgiIHJ4PSI4IiByeT0iMjMiIHRyYW5zZm9ybT0icm90YXRlKDEyIDc3IDI4KSIgZmlsbD0iI2U1ZDljNiIvPgogIDxwYXRoIGQ9Ik01OSAxNEw2MSAzOE03OCAxNEw3NCAzOCIgc3Ryb2tlPSIjZTdhYWE1IiBzdHJva2Utd2lkdGg9IjYiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIvPgogIDxjaXJjbGUgY3g9IjIwIiBjeT0iNjYiIHI9IjEzIiBmaWxsPSIjZmZmNWRlIi8+CiAgPGVsbGlwc2UgY3g9IjQ0IiBjeT0iNjYiIHJ4PSIyOCIgcnk9IjIzIiBmaWxsPSIjYzRhZTk2Ii8+CiAgPGVsbGlwc2UgY3g9IjQ1IiBjeT0iNzQiIHJ4PSIxOCIgcnk9IjE0IiBmaWxsPSIjZTVkOWM2Ii8+CiAgPHBhdGggZD0iTTQ5IDQ5UTY2IDM0IDgyIDQ3UTk1IDU5IDg1IDczTDYwIDc2WiIgZmlsbD0iI2U1ZDljNiIvPgogIDxjaXJjbGUgY3g9Ijc2IiBjeT0iNTYiIHI9IjQiIGZpbGw9IiMzYjM0NDAiLz4KICA8Y2lyY2xlIGN4PSI3NyIgY3k9IjU1IiByPSIxLjIiIGZpbGw9IndoaXRlIi8+CiAgPHBhdGggZD0iTTg5IDY0TDgzIDY4TDgzIDYyWiIgZmlsbD0iI2RmOTU5ZCIvPgogIDxwYXRoIGQ9Ik0zOCA4Nkg1N002NSA4Mkg4MCIgc3Ryb2tlPSIjZmZmMGQ3IiBzdHJva2Utd2lkdGg9IjciIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIvPgo8L3N2Zz4K"

        Squirrel ->
            "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIiB2aWV3Qm94PSIwIDAgMTAwIDEwMCIgcm9sZT0iaW1nIiBhcmlhLWxhYmVsbGVkYnk9InRpdGxlIj4KICA8dGl0bGUgaWQ9InRpdGxlIj5TcXVpcnJlbDwvdGl0bGU+CiAgPHBhdGggZD0iTTQxIDc2QzkgNzYgMSA1MSA4IDI4QzE2IDUgNDQgNyA0NiAyOEM0OCA0MiAzNCA0OSAyNSA0MUMyMCAzNSAyMyAyNyAyOSAyOUMxMyA0MyAyOSA1NyA0NyA1NVoiIGZpbGw9IiNkNzgwM2QiLz4KICA8cGF0aCBkPSJNMjAgMjNDOSAzOSAxNiA1OSAzMiA2MiIgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjZjFiOTY3IiBzdHJva2Utd2lkdGg9IjYiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIvPgogIDxlbGxpcHNlIGN4PSI1OCIgY3k9IjY1IiByeD0iMjIiIHJ5PSIyNCIgZmlsbD0iI2JkNjkzNSIvPgogIDxlbGxpcHNlIGN4PSI2NSIgY3k9IjY3IiByeD0iMTIiIHJ5PSIxOCIgZmlsbD0iI2YyZDZhMCIvPgogIDxwYXRoIGQ9Ik01OCA0M0w1OCAyMkw3MCAzNFE4OCAzMiA5MSA0OUw4MCA2MEw2MCA1N1oiIGZpbGw9IiNkNzgwM2QiLz4KICA8cGF0aCBkPSJNNjEgMjlMNjQgMzlMNjkgMzVaIiBmaWxsPSIjZjBjMjhiIi8+CiAgPGNpcmNsZSBjeD0iODAiIGN5PSI0MyIgcj0iNCIgZmlsbD0iIzMwMjczOCIvPgogIDxjaXJjbGUgY3g9IjgxIiBjeT0iNDIiIHI9IjEuMiIgZmlsbD0id2hpdGUiLz4KICA8Y2lyY2xlIGN4PSI5MSIgY3k9IjUwIiByPSIzIiBmaWxsPSIjNjg0MTNiIi8+CiAgPHBhdGggZD0iTTU2IDg2SDc3TTcyIDYyTDg2IDY2IiBzdHJva2U9IiNlYWEzNWQiIHN0cm9rZS13aWR0aD0iNiIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIi8+Cjwvc3ZnPgo="

        Duck ->
            "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIiB2aWV3Qm94PSIwIDAgMTAwIDEwMCIgcm9sZT0iaW1nIiBhcmlhLWxhYmVsbGVkYnk9InRpdGxlIj4KICA8dGl0bGUgaWQ9InRpdGxlIj5EdWNrPC90aXRsZT4KICA8cGF0aCBkPSJNMjggNjFMOCA0M0wxMiA2NloiIGZpbGw9IiNhNTgyNjciLz4KICA8ZWxsaXBzZSBjeD0iNDQiIGN5PSI2NCIgcng9IjMxIiByeT0iMjIiIGZpbGw9IiNkMWM1YWMiLz4KICA8cGF0aCBkPSJNMjQgNTVRNDMgNDQgNjEgNTdRNDkgNzYgMjcgNzFaIiBmaWxsPSIjODk3NDYzIi8+CiAgPHBhdGggZD0iTTM0IDYxUTQ2IDU1IDU1IDYwTDQ2IDY4TDMyIDY4WiIgZmlsbD0iIzVlOGZiYyIvPgogIDxwYXRoIGQ9Ik01OCA1N0w2MCAzN0w3NSAzN0w3OCA2NFoiIGZpbGw9IiM0NThjNmMiLz4KICA8Y2lyY2xlIGN4PSI3MCIgY3k9IjMyIiByPSIxNyIgZmlsbD0iIzMyOGI3MCIvPgogIDxwYXRoIGQ9Ik01NyA0OEw3NyA1MSIgc3Ryb2tlPSIjZmZmMWNlIiBzdHJva2Utd2lkdGg9IjUiLz4KICA8cGF0aCBkPSJNODAgMzFMOTcgMzVMOTYgNDNMODAgNDJaIiBmaWxsPSIjZjRiZjRlIi8+CiAgPGNpcmNsZSBjeD0iNzYiIGN5PSIyOCIgcj0iMy41IiBmaWxsPSIjMWMzMTQwIi8+CiAgPGNpcmNsZSBjeD0iNzciIGN5PSIyNyIgcj0iMSIgZmlsbD0id2hpdGUiLz4KICA8cGF0aCBkPSJNMzcgODRMMzQgOTFINDZNNTcgODRMNTUgOTFINjciIGZpbGw9Im5vbmUiIHN0cm9rZT0iI2U4YTc0MyIgc3Ryb2tlLXdpZHRoPSI1IiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiLz4KPC9zdmc+Cg=="

        Quail ->
            "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIiB2aWV3Qm94PSIwIDAgMTAwIDEwMCIgcm9sZT0iaW1nIiBhcmlhLWxhYmVsbGVkYnk9InRpdGxlIj4KICA8dGl0bGUgaWQ9InRpdGxlIj5RdWFpbDwvdGl0bGU+CiAgPHBhdGggZD0iTTYyIDI5UTUyIDkgNjcgOVE4MCAxMCA3MSAxOUw2NiAxN0w2NyAyOFoiIGZpbGw9IiMzYzM2NDIiLz4KICA8cGF0aCBkPSJNMjYgNjVMOSA0N0w5IDY1TDIzIDc1WiIgZmlsbD0iIzgwNjU0ZiIvPgogIDxlbGxpcHNlIGN4PSI0NyIgY3k9IjYyIiByeD0iMzAiIHJ5PSIyNSIgZmlsbD0iIzlmODc2OCIvPgogIDxlbGxpcHNlIGN4PSI2MSIgY3k9IjY4IiByeD0iMTgiIHJ5PSIxNyIgZmlsbD0iI2UyY2I5NiIvPgogIDxwYXRoIGQ9Ik0yNiA0OVE0MiA0MSA1NSA1NFE0NSA3NSAyNSA3MFoiIGZpbGw9IiM3ZDY5NWEiLz4KICA8Y2lyY2xlIGN4PSI2OCIgY3k9IjM2IiByPSIxNiIgZmlsbD0iI2E4YTlhNCIvPgogIDxwYXRoIGQ9Ik01OCAzNVE2OCA0NSA3OSAzNEw3NSA0OUw2NCA1MVoiIGZpbGw9IiMzYzM2NDIiLz4KICA8cGF0aCBkPSJNNTcgMzZRNjUgNDggNzggMzkiIGZpbGw9Im5vbmUiIHN0cm9rZT0iI2ZmZjBjZSIgc3Ryb2tlLXdpZHRoPSIzIi8+CiAgPHBhdGggZD0iTTgxIDM0TDk0IDQwTDgxIDQ0WiIgZmlsbD0iI2Q2YWQ2NyIvPgogIDxjaXJjbGUgY3g9Ijc0IiBjeT0iMzEiIHI9IjMiIGZpbGw9IiMyNDJhMzQiLz4KICA8cGF0aCBkPSJNNTEgNTlMNTUgNjVNNjQgNTlMNjcgNjVNNTcgNzFMNjEgNzdNNjkgNjlMNzIgNzUiIHN0cm9rZT0iI2E1OGI1OCIgc3Ryb2tlLXdpZHRoPSIzIiBzdHJva2UtbGluZWNhcD0icm91bmQiLz4KICA8cGF0aCBkPSJNMzggODRMMzYgOTJINDZNNjAgODRMNTggOTJINjgiIGZpbGw9Im5vbmUiIHN0cm9rZT0iI2M0OTQ1OCIgc3Ryb2tlLXdpZHRoPSI0IiBzdHJva2UtbGluZWNhcD0icm91bmQiLz4KPC9zdmc+Cg=="

        Snake ->
            "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIiB2aWV3Qm94PSIwIDAgMTAwIDEwMCIgcm9sZT0iaW1nIiBhcmlhLWxhYmVsbGVkYnk9InRpdGxlIj4KICA8dGl0bGUgaWQ9InRpdGxlIj5TbmFrZTwvdGl0bGU+CiAgPHBhdGggZD0iTTEwIDc4QzM0IDkyIDc1IDg3IDczIDY4QzcxIDQ5IDI0IDcwIDIzIDUwQzIyIDMyIDYxIDQ5IDY0IDMxIiBmaWxsPSJub25lIiBzdHJva2U9IiM0YjljNjIiIHN0cm9rZS13aWR0aD0iMTciIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIvPgogIDxwYXRoIGQ9Ik0xMyA4MEMzNyA5MiA3MCA4NSA2NyA2OU0zMCA1MFE0NSA1NyA1OCA0OSIgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjYzhkYTc4IiBzdHJva2Utd2lkdGg9IjUiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIvPgogIDxwYXRoIGQ9Ik01NSAzNVE0OCAyMyA2MSAxNlE3NiA3IDg5IDIxTDg2IDM0UTY5IDQ1IDU1IDM1WiIgZmlsbD0iIzc0YmQ2OSIvPgogIDxwYXRoIGQ9Ik04NyAyNkw5OCAyNk05NSAyNkw5OSAyMU05NSAyNkw5OSAzMSIgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjZTA3ODgwIiBzdHJva2Utd2lkdGg9IjMiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIvPgogIDxlbGxpcHNlIGN4PSI3NyIgY3k9IjIwIiByeD0iNCIgcnk9IjUiIGZpbGw9IiNmMmRmODUiLz4KICA8ZWxsaXBzZSBjeD0iNzgiIGN5PSIyMCIgcng9IjEuNSIgcnk9IjQiIGZpbGw9IiMyODQ0M2EiLz4KICA8cGF0aCBkPSJNMzkgNzVMNDMgODBNNTEgNzBMNTUgNzVNMzIgNDVMMzYgNTAiIHN0cm9rZT0iIzJjNzM0ZiIgc3Ryb2tlLXdpZHRoPSI0IiBzdHJva2UtbGluZWNhcD0icm91bmQiLz4KPC9zdmc+Cg=="

        Lizard ->
            "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIiB2aWV3Qm94PSIwIDAgMTAwIDEwMCIgcm9sZT0iaW1nIiBhcmlhLWxhYmVsbGVkYnk9InRpdGxlIj4KICA8dGl0bGUgaWQ9InRpdGxlIj5MaXphcmQ8L3RpdGxlPgogIDxwYXRoIGQ9Ik00NCA1OEMxNSA3OSAzIDU4IDEwIDM4IiBmaWxsPSJub25lIiBzdHJva2U9IiMzZTljOTkiIHN0cm9rZS13aWR0aD0iMTAiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIvPgogIDxnIGZpbGw9Im5vbmUiIHN0cm9rZT0iIzYxYzJhYyIgc3Ryb2tlLXdpZHRoPSI3IiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPgogICAgPHBhdGggZD0iTTM5IDUyTDI1IDM0TDE3IDMzTTM4IDYzTDI4IDgwTDE4IDgzTTY0IDQ4TDcwIDI5TDgxIDI0TTYzIDYyTDc2IDc4TDg3IDc3Ii8+CiAgPC9nPgogIDxwYXRoIGQ9Ik0xNyAzM0wxNiAyNk0xNyAzM0wxMCAzN00xOCA4M0wxMSA3OU0xOCA4M0wxNyA5MU04MSAyNEw4MCAxN004MSAyNEw4OCAyN004NyA3N0w5MCA3ME04NyA3N0w5NCA4MiIgc3Ryb2tlPSIjYTVkNjlkIiBzdHJva2Utd2lkdGg9IjMiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIvPgogIDxlbGxpcHNlIGN4PSI1MSIgY3k9IjU2IiByeD0iMjUiIHJ5PSIxNCIgZmlsbD0iIzNlOWM5OSIvPgogIDxwYXRoIGQ9Ik0zNCA1NUw2NyA1MSIgc3Ryb2tlPSIjZTZkMjdmIiBzdHJva2Utd2lkdGg9IjUiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIvPgogIDxwYXRoIGQ9Ik02NyA0NFE3OCAzMiA5MCA0MFExMDAgNDggODcgNjBMNzAgNjFaIiBmaWxsPSIjNjFjMmFjIi8+CiAgPGNpcmNsZSBjeD0iODYiIGN5PSI0NCIgcj0iNCIgZmlsbD0iI2U4ZGU4ZCIvPgogIDxjaXJjbGUgY3g9Ijg3IiBjeT0iNDQiIHI9IjIiIGZpbGw9IiMyNTQzNGEiLz4KICA8cGF0aCBkPSJNODMgNTVMOTEgNTIiIHN0cm9rZT0iIzI2N2I3YyIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiLz4KPC9zdmc+Cg=="

        Frog ->
            "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIiB2aWV3Qm94PSIwIDAgMTAwIDEwMCIgcm9sZT0iaW1nIiBhcmlhLWxhYmVsbGVkYnk9InRpdGxlIj4KICA8dGl0bGUgaWQ9InRpdGxlIj5Gcm9nPC90aXRsZT4KICA8ZWxsaXBzZSBjeD0iMjUiIGN5PSI2OCIgcng9IjE4IiByeT0iMTYiIHRyYW5zZm9ybT0icm90YXRlKC0yNSAyNSA2OCkiIGZpbGw9IiM1OGE5NTMiLz4KICA8ZWxsaXBzZSBjeD0iNzUiIGN5PSI2OCIgcng9IjE4IiByeT0iMTYiIHRyYW5zZm9ybT0icm90YXRlKDI1IDc1IDY4KSIgZmlsbD0iIzU4YTk1MyIvPgogIDxlbGxpcHNlIGN4PSI1MCIgY3k9IjYwIiByeD0iMjciIHJ5PSIyNSIgZmlsbD0iIzgyYzg1ZSIvPgogIDxlbGxpcHNlIGN4PSI1MCIgY3k9IjY2IiByeD0iMTgiIHJ5PSIxNyIgZmlsbD0iI2Q0ZTU4YiIvPgogIDxwYXRoIGQ9Ik0yNyA2NUwyNSA4M0wxMyA4Nk03MyA2NUw3NSA4M0w4NyA4NiIgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjOGFjYjY2IiBzdHJva2Utd2lkdGg9IjgiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIgc3Ryb2tlLWxpbmVqb2luPSJyb3VuZCIvPgogIDxwYXRoIGQ9Ik0xMyA4Nkw3IDc5TTEzIDg2TDcgOTFNODcgODZMOTMgNzlNODcgODZMOTMgOTEiIHN0cm9rZT0iI2I1ZGI3YyIgc3Ryb2tlLXdpZHRoPSI0IiBzdHJva2UtbGluZWNhcD0icm91bmQiLz4KICA8ZWxsaXBzZSBjeD0iNTAiIGN5PSI0MyIgcng9IjMyIiByeT0iMjAiIGZpbGw9IiM4MmM4NWUiLz4KICA8Y2lyY2xlIGN4PSIzMSIgY3k9IjI4IiByPSIxMyIgZmlsbD0iIzgyYzg1ZSIvPgogIDxjaXJjbGUgY3g9IjY5IiBjeT0iMjgiIHI9IjEzIiBmaWxsPSIjODJjODVlIi8+CiAgPGNpcmNsZSBjeD0iMzEiIGN5PSIyOCIgcj0iOCIgZmlsbD0iI2Y0ZTdhZSIvPgogIDxjaXJjbGUgY3g9IjY5IiBjeT0iMjgiIHI9IjgiIGZpbGw9IiNmNGU3YWUiLz4KICA8ZWxsaXBzZSBjeD0iMzIiIGN5PSIyOCIgcng9IjQiIHJ5PSI1IiBmaWxsPSIjMjkzZTM2Ii8+CiAgPGVsbGlwc2UgY3g9IjY4IiBjeT0iMjgiIHJ4PSI0IiByeT0iNSIgZmlsbD0iIzI5M2UzNiIvPgogIDxwYXRoIGQ9Ik0yOSA0NlE1MCA1OSA3MSA0NiIgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjNDA4YTQ4IiBzdHJva2Utd2lkdGg9IjMiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIvPgo8L3N2Zz4K"


headIcon : String
headIcon =
    "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIiB2aWV3Qm94PSIwIDAgMTAwIDEwMCIgcm9sZT0iaW1nIiBhcmlhLWxhYmVsbGVkYnk9InRpdGxlIGRlc2MiPgogIDx0aXRsZSBpZD0idGl0bGUiPkVhZ2xlIGhlYWQ8L3RpdGxlPgogIDxkZXNjIGlkPSJkZXNjIj5BIHJpZ2h0LWZhY2luZyBiYWxkIGVhZ2xlIHdpdGggaXZvcnkgZmVhdGhlcnMsIGEgZmllcmNlIGFtYmVyIGV5ZSwgYW5kIGEgaG9va2VkIGdvbGRlbiBiZWFrLiBUaGUgbGVmdCBlZGdlIGpvaW5zIHRoZSBib2R5IGZyb20geSAyOCB0byA3Mi48L2Rlc2M+CiAgPGRlZnM+CiAgICA8bGluZWFyR3JhZGllbnQgaWQ9ImVhZ2xlLWhlYWQtbmVjayIgeDE9IjAiIHkxPSIyOCIgeDI9IjAiIHkyPSI3MiIgZ3JhZGllbnRVbml0cz0idXNlclNwYWNlT25Vc2UiPgogICAgICA8c3RvcCBzdG9wLWNvbG9yPSIjNGMzMzJiIi8+CiAgICAgIDxzdG9wIG9mZnNldD0iLjQ1IiBzdG9wLWNvbG9yPSIjODA1MjM3Ii8+CiAgICAgIDxzdG9wIG9mZnNldD0iLjc1IiBzdG9wLWNvbG9yPSIjYjk4MjRlIi8+CiAgICAgIDxzdG9wIG9mZnNldD0iMSIgc3RvcC1jb2xvcj0iI2U2Y2JhMCIvPgogICAgPC9saW5lYXJHcmFkaWVudD4KICAgIDxsaW5lYXJHcmFkaWVudCBpZD0iZWFnbGUtaGVhZC13aGl0ZSIgeDE9IjI4IiB5MT0iMjMiIHgyPSI0MCIgeTI9Ijc4IiBncmFkaWVudFVuaXRzPSJ1c2VyU3BhY2VPblVzZSI+CiAgICAgIDxzdG9wIHN0b3AtY29sb3I9IiNmZmZkZjEiLz4KICAgICAgPHN0b3Agb2Zmc2V0PSIuNTgiIHN0b3AtY29sb3I9IiNmNWVkZGIiLz4KICAgICAgPHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjYzljNmJhIi8+CiAgICA8L2xpbmVhckdyYWRpZW50PgogICAgPGxpbmVhckdyYWRpZW50IGlkPSJlYWdsZS1oZWFkLWJlYWsiIHgxPSI2OSIgeTE9IjM5IiB4Mj0iODQiIHkyPSI2NiIgZ3JhZGllbnRVbml0cz0idXNlclNwYWNlT25Vc2UiPgogICAgICA8c3RvcCBzdG9wLWNvbG9yPSIjZmZlMjkxIi8+CiAgICAgIDxzdG9wIG9mZnNldD0iLjUiIHN0b3AtY29sb3I9IiNmNWJiNDYiLz4KICAgICAgPHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjYzc4MDI4Ii8+CiAgICA8L2xpbmVhckdyYWRpZW50PgogIDwvZGVmcz4KICA8cGF0aCBmaWxsPSJ1cmwoI2VhZ2xlLWhlYWQtbmVjaykiIGQ9Ik0wIDI4SDI3VjcySDBaIi8+CiAgPHBhdGggZmlsbD0iIzQzMmQyNyIgZD0iTTAgMjhIMjdWMzRIMFoiLz4KICA8cGF0aCBmaWxsPSIjZWZkYWIyIiBkPSJNMCA2NkgyN1Y3MkgwWiIvPgogIDxwYXRoIGZpbGw9InVybCgjZWFnbGUtaGVhZC13aGl0ZSkiIGQ9Ik05IDMxTDIwIDIzTDE5IDI5QzM2IDE3IDU5IDIxIDcwIDMyTDc3IDQxTDcyIDU3QzY2IDY5IDUzIDc2IDM4IDc2TDI3IDgyTDI5IDczTDE2IDc3TDIxIDY3TDkgNjlMMTYgNTdMOCA1N0wxNiA0NUw4IDQ2TDE1IDM3WiIvPgogIDxwYXRoIGZpbGw9IiNmZmZkZjEiIGQ9Ik0yMCAzMkMzOCAyMiA1NiAyNSA2NiAzM0M0OSAyOSAzNiAzMiAyNSAzOUwxNyA0NEwyMSAzNkwxNCAzOFoiLz4KICA8cGF0aCBmaWxsPSIjZGZkZGNmIiBkPSJNMjIgNTZDMzMgNjEgNDQgNjUgNjAgNjJDNTAgNzAgMzkgNzAgMjkgNjhMMjMgNzNMMjUgNjRMMTcgNjZaIi8+CiAgPHBhdGggZmlsbD0idXJsKCNlYWdsZS1oZWFkLWJlYWspIiBkPSJNNjggMzhDNzggMzggODkgNDIgOTYgNDhDMTAxIDUzIDk4IDY0IDg3IDY5TDg5IDU4TDc3IDU1TDY3IDU1WiIvPgogIDxwYXRoIGZpbGw9IiNmZmU3YTEiIGQ9Ik03MSAzOUM4MCA0MCA4OSA0NCA5NCA0OEw3OCA0N0w3MCA0NloiLz4KICA8cGF0aCBkPSJNNzAgNTRMODggNTNMOTMgNTYiIGZpbGw9Im5vbmUiIHN0cm9rZT0iI2E3NmIyNiIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiLz4KICA8ZWxsaXBzZSBjeD0iNzciIGN5PSI0NiIgcng9IjIuNCIgcnk9IjEuNSIgZmlsbD0iIzljNjUyOCIvPgogIDxwYXRoIGZpbGw9IiM1MTNlMzIiIGQ9Ik00NiA0MEM1MyAzNiA2MSAzNyA2NiA0MUw2MiA0OEw1MiA0OFoiLz4KICA8ZWxsaXBzZSBjeD0iNTciIGN5PSI0MiIgcng9IjQuOCIgcnk9IjQiIGZpbGw9IiNlOWI4NGUiLz4KICA8ZWxsaXBzZSBjeD0iNTgiIGN5PSI0MiIgcng9IjIuNCIgcnk9IjMuMyIgZmlsbD0iIzI0MmIyYyIvPgogIDxjaXJjbGUgY3g9IjU5IiBjeT0iNDAuOCIgcj0iMSIgZmlsbD0iI2ZmZmRmMSIvPgogIDxwYXRoIGQ9Ik00MyAzNUw2NSA0MCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjZmZmZGYxIiBzdHJva2Utd2lkdGg9IjUiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIvPgogIDxwYXRoIGQ9Ik0zNCA0NkwyOSA1MU0zNyA1NUwzMiA1OSIgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjZDJjZGJkIiBzdHJva2Utd2lkdGg9IjIiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIvPgo8L3N2Zz4K"


bodyIcon : String
bodyIcon =
    "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIiB2aWV3Qm94PSIwIDAgMTAwIDEwMCIgcm9sZT0iaW1nIiBhcmlhLWxhYmVsbGVkYnk9InRpdGxlIGRlc2MiPgogIDx0aXRsZSBpZD0idGl0bGUiPlJlcGVhdGluZyBlYWdsZSBib2R5PC90aXRsZT4KICA8ZGVzYyBpZD0iZGVzYyI+QSB3YXJtIGJyb3duIGZlYXRoZXJlZCBib2R5IHRpbGUgd2l0aCBtYXRjaGluZyBlZGdlcyBmcm9tIHkgMjggdG8gNzIsIGRlc2lnbmVkIHRvIHJlcGVhdCBob3Jpem9udGFsbHkuPC9kZXNjPgogIDxkZWZzPgogICAgPGxpbmVhckdyYWRpZW50IGlkPSJlYWdsZS1ib2R5LXNraW4iIHgxPSIwIiB5MT0iMjgiIHgyPSIwIiB5Mj0iNzIiIGdyYWRpZW50VW5pdHM9InVzZXJTcGFjZU9uVXNlIj4KICAgICAgPHN0b3Agc3RvcC1jb2xvcj0iIzRjMzMyYiIvPgogICAgICA8c3RvcCBvZmZzZXQ9Ii40NSIgc3RvcC1jb2xvcj0iIzgwNTIzNyIvPgogICAgICA8c3RvcCBvZmZzZXQ9Ii43NSIgc3RvcC1jb2xvcj0iI2I5ODI0ZSIvPgogICAgICA8c3RvcCBvZmZzZXQ9IjEiIHN0b3AtY29sb3I9IiNlNmNiYTAiLz4KICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgPC9kZWZzPgogIDxwYXRoIGZpbGw9InVybCgjZWFnbGUtYm9keS1za2luKSIgZD0iTTAgMjhIMTAwVjcySDBaIi8+CiAgPHBhdGggZmlsbD0iIzQzMmQyNyIgZD0iTTAgMjhIMTAwVjM0SDBaIi8+CiAgPHBhdGggZmlsbD0iI2VmZGFiMiIgZD0iTTAgNjZIMTAwVjcySDBaIi8+CiAgPCEtLSBTdGFnZ2VyZWQsIGJhY2t3YXJkLXBvaW50aW5nIGZlYXRoZXJzIHN0b3Agc2hvcnQgb2YgdGhlIGpvaW5pbmcgZWRnZXMuIC0tPgogIDxnIGZpbGw9IiNhODc5NGYiIHN0cm9rZT0iIzY4NDMyZiIgc3Ryb2tlLXdpZHRoPSIxLjQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPgogICAgPHBhdGggZD0iTTI0IDM3UTE0IDM2IDggNDNRMTYgNTAgMjYgNDVMMjAgNDNaIi8+CiAgICA8cGF0aCBkPSJNNDkgMzdRMzkgMzYgMzMgNDNRNDEgNTAgNTEgNDVMNDUgNDNaIi8+CiAgICA8cGF0aCBkPSJNNzQgMzdRNjQgMzYgNTggNDNRNjYgNTAgNzYgNDVMNzAgNDNaIi8+CiAgICA8cGF0aCBkPSJNOTkgMzdRODkgMzYgODMgNDNROTEgNTAgOTkgNDVMOTUgNDNaIi8+CiAgPC9nPgogIDxnIGZpbGw9IiNjNTk4NjQiIHN0cm9rZT0iIzk3NjUzZiIgc3Ryb2tlLXdpZHRoPSIxLjMiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPgogICAgPHBhdGggZD0iTTE4IDUxUTkgNTAgMiA1N1E5IDY0IDIwIDU5TDE0IDU3WiIvPgogICAgPHBhdGggZD0iTTQzIDUxUTM0IDUwIDI3IDU3UTM0IDY0IDQ1IDU5TDM5IDU3WiIvPgogICAgPHBhdGggZD0iTTY4IDUxUTU5IDUwIDUyIDU3UTU5IDY0IDcwIDU5TDY0IDU3WiIvPgogICAgPHBhdGggZD0iTTkzIDUxUTg0IDUwIDc3IDU3UTg0IDY0IDk1IDU5TDg5IDU3WiIvPgogIDwvZz4KICA8cGF0aCBkPSJNMTIgNDJMMjEgNDFNMzcgNDJMNDYgNDFNNjIgNDJMNzEgNDFNODcgNDJMOTYgNDFNNiA1N0wxNCA1NU0zMSA1N0wzOSA1NU01NiA1N0w2NCA1NU04MSA1N0w4OSA1NSIgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjZTNiZDg0IiBzdHJva2Utd2lkdGg9IjEuNCIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIi8+Cjwvc3ZnPgo="


tailIcon : String
tailIcon =
    "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIiB2aWV3Qm94PSIwIDAgMTAwIDEwMCIgcm9sZT0iaW1nIiBhcmlhLWxhYmVsbGVkYnk9InRpdGxlIGRlc2MiPgogIDx0aXRsZSBpZD0idGl0bGUiPkVhZ2xlIHRhaWw8L3RpdGxlPgogIDxkZXNjIGlkPSJkZXNjIj5BIGZhbiBvZiBpdm9yeSB0YWlsIGZlYXRoZXJzIHdpdGggd2FybSBicm93biByb290cy4gVGhlIHJpZ2h0IGVkZ2Ugam9pbnMgdGhlIGJvZHkgZnJvbSB5IDI4IHRvIDcyLjwvZGVzYz4KICA8ZGVmcz4KICAgIDxsaW5lYXJHcmFkaWVudCBpZD0iZWFnbGUtdGFpbC1mZWF0aGVycyIgeDE9IjEwIiB5MT0iNTAiIHgyPSI3NCIgeTI9IjUwIiBncmFkaWVudFVuaXRzPSJ1c2VyU3BhY2VPblVzZSI+CiAgICAgIDxzdG9wIHN0b3AtY29sb3I9IiNmZmZkZjEiLz4KICAgICAgPHN0b3Agb2Zmc2V0PSIuNiIgc3RvcC1jb2xvcj0iI2VlZTJjOSIvPgogICAgICA8c3RvcCBvZmZzZXQ9IjEiIHN0b3AtY29sb3I9IiNiYTk2NjciLz4KICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICA8bGluZWFyR3JhZGllbnQgaWQ9ImVhZ2xlLXRhaWwtYm9keSIgeDE9IjAiIHkxPSIyOCIgeDI9IjAiIHkyPSI3MiIgZ3JhZGllbnRVbml0cz0idXNlclNwYWNlT25Vc2UiPgogICAgICA8c3RvcCBzdG9wLWNvbG9yPSIjNGMzMzJiIi8+CiAgICAgIDxzdG9wIG9mZnNldD0iLjQ1IiBzdG9wLWNvbG9yPSIjODA1MjM3Ii8+CiAgICAgIDxzdG9wIG9mZnNldD0iLjc1IiBzdG9wLWNvbG9yPSIjYjk4MjRlIi8+CiAgICAgIDxzdG9wIG9mZnNldD0iMSIgc3RvcC1jb2xvcj0iI2U2Y2JhMCIvPgogICAgPC9saW5lYXJHcmFkaWVudD4KICA8L2RlZnM+CiAgPGcgZmlsbD0idXJsKCNlYWdsZS10YWlsLWZlYXRoZXJzKSIgc3Ryb2tlPSIjYmRhYjg4IiBzdHJva2Utd2lkdGg9IjEuMyIgc3Ryb2tlLWxpbmVqb2luPSJyb3VuZCI+CiAgICA8cGF0aCBkPSJNNzggNDJMMjEgMTNRMTQgMTIgMTMgMTlMMTQgMjhMNjcgNTFaIi8+CiAgICA8cGF0aCBkPSJNNzMgNDNMMTEgMjZRNCAyNiA1IDM0TDcgNDJMNjUgNTRaIi8+CiAgICA8cGF0aCBkPSJNNzAgNDVMNyA0MlExIDQ0IDQgNTFMNyA1OUw2OCA1NloiLz4KICAgIDxwYXRoIGQ9Ik03MiA0OUw5IDU3UTMgNjAgOCA2N0wxMyA3NEw3MSA1OVoiLz4KICAgIDxwYXRoIGQ9Ik03NyA1M0wxNyA3MVExMSA3NSAxOCA4MkwyNCA4N0w3OCA2MVoiLz4KICA8L2c+CiAgPGcgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjZDRiZTk2IiBzdHJva2Utd2lkdGg9IjEuNSIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIj4KICAgIDxwYXRoIGQ9Ik0yMyAyM0w2NSA0Nk0xNCAzNEw2NCA0OU0xMiA1MEw2NSA1MU0xNSA2NEw2NiA1NU0yNSA3OEw3MCA1OCIvPgogIDwvZz4KICA8cGF0aCBmaWxsPSJ1cmwoI2VhZ2xlLXRhaWwtYm9keSkiIGQ9Ik0xMDAgMjhIODlDNzUgMjggNjkgMzcgNTcgNDFMNDggNDRMNTYgNTBMNDggNTVMNjAgNThDNzIgNjMgNzggNzIgOTEgNzJIMTAwWiIvPgogIDxwYXRoIGZpbGw9IiM0MzJkMjciIGQ9Ik0xMDAgMjhIODlDNzUgMjggNjkgMzcgNTcgNDFMNDggNDRMNjEgNDVDNzUgMzkgODEgMzQgOTEgMzRIMTAwWiIvPgogIDxwYXRoIGZpbGw9IiNlZmRhYjIiIGQ9Ik0xMDAgNjZIOTFDNzggNjYgNzAgNjAgNjAgNThDNzIgNjMgNzggNzIgOTEgNzJIMTAwWiIvPgogIDxwYXRoIGQ9Ik02OCA0NEw1OSA0OUw3MCA1Mk04NCA0Nkw3NSA1MUw4NiA1NSIgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjYzU5ODY0IiBzdHJva2Utd2lkdGg9IjIiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIgc3Ryb2tlLWxpbmVqb2luPSJyb3VuZCIvPgo8L3N2Zz4K"


bendIcon : String
bendIcon =
    "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIiB2aWV3Qm94PSIwIDAgMTAwIDEwMCIgcm9sZT0iaW1nIiBhcmlhLWxhYmVsbGVkYnk9InRpdGxlIGRlc2MiPgogIDx0aXRsZSBpZD0idGl0bGUiPkN1cnZlZCBlYWdsZSBib2R5PC90aXRsZT4KICA8ZGVzYyBpZD0iZGVzYyI+QSBmZWF0aGVyZWQgcXVhcnRlci1jaXJjbGUgYm9keSBqb2luaW5nIHRoZSBsZWZ0IGFuZCB0b3AgZWRnZXMgZnJvbSAyOCB0byA3Miwgd2l0aCBkYXJrIGZlYXRoZXJzIGluc2lkZSBhbmQgYSBjcmVhbSBiZWxseSBvdXRzaWRlLjwvZGVzYz4KICA8ZGVmcz4KICAgIDxyYWRpYWxHcmFkaWVudCBpZD0iZWFnbGUtYmVuZC1za2luIiBjeD0iMCIgY3k9IjAiIHI9IjcyIiBncmFkaWVudFVuaXRzPSJ1c2VyU3BhY2VPblVzZSI+CiAgICAgIDxzdG9wIG9mZnNldD0iLjM4ODg4OSIgc3RvcC1jb2xvcj0iIzRjMzMyYiIvPgogICAgICA8c3RvcCBvZmZzZXQ9Ii42NjM4ODkiIHN0b3AtY29sb3I9IiM4MDUyMzciLz4KICAgICAgPHN0b3Agb2Zmc2V0PSIuODQ3MjIyIiBzdG9wLWNvbG9yPSIjYjk4MjRlIi8+CiAgICAgIDxzdG9wIG9mZnNldD0iMSIgc3RvcC1jb2xvcj0iI2U2Y2JhMCIvPgogICAgPC9yYWRpYWxHcmFkaWVudD4KICA8L2RlZnM+CiAgPHBhdGggZmlsbD0idXJsKCNlYWdsZS1iZW5kLXNraW4pIiBkPSJNMCAyOEEyOCAyOCAwIDAgMCAyOCAwSDcyQTcyIDcyIDAgMCAxIDAgNzJaIi8+CiAgPHBhdGggZmlsbD0iIzQzMmQyNyIgZD0iTTAgMjhBMjggMjggMCAwIDAgMjggMEgzNEEzNCAzNCAwIDAgMSAwIDM0WiIvPgogIDxwYXRoIGZpbGw9IiNlZmRhYjIiIGQ9Ik0wIDY2QTY2IDY2IDAgMCAwIDY2IDBINzJBNzIgNzIgMCAwIDEgMCA3MloiLz4KICA8ZyBmaWxsPSIjYTg3OTRmIiBzdHJva2U9IiM2ODQzMmYiIHN0cm9rZS13aWR0aD0iMS40IiBzdHJva2UtbGluZWpvaW49InJvdW5kIj4KICAgIDxwYXRoIGQ9Ik04IDM2UTEwIDQ0IDE2IDQ3TDIyIDQwTDE3IDQxTDE1IDM0WiIvPgogICAgPHBhdGggZD0iTTI1IDI3UTI3IDM1IDM1IDM4TDM5IDI5TDM0IDMxTDMxIDIzWiIvPgogICAgPHBhdGggZD0iTTM2IDhRNDAgMTUgNDggMTdMNDkgOEw0NCAxMUw0MSA0WiIvPgogIDwvZz4KICA8ZyBmaWxsPSIjYzU5ODY0IiBzdHJva2U9IiM5NzY1M2YiIHN0cm9rZS13aWR0aD0iMS4zIiBzdHJva2UtbGluZWpvaW49InJvdW5kIj4KICAgIDxwYXRoIGQ9Ik04IDUyUTEwIDYxIDE3IDY0TDI0IDU3TDE4IDU3TDE2IDUwWiIvPgogICAgPHBhdGggZD0iTTM0IDQzUTM1IDUyIDQ0IDU1TDQ5IDQ2TDQ0IDQ3TDQxIDQwWiIvPgogICAgPHBhdGggZD0iTTUyIDIzUTU2IDMyIDY0IDMzTDY1IDI0TDYwIDI3TDU4IDE5WiIvPgogIDwvZz4KICA8cGF0aCBkPSJNMTMgMzhMMTcgNDNNMjkgMjlMMzQgMzNNNDAgOUw0NSAxMk0xMyA1NEwxOCA1OU0zOCA0NUw0NCA1ME01NiAyNEw2MSAyOCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjZTNiZDg0IiBzdHJva2Utd2lkdGg9IjEuNCIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIi8+Cjwvc3ZnPgo="


reversedBendIcon : String
reversedBendIcon =
    "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIiB2aWV3Qm94PSIwIDAgMTAwIDEwMCIgcm9sZT0iaW1nIiBhcmlhLWxhYmVsbGVkYnk9InRpdGxlIGRlc2MiPgogIDx0aXRsZSBpZD0idGl0bGUiPkN1cnZlZCBlYWdsZSBib2R5IHdpdGggcmV2ZXJzZWQgY29sb3JzPC90aXRsZT4KICA8ZGVzYyBpZD0iZGVzYyI+VGhlIG1hdGNoaW5nIHF1YXJ0ZXItY2lyY2xlIGJvZHkgd2l0aCBkYXJrIGZlYXRoZXJzIG91dHNpZGUgYW5kIGEgY3JlYW0gYmVsbHkgaW5zaWRlLCBmb3IgcmV2ZXJzZWQgYW5kIGJsZW5kZWQgdHVybnMuPC9kZXNjPgogIDxkZWZzPgogICAgPHJhZGlhbEdyYWRpZW50IGlkPSJlYWdsZS1iZW5kLXJldmVyc2VkLXNraW4iIGN4PSIwIiBjeT0iMCIgcj0iNzIiIGdyYWRpZW50VW5pdHM9InVzZXJTcGFjZU9uVXNlIj4KICAgICAgPHN0b3Agb2Zmc2V0PSIuMzg4ODg5IiBzdG9wLWNvbG9yPSIjZTZjYmEwIi8+CiAgICAgIDxzdG9wIG9mZnNldD0iLjU0MTY2NyIgc3RvcC1jb2xvcj0iI2I5ODI0ZSIvPgogICAgICA8c3RvcCBvZmZzZXQ9Ii43MjUiIHN0b3AtY29sb3I9IiM4MDUyMzciLz4KICAgICAgPHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjNGMzMzJiIi8+CiAgICA8L3JhZGlhbEdyYWRpZW50PgogIDwvZGVmcz4KICA8cGF0aCBmaWxsPSJ1cmwoI2VhZ2xlLWJlbmQtcmV2ZXJzZWQtc2tpbikiIGQ9Ik0wIDI4QTI4IDI4IDAgMCAwIDI4IDBINzJBNzIgNzIgMCAwIDEgMCA3MloiLz4KICA8cGF0aCBmaWxsPSIjZWZkYWIyIiBkPSJNMCAyOEEyOCAyOCAwIDAgMCAyOCAwSDM0QTM0IDM0IDAgMCAxIDAgMzRaIi8+CiAgPHBhdGggZmlsbD0iIzQzMmQyNyIgZD0iTTAgNjZBNjYgNjYgMCAwIDAgNjYgMEg3MkE3MiA3MiAwIDAgMSAwIDcyWiIvPgogIDxnIGZpbGw9IiNhODc5NGYiIHN0cm9rZT0iIzY4NDMyZiIgc3Ryb2tlLXdpZHRoPSIxLjQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPgogICAgPHBhdGggZD0iTTggMzZRMTAgNDQgMTYgNDdMMjIgNDBMMTcgNDFMMTUgMzRaIi8+CiAgICA8cGF0aCBkPSJNMjUgMjdRMjcgMzUgMzUgMzhMMzkgMjlMMzQgMzFMMzEgMjNaIi8+CiAgICA8cGF0aCBkPSJNMzYgOFE0MCAxNSA0OCAxN0w0OSA4TDQ0IDExTDQxIDRaIi8+CiAgPC9nPgogIDxnIGZpbGw9IiNjNTk4NjQiIHN0cm9rZT0iIzk3NjUzZiIgc3Ryb2tlLXdpZHRoPSIxLjMiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPgogICAgPHBhdGggZD0iTTggNTJRMTAgNjEgMTcgNjRMMjQgNTdMMTggNTdMMTYgNTBaIi8+CiAgICA8cGF0aCBkPSJNMzQgNDNRMzUgNTIgNDQgNTVMNDkgNDZMNDQgNDdMNDEgNDBaIi8+CiAgICA8cGF0aCBkPSJNNTIgMjNRNTYgMzIgNjQgMzNMNjUgMjRMNjAgMjdMNTggMTlaIi8+CiAgPC9nPgogIDxwYXRoIGQ9Ik0xMyAzOEwxNyA0M00yOSAyOUwzNCAzM000MCA5TDQ1IDEyTTEzIDU0TDE4IDU5TTM4IDQ1TDQ0IDUwTTU2IDI0TDYxIDI4IiBmaWxsPSJub25lIiBzdHJva2U9IiNlM2JkODQiIHN0cm9rZS13aWR0aD0iMS40IiBzdHJva2UtbGluZWNhcD0icm91bmQiLz4KPC9zdmc+Cg=="


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


directionToward : Position -> Position -> Direction
directionToward pos ahead =
    if nextHead Right pos == ahead then
        Right

    else if nextHead Left pos == ahead then
        Left

    else if nextHead Up pos == ahead then
        Up

    else
        Down


bodySegments : Position -> List Position -> List Segment
bodySegments ahead positions =
    case positions of
        [] ->
            []

        pos :: rest ->
            { part =
                case rest of
                    [] ->
                        EagleTail

                    behind :: _ ->
                        if isOpposite (directionToward pos ahead) (directionToward pos behind) then
                            EagleBody

                        else
                            EagleBend (directionToward pos behind)
            , direction = directionToward pos ahead
            , position = pos
            }
                :: bodySegments pos rest


eagleSegments : Model -> List Segment
eagleSegments model =
    { part = EagleHead, direction = model.direction, position = model.head }
        :: bodySegments model.head model.body



-- The base bend joins Left and Up. Both traversal orders use the same shape.


cornerRotation : Direction -> Direction -> Int
cornerRotation ahead behind =
    if List.member Left [ ahead, behind ] && List.member Up [ ahead, behind ] then
        0

    else if List.member Up [ ahead, behind ] && List.member Right [ ahead, behind ] then
        90

    else if List.member Right [ ahead, behind ] && List.member Down [ ahead, behind ] then
        180

    else
        270


oppositeDirection : Direction -> Direction
oppositeDirection direction =
    case direction of
        Up ->
            Down

        Down ->
            Up

        Left ->
            Right

        Right ->
            Left



-- Horizontal sprites stay upright when mirrored, so their dark feather band stays on top.


featherSide : Direction -> Direction
featherSide direction =
    case direction of
        Up ->
            Left

        Down ->
            Right

        _ ->
            Up



-- Whether the dark feather band belongs inside at the base tile's Left and Up endpoints.


cornerColors : Direction -> Direction -> ( Bool, Bool )
cornerColors ahead behind =
    let
        ( ( leftEdge, leftInside ), ( topEdge, topInside ) ) =
            case cornerRotation ahead behind of
                0 ->
                    ( ( Left, Up ), ( Up, Left ) )

                90 ->
                    ( ( Up, Right ), ( Right, Up ) )

                180 ->
                    ( ( Right, Down ), ( Down, Right ) )

                _ ->
                    ( ( Down, Left ), ( Left, Down ) )

        matchesInside edge inside =
            featherSide
                (if edge == ahead then
                    ahead

                 else
                    oppositeDirection behind
                )
                == inside
    in
    ( matchesInside leftEdge leftInside, matchesInside topEdge topInside )


drawEagleImage : String -> List (Svg.Attribute msg) -> Svg msg
drawEagleImage icon attributes =
    Svg.image
        ([ SA.xlinkHref icon
         , SA.x (String.fromInt (negate cellSize // 2))
         , SA.y (String.fromInt (negate cellSize // 2))
         , SA.width (String.fromInt cellSize)
         , SA.height (String.fromInt cellSize)
         ]
            ++ attributes
        )
        []


drawBend : Segment -> Direction -> Svg msg
drawBend segment behind =
    let
        ( leftInside, topInside ) =
            cornerColors segment.direction behind

        baseIcon =
            if leftInside then
                bendIcon

            else
                reversedBendIcon

        topIcon =
            if topInside then
                bendIcon

            else
                reversedBendIcon

        maskId =
            "bend-mask-" ++ String.fromInt segment.position.x ++ "-" ++ String.fromInt segment.position.y

        gradientId =
            maskId ++ "-gradient"

        low =
            String.fromFloat (toFloat cellSize * -0.5)

        edge =
            String.fromFloat (toFloat cellSize * -0.22)

        size =
            String.fromInt cellSize
    in
    if leftInside == topInside then
        drawEagleImage baseIcon []

    else
        Svg.g []
            [ Svg.defs []
                [ Svg.linearGradient
                    [ SA.id gradientId
                    , SA.gradientUnits "userSpaceOnUse"
                    , SA.x1 low
                    , SA.y1 edge
                    , SA.x2 edge
                    , SA.y2 low
                    ]
                    [ Svg.stop [ SA.offset "0", SA.stopColor "black" ] []
                    , Svg.stop [ SA.offset "1", SA.stopColor "white" ] []
                    ]
                , Svg.mask
                    [ SA.id maskId
                    , SA.maskUnits "userSpaceOnUse"
                    , SA.maskContentUnits "userSpaceOnUse"
                    , SA.x low
                    , SA.y low
                    , SA.width size
                    , SA.height size
                    ]
                    [ rect
                        [ SA.x low
                        , SA.y low
                        , SA.width size
                        , SA.height size
                        , SA.fill ("url(#" ++ gradientId ++ ")")
                        ]
                        []
                    ]
                ]
            , drawEagleImage baseIcon []
            , drawEagleImage topIcon [ SA.mask ("url(#" ++ maskId ++ ")") ]
            ]


drawEagleSegment : Segment -> Svg msg
drawEagleSegment segment =
    let
        px =
            segment.position.x * cellSize

        py =
            segment.position.y * cellSize

        artwork =
            case segment.part of
                EagleHead ->
                    drawEagleImage headIcon []

                EagleBody ->
                    drawEagleImage bodyIcon []

                EagleBend behind ->
                    drawBend segment behind

                EagleTail ->
                    drawEagleImage tailIcon []

        orientation =
            case segment.part of
                EagleBend behind ->
                    "rotate(" ++ String.fromInt (cornerRotation segment.direction behind) ++ ")"

                _ ->
                    case segment.direction of
                        Right ->
                            "scale(1 1)"

                        Left ->
                            "scale(-1 1)"

                        Up ->
                            "rotate(-90)"

                        Down ->
                            "rotate(90)"
    in
    Svg.g
        [ SA.transform
            ("translate("
                ++ String.fromInt (px + cellSize // 2)
                ++ " "
                ++ String.fromInt (py + cellSize // 2)
                ++ ") "
                ++ orientation
            )
        ]
        [ artwork ]


drawFoodHalo : Position -> Svg msg
drawFoodHalo pos =
    Svg.circle
        [ SA.cx (String.fromInt (pos.x * cellSize + cellSize // 2))
        , SA.cy (String.fromInt (pos.y * cellSize + cellSize // 2))
        , SA.r (String.fromInt (cellSize // 2 - 1))
        , SA.fill "#facc15"
        , SA.fillOpacity "0.3"
        , SA.stroke "#facc15"
        , SA.strokeWidth "2"
        ]
        []


drawFood : FoodType -> Position -> Svg msg
drawFood foodType pos =
    Svg.image
        [ SA.xlinkHref (foodIcon foodType)
        , SA.x (String.fromInt (pos.x * cellSize))
        , SA.y (String.fromInt (pos.y * cellSize))
        , SA.width (String.fromInt cellSize)
        , SA.height (String.fromInt cellSize)
        ]
        [ Svg.title [] [ Svg.text (foodName foodType) ] ]


drawBoard : List (Svg msg)
drawBoard =
    List.concatMap
        (\row ->
            List.map
                (\col -> drawCell "#0a1628" { x = col, y = row })
                (List.range 0 (gridSize - 1))
        )
        (List.range 0 (gridSize - 1))


skyCss : String
skyCss =
    """
body { margin: 0; }

.sky {
    position: relative;
    overflow: hidden;
    min-height: 100vh;
    box-sizing: border-box;
    padding: 24px;
    background: #071225;
    display: grid;
    place-items: center;
}

.cloud {
    position: absolute;
    left: 0;
    width: 240px;
    height: 90px;
    fill: #dbeafe;
    opacity: 0.06;
    pointer-events: none;
    animation: drift 90s linear infinite;
}

.cloud-one { top: 12%; animation-delay: -30s; }
.cloud-two { top: 70%; animation-duration: 110s; animation-delay: -80s; }

.sky-game { position: relative; }

@keyframes drift {
    from { transform: translateX(-260px); }
    to   { transform: translateX(100vw); }
}

@media (prefers-reduced-motion: reduce) {
    .cloud { animation: none; left: 8%; }
    .cloud-two { left: 60%; }
}
"""


cloud : String -> Html msg
cloud name =
    Svg.svg
        [ SA.class ("cloud " ++ name)
        , SA.viewBox "0 0 240 90"
        , SA.width "240"
        , SA.height "90"
        , Html.Attributes.attribute "aria-hidden" "true"
        , Html.Attributes.attribute "focusable" "false"
        ]
        [ Svg.ellipse [ SA.cx "120", SA.cy "62", SA.rx "105", SA.ry "24" ] []
        , Svg.circle [ SA.cx "85", SA.cy "48", SA.r "28" ] []
        , Svg.circle [ SA.cx "140", SA.cy "38", SA.r "34" ] []
        ]


withSky : Html msg -> Html msg
withSky game =
    div [ class "sky" ]
        [ node "style" [] [ text skyCss ]
        , cloud "cloud-one"
        , cloud "cloud-two"
        , div [ class "sky-game" ] [ game ]
        ]


view : Model -> Html Msg
view model =
    withSky (viewGame model)


viewGame : Model -> Html Msg
viewGame model =
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
                [ text ("Score: " ++ String.fromInt model.score) ]
            , p [ style "color" "#1d4ed8", style "margin" "0" ]
                [ text ("Best: " ++ String.fromInt model.highScore) ]
            ]
         , p [ style "color" "#e6cba0", style "margin" "0 0 8px 0" ]
            [ text ("Prey caught: " ++ String.fromInt model.foodEaten) ]
         , p [ style "color" "#e6cba0", style "margin" "0 0 8px 0" ]
            [ text
                ("Next prey: "
                    ++ foodName model.foodType
                    ++ (if isGoldenFood model.foodEaten then
                            " (golden! +3 points)"

                        else
                            " (+1 point)"
                       )
                )
            ]
         , svg
            [ SA.width (String.fromInt (gridSize * cellSize))
            , SA.height (String.fromInt (gridSize * cellSize))
            ]
            (drawBoard
                ++ List.map drawEagleSegment (eagleSegments model)
                ++ (if isGoldenFood model.foodEaten then
                        [ drawFoodHalo model.food ]

                    else
                        []
                   )
                ++ [ drawFood model.foodType model.food ]
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
        { init = \_ -> ( initialModel, Task.perform InitializeFood Time.now )
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
