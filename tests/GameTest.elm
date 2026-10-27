module GameTest exposing (suite)

import Expect
import Fuzz
import Game exposing (Direction(..), DragonPart(..), FoodType(..), GameStatus(..), Model, Msg(..), Position)
import Random
import Set
import Test exposing (Test, describe, fuzz2, test)
import Time


suite : Test
suite =
    describe "Dragon Strike"
        [ movementTests
        , segmentTests
        , cornerTests
        , gameplayTests
        , foodTests
        ]


movementTests : Test
movementTests =
    describe "Movement and wrapping"
        [ test "moving right increases x by one" <|
            \_ ->
                Game.nextHead Right { x = 5, y = 7 }
                    |> Expect.equal { x = 6, y = 7 }
        , test "moving up decreases y by one" <|
            \_ ->
                Game.nextHead Up { x = 5, y = 7 }
                    |> Expect.equal { x = 5, y = 6 }
        , describe "Each edge wraps to the opposite edge"
            (List.map
                (\( name, direction, start ) ->
                    test name <|
                        \_ ->
                            Game.nextHead direction start
                                |> Expect.equal
                                    (case direction of
                                        Right ->
                                            { start | x = 0 }

                                        Left ->
                                            { start | x = Game.gridSize - 1 }

                                        Up ->
                                            { start | y = Game.gridSize - 1 }

                                        Down ->
                                            { start | y = 0 }
                                    )
                )
                [ ( "right edge", Right, { x = Game.gridSize - 1, y = 5 } )
                , ( "left edge", Left, { x = 0, y = 5 } )
                , ( "top edge", Up, { x = 5, y = 0 } )
                , ( "bottom edge", Down, { x = 5, y = Game.gridSize - 1 } )
                ]
            )
        , test "all board positions identify their four neighbors, including wrapped neighbors" <|
            \_ ->
                List.concatMap
                    (\pos ->
                        List.map
                            (\direction ->
                                ( pos, direction, Game.directionToward pos (Game.nextHead direction pos) )
                            )
                            directions
                    )
                    positions
                    |> Expect.equal
                        (List.concatMap (\pos -> List.map (\direction -> ( pos, direction, direction )) directions) positions)
        , fuzz2 (Fuzz.intRange 0 (Game.gridSize - 1))
            (Fuzz.intRange 0 (Game.gridSize - 1))
            "right followed by left returns to the starting position"
          <|
            \x y ->
                { x = x, y = y }
                    |> Game.nextHead Right
                    |> Game.nextHead Left
                    |> Expect.equal { x = x, y = y }
        ]


segmentTests : Test
segmentTests =
    describe "Head, body, and tail"
        [ test "the initial dragon has one head, one body, and one tail" <|
            \_ ->
                summary Game.initialModel
                    |> Expect.equal
                        [ ( DragonHead, Right, { x = 10, y = 10 } )
                        , ( DragonBody, Right, { x = 9, y = 10 } )
                        , ( DragonTail, Right, { x = 8, y = 10 } )
                        ]
        , test "each segment follows its own neighbors at successive bends" <|
            \_ ->
                let
                    initial =
                        Game.initialModel
                in
                summary
                    { initial
                        | head = { x = 5, y = 4 }
                        , body = [ { x = 5, y = 5 }, { x = 4, y = 5 }, { x = 4, y = 6 } ]
                        , direction = Up
                    }
                    |> Expect.equal
                        [ ( DragonHead, Up, { x = 5, y = 4 } )
                        , ( DragonBend Left, Up, { x = 5, y = 5 } )
                        , ( DragonBend Down, Right, { x = 4, y = 5 } )
                        , ( DragonTail, Up, { x = 4, y = 6 } )
                        ]
        , test "an empty body renders just the head" <|
            \_ ->
                let
                    initial =
                        Game.initialModel
                in
                summary { initial | body = [] }
                    |> Expect.equal [ ( DragonHead, Right, initial.head ) ]
        , test "a single body position renders as the tail" <|
            \_ ->
                let
                    initial =
                        Game.initialModel
                in
                summary { initial | body = [ { x = 9, y = 10 } ] }
                    |> Expect.equal
                        [ ( DragonHead, Right, initial.head )
                        , ( DragonTail, Right, { x = 9, y = 10 } )
                        ]
        , test "opposite neighbors use the straight body in every direction" <|
            \_ ->
                List.map
                    (\( ahead, behind ) ->
                        Game.bodySegments (Game.nextHead ahead center) [ center, Game.nextHead behind center ]
                            |> List.head
                            |> Maybe.map .part
                    )
                    [ ( Left, Right ), ( Right, Left ), ( Up, Down ), ( Down, Up ) ]
                    |> Expect.equal (List.repeat 4 (Just DragonBody))
        ]


cornerTests : Test
cornerTests =
    describe "Curved bodies and matching color bands"
        (List.map
            (\( ( ahead, behind ), ( rotation, colors ) ) ->
                describe (directionName ahead ++ " ahead, " ++ directionName behind ++ " behind")
                    [ test "uses the correct corner rotation and endpoint palettes" <|
                        \_ ->
                            ( Game.cornerRotation ahead behind, Game.cornerColors ahead behind )
                                |> Expect.equal ( rotation, colors )
                    , test "chooses a bend at every position, including wrapped board edges" <|
                        \_ ->
                            List.map
                                (\pos ->
                                    Game.bodySegments (Game.nextHead ahead pos) [ pos, Game.nextHead behind pos ]
                                        |> List.head
                                        |> Maybe.map (\segment -> ( segment.part, segment.direction, segment.position ))
                                )
                                positions
                                |> Expect.equal
                                    (List.map (\pos -> Just ( DragonBend behind, ahead, pos )) positions)
                    ]
            )
            [ ( ( Up, Left ), ( 0, ( True, True ) ) )
            , ( ( Left, Up ), ( 0, ( True, False ) ) )
            , ( ( Right, Up ), ( 90, ( True, True ) ) )
            , ( ( Up, Right ), ( 90, ( False, True ) ) )
            , ( ( Down, Right ), ( 180, ( False, True ) ) )
            , ( ( Right, Down ), ( 180, ( False, False ) ) )
            , ( ( Down, Left ), ( 270, ( False, False ) ) )
            , ( ( Left, Down ), ( 270, ( True, False ) ) )
            ]
        )


gameplayTests : Test
gameplayTests =
    describe "Gameplay"
        [ test "ordinary movement advances the tail without growing" <|
            \_ ->
                let
                    segments =
                        Game.tickGame Game.initialModel |> summary
                in
                ( List.length segments, List.reverse segments |> List.head )
                    |> Expect.equal ( 3, Just ( DragonTail, Right, { x = 9, y = 10 } ) )
        , test "eating grows the body, keeps the tail position, and awards a point" <|
            \_ ->
                let
                    initial =
                        Game.initialModel

                    afterEating =
                        Game.tickGame { initial | food = { x = 11, y = 10 } }
                in
                ( List.map .part (Game.dragonSegments afterEating), List.reverse afterEating.body |> List.head, afterEating.score )
                    |> Expect.equal ( [ DragonHead, DragonBody, DragonBody, DragonTail ], Just { x = 8, y = 10 }, 1 )
        , test "restart restores the initial dragon and preserves the best score" <|
            \_ ->
                let
                    initial =
                        Game.initialModel

                    restarted =
                        Game.update Restart { initial | highScore = 12, score = 4, status = GameOver }
                            |> Tuple.first
                in
                restarted
                    |> Expect.equal
                        { initial
                            | highScore = 12
                            , foodType = restarted.foodType
                            , randomSeed = restarted.randomSeed
                        }
        , test "a game-over tick leaves the model unchanged" <|
            \_ ->
                let
                    initial =
                        Game.initialModel

                    stopped =
                        { initial | status = GameOver }
                in
                Game.tickGame stopped |> Expect.equal stopped
        , test "the dragon cannot reverse directly into its neck" <|
            \_ ->
                Game.update (KeyPressed Left) Game.initialModel
                    |> Tuple.first
                    |> .direction
                    |> Expect.equal Right
        , test "turning upwards is accepted when moving right" <|
            \_ ->
                Game.update (KeyPressed Up) Game.initialModel
                    |> Tuple.first
                    |> .direction
                    |> Expect.equal Up
        ]


foodTests : Test
foodTests =
    describe "Variable prey"
        [ test "the catalogue contains exactly ten named prey types" <|
            \_ ->
                List.map Game.foodName Game.allFoodTypes
                    |> Expect.equal [ "Mouse", "Vole", "Rat", "Rabbit", "Squirrel", "Duck", "Quail", "Snake", "Lizard", "Frog" ]
        , test "each prey type has its own embedded SVG" <|
            \_ ->
                let
                    icons =
                        List.map Game.foodIcon Game.allFoodTypes
                in
                ( Set.size (Set.fromList icons), List.all (String.startsWith "data:image/svg+xml;base64,") icons )
                    |> Expect.equal ( 10, True )
        , test "all 2000 choices belong to the catalogue and exclude the previous type" <|
            \_ ->
                List.concatMap
                    (\current ->
                        List.filterMap
                            (\seedNumber ->
                                let
                                    ( chosen, _ ) =
                                        Random.step (Game.differentFood current) (Random.initialSeed seedNumber)
                                in
                                if chosen /= current && List.member chosen Game.allFoodTypes then
                                    Nothing

                                else
                                    Just ( Game.foodName current, seedNumber, Game.foodName chosen )
                            )
                            (List.range 0 199)
                    )
                    Game.allFoodTypes
                    |> Expect.equal []
        , test "all nine alternatives can be selected for every current type" <|
            \_ ->
                List.map
                    (\current ->
                        Random.step (Random.list 500 (Game.differentFood current)) (Random.initialSeed 42)
                            |> Tuple.first
                            |> List.map Game.foodName
                            |> Set.fromList
                    )
                    Game.allFoodTypes
                    |> Expect.equal
                        (List.map
                            (\current ->
                                Game.allFoodTypes
                                    |> List.filter ((/=) current)
                                    |> List.map Game.foodName
                                    |> Set.fromList
                            )
                            Game.allFoodTypes
                        )
        , test "ordinary movement preserves the food type and random seed" <|
            \_ ->
                let
                    initial =
                        Game.initialModel

                    moved =
                        Game.tickGame initial
                in
                ( moved.foodType, moved.randomSeed )
                    |> Expect.equal ( initial.foodType, initial.randomSeed )
        , test "catching each prey changes type, advances randomness, and still awards one point" <|
            \_ ->
                let
                    initial =
                        Game.initialModel
                in
                List.filter
                    (\current ->
                        let
                            hungry =
                                { initial | food = Game.nextHead initial.direction initial.head, foodType = current }

                            caught =
                                Game.tickGame hungry
                        in
                        caught.foodType
                            == current
                            || not (List.member caught.foodType Game.allFoodTypes)
                            || caught.randomSeed
                            == hungry.randomSeed
                            || caught.score
                            /= 1
                            || caught.food
                            == hungry.food
                    )
                    Game.allFoodTypes
                    |> Expect.equal []
        , test "restart chooses another prey type, advances randomness, and preserves the best score" <|
            \_ ->
                let
                    initial =
                        Game.initialModel
                in
                List.filter
                    (\current ->
                        let
                            previous =
                                { initial | foodType = current, highScore = 12, score = 4 }

                            restarted =
                                Game.update Restart previous |> Tuple.first
                        in
                        restarted.foodType
                            == current
                            || restarted.randomSeed
                            == previous.randomSeed
                            || restarted.highScore
                            /= 12
                            || restarted.score
                            /= 0
                    )
                    Game.allFoodTypes
                    |> Expect.equal []
        , test "clock initialization preserves gameplay and chooses valid prey" <|
            \_ ->
                let
                    initial =
                        Game.initialModel

                    initialized =
                        Game.update (InitializeFood (Time.millisToPosix 123456)) initial |> Tuple.first
                in
                Expect.all
                    [ \model -> Expect.equal True (List.member model.foodType Game.allFoodTypes)
                    , \model -> Expect.notEqual initial.randomSeed model.randomSeed
                    , \model ->
                        Expect.equal
                            { initial | foodType = model.foodType, randomSeed = model.randomSeed }
                            model
                    ]
                    initialized
        , test "clock initialization can select all ten types rather than a fixed starting choice" <|
            \_ ->
                List.range 0 999
                    |> List.map
                        (\millis ->
                            Game.update (InitializeFood (Time.millisToPosix millis)) Game.initialModel
                                |> Tuple.first
                                |> .foodType
                                |> Game.foodName
                        )
                    |> Set.fromList
                    |> Expect.equal
                        (Set.fromList (List.map Game.foodName Game.allFoodTypes))
        ]


summary : Model -> List ( Game.DragonPart, Direction, Position )
summary model =
    List.map (\segment -> ( segment.part, segment.direction, segment.position )) (Game.dragonSegments model)


directions : List Direction
directions =
    [ Up, Down, Left, Right ]


positions : List Position
positions =
    List.concatMap
        (\x -> List.map (\y -> { x = x, y = y }) (List.range 0 (Game.gridSize - 1)))
        (List.range 0 (Game.gridSize - 1))


center : Position
center =
    { x = 5, y = 5 }


directionName : Direction -> String
directionName direction =
    case direction of
        Up ->
            "Up"

        Down ->
            "Down"

        Left ->
            "Left"

        Right ->
            "Right"
