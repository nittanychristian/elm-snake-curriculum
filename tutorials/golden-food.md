# Catch golden food

Every fifth piece of food gets a golden halo. Catch it to earn **three points**! Other food is worth one point. The eagle grows one segment for either kind.

You will practice a counter, `modBy`, an `if` expression, and drawing SVG shapes on top of each other.

## 1. Try the example

Open [the complete example](examples/golden-food/Main.elm). Copy it into the Elm editor at https://ellie-app.com/ and click **Compile**. Use your arrow keys to fly. If needed, add **elm/svg 1.0.1** in Ellie's Packages panel. You do not need a server or a terminal.

The example uses a small red food circle so you can clearly see its halo. The finished [src/Game.elm](../src/Game.elm) includes the same bonus with the illustrated prey. If you already have that version, jump to **Try your own rules** below.

For a local checkout with Nix installed:

```sh
nix develop
just dev tutorials/examples/golden-food
```

The following steps explain how to add the feature to an earlier version of your game. Keep your own artwork and movement rules.

## 2. Count catches separately from points

Add a field inside `type alias Model`:

```elm
    , foodEaten : Int
```

Add its starting value inside `initialModel`:

```elm
    , foodEaten = 0
```

Why two counters? After five catches, you have **five prey** but **seven points**: `1 + 1 + 1 + 1 + 3`. We use catches to decide when the next bonus appears.

## 3. Find every fifth piece

Add these two functions above `tickGame`:

```elm
isGoldenFood : Int -> Bool
isGoldenFood foodEaten =
    modBy 5 (foodEaten + 1) == 0


foodPoints : Int -> Int
foodPoints foodEaten =
    if isGoldenFood foodEaten then
        3

    else
        1
```

`modBy` finds the remainder after division. `modBy 5 5` is `0`, but `modBy 5 6` is `1`.

`foodEaten` counts the pieces you **already caught**. Adding one gives the number of the piece currently on the board.

| Already caught | Current piece | Golden? | Points for catching it |
| --- | --- | --- | --- |
| 0 | 1st | No | 1 |
| 3 | 4th | No | 1 |
| 4 | 5th | Yes | 3 |
| 5 | 6th | No | 1 |
| 9 | 10th | Yes | 3 |

Predict the result of `isGoldenFood 14` before trying it.

## 4. Award points and count the catch

Inside `tickGame`, find the `newScore` definition. Replace it with:

```elm
                newScore =
                    if ateFood then
                        model.score + foodPoints model.foodEaten

                    else
                        model.score
```

Near the end of `tickGame`, find the record update containing `score = newScore`. Add this field alongside it:

```elm
                , foodEaten =
                    if ateFood then
                        model.foodEaten + 1

                    else
                        model.foodEaten
```

Both calculations read the old model. On the fifth catch, the old counter is `4`, so `foodPoints 4` gives `3`. The new counter becomes `5`, making the sixth piece ordinary.

Keep the body-growth code as it is. Three points still means one new body segment.

If your game has restart, reset `foodEaten` to `0` along with the score. The finished game's restart already starts from `initialModel`, which handles this for us and keeps the best score separately.

## 5. Draw a halo behind the food

Add this function near your other drawing functions. It uses the same `Svg` and `Svg.Attributes as SA` imports as the game:

```elm
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
```

`pos.x * cellSize` finds the left edge of the food's cell. Adding half a cell moves to its center. The circle's fill is partly transparent, and its outline is solid gold.

In the list of shapes for your board, insert this **immediately before the food drawing**:

```elm
                ++ (if isGoldenFood model.foodEaten then
                        [ drawFoodHalo model.food ]

                    else
                        []
                   )
```

For example, with the illustrated prey, the end of the board's shape list becomes:

```elm
                ++ List.map drawEagleSegment (eagleSegments model)
                ++ (if isGoldenFood model.foodEaten then
                        [ drawFoodHalo model.food ]

                    else
                        []
                   )
                ++ [ drawFood model.foodType model.food ]
```

SVG draws later shapes on top of earlier ones. Putting the halo first places it behind the prey image.

If your food is a square that covers the whole cell, it will hide the halo! The tutorial example draws a smaller circle instead. You can copy its food drawing or use your custom SVG image.

## 6. Tell the player what the numbers mean

Change your score label to use **Score**:

```elm
[ text ("Score: " ++ String.fromInt model.score) ]
```

Show a separate catch counter and a text hint near the board. These are HTML elements you can add next to the existing score paragraph:

```elm
p [ style "color" "#e6cba0" ]
    [ text ("Prey caught: " ++ String.fromInt model.foodEaten) ]
```

```elm
p [ style "color" "#eab308" ]
    [ text
        (if isGoldenFood model.foodEaten then
            "Golden food! +3 points"

         else
            "Food: +1 point"
        )
    ]
```

Remember the separating commas when adding elements to your existing list. The text hint means players can recognize the bonus without relying only on its color. In the finished game, the hint appears beside the current prey's name.

## 7. Check your rule with an Elm test

You can check the rule without playing a whole game. If you have the repository's local test setup, create `tests/GoldenFoodTest.elm`:

```elm
module GoldenFoodTest exposing (suite)

import Expect
import Game
import Test exposing (Test, test)


suite : Test
suite =
    test "four catches make the next prey worth three points" <|
        \_ ->
            Game.foodPoints 4
                |> Expect.equal 3
```

The finished game's module exposes `foodPoints` for tests. If you are adding the helper yourself, add `foodPoints` to `module Game exposing (...)` too. You can run the tests with `nix develop -c just test`. See [the Elm testing tutorial](testing-elm.md) for the setup and how to write more tests.

This uses the repository's `Game` module; it is a separate local testing step from running the `Main` example in Ellie. Ellie users can test the rules by playing and watching the score.

## Check your work

- The first four catches each give one point.
- After four catches, the next food has a golden halo and a three-point hint.
- Catching it changes the catch count to **5** and the score to **7**.
- The sixth piece is ordinary again. The tenth is golden. Ten catches give **14 points**.
- Flying around without catching food keeps the current bonus and counters unchanged.
- If your version has restart, it returns to zero catches and ordinary food while keeping your best score.

For a quick visual check, temporarily set `foodEaten = 4` in `initialModel` and compile. The first piece on screen should have a halo. Set it back to `0` afterward.

## Try your own rules

Change one thing at a time:

- Replace `5` in `isGoldenFood` with `3`. Which pieces become golden?
- Change the golden reward from `3` to `5` in `foodPoints`. Update the text hint and tests too.
- Give the halo a different color by changing both `fill` and `stroke`.

Before compiling, predict the score after ten catches under your new rule.
