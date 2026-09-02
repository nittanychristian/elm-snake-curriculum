-- Eagle Strike — Week 5 solution with school colors (blue & green) and eagle mascot.
-- Changes from Week 4:
--   - School color scheme: navy board, green body, white eagle head, gold beak
--   - Eagle head SVG: beak points in the direction of travel, eye dot
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
import Svg exposing (Svg, circle, polygon, rect, svg)
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
        ( Up, Down ) -> True
        ( Down, Up ) -> True
        ( Left, Right ) -> True
        ( Right, Left ) -> True
        _ -> False


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

-- Helper to format an SVG coordinate pair
pt : Int -> Int -> String
pt x y =
    String.fromInt x ++ "," ++ String.fromInt y


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


-- Draw the eagle head: white cell + gold beak pointing in direction of travel + dark eye
drawEagleHead : Direction -> Position -> List (Svg msg)
drawEagleHead dir pos =
    let
        px =
            pos.x * cellSize

        py =
            pos.y * cellSize

        -- Beak: triangle pointing in the direction of travel
        beakPoints =
            case dir of
                Right ->
                    pt (px + 20) (py + 10) ++ " " ++ pt (px + 14) (py + 6) ++ " " ++ pt (px + 14) (py + 14)

                Left ->
                    pt px (py + 10) ++ " " ++ pt (px + 6) (py + 6) ++ " " ++ pt (px + 6) (py + 14)

                Up ->
                    pt (px + 10) py ++ " " ++ pt (px + 6) (py + 6) ++ " " ++ pt (px + 14) (py + 6)

                Down ->
                    pt (px + 10) (py + 20) ++ " " ++ pt (px + 6) (py + 14) ++ " " ++ pt (px + 14) (py + 14)

        -- Eye position shifts to the "front" of the head
        ( eyeX, eyeY ) =
            case dir of
                Right ->
                    ( px + 13, py + 7 )

                Left ->
                    ( px + 7, py + 7 )

                Up ->
                    ( px + 13, py + 9 )

                Down ->
                    ( px + 13, py + 11 )
    in
    [ -- White eagle head
      rect
        [ SA.x (String.fromInt px)
        , SA.y (String.fromInt py)
        , SA.width (String.fromInt cellSize)
        , SA.height (String.fromInt cellSize)
        , SA.fill "#f0ede0"
        , SA.rx "4"
        ]
        []
    , -- Gold beak
      polygon
        [ SA.points beakPoints
        , SA.fill "#eab308"
        ]
        []
    , -- Dark eye
      circle
        [ SA.cx (String.fromInt eyeX)
        , SA.cy (String.fromInt eyeY)
        , SA.r "2"
        , SA.fill "#0a1628"
        ]
        []
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
        "ArrowUp" -> KeyPressed Up
        "ArrowDown" -> KeyPressed Down
        "ArrowLeft" -> KeyPressed Left
        "ArrowRight" -> KeyPressed Right
        "r" -> Restart
        "R" -> Restart
        _ -> Ignore


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
