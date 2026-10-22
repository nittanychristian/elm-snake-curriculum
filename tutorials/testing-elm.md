# Write tests for your Elm game

A test is a small example that asks, “Did this code do what I expected?” Tests let you check movement, growth, and turns without playing through the same situation every time.

Elm checks that your types fit together. Tests check the behavior you wanted. A game can compile and still award the wrong number of points.

## 1. Try a check in Ellie

Open your Week 5 game at https://ellie-app.com/. The repository's starter is [week5/Main.elm](../week5/Main.elm); the finished version is [src/Game.elm](../src/Game.elm).

You can run simple checks in the browser without installing anything. Add these definitions to the same Elm file as your game:

```elm
checks : List ( String, Bool )
checks =
    [ ( "Moving right increases x by one"
      , nextHead Right { x = 5, y = 7 } == { x = 6, y = 7 }
      )
    , ( "An ordinary tick does not award a point"
      , (tickGame initialModel |> .score) == 0
      )
    ]


checkResults : Html msg
checkResults =
    div []
        (List.map
            (\( name, passed ) ->
                p []
                    [ text
                        ((if passed then
                            "PASS: "

                          else
                            "FAIL: "
                         )
                            ++ name
                        )
                    ]
            )
            checks
        )
```

The starter already imports `Html`, `div`, `p`, and `text`. In `view`, add `checkResults` as the first item in the outer `div`'s list of children, before `h1`:

```elm
([ checkResults
 , h1
```

Keep the rest of `view` in place. Click **Compile** and look for two `PASS` messages above the game.

These checks call your actual game functions in the same file. You do not need to copy the movement rules into a second program.

## 2. Make a check fail on purpose

In the first check, change the expected position from `{ x = 6, y = 7 }` to `{ x = 7, y = 7 }`. Compile again.

The check should now say `FAIL`: moving once from column 5 should reach column 6, not column 7. Restore the correct expected value afterward.

This experiment shows that the check can catch a mistake. When writing your own test, choose the expected answer yourself; do not calculate it by calling the same function twice.

## 3. Use the standard Elm testing tools locally

For a whole project, the `elm-explorations/test` package gives failures helpful names and displays expected and actual values. The `elm-test` command runs those tests. These are two different pieces: a library for writing tests and a runner for executing them.

Official references:

- Tests: https://package.elm-lang.org/packages/elm-explorations/test/2.2.1/Test
- Expectations: https://package.elm-lang.org/packages/elm-explorations/test/2.2.1/Expect
- Fuzzers: https://package.elm-lang.org/packages/elm-explorations/test/2.2.1/Fuzz
- Test runner: https://github.com/rtfeldman/node-test-runner

This part needs a local checkout and Nix, such as your teacher's development environment. On a school Chromebook with Ellie, use the checks above and ask your teacher to run the full suite. Ellie's Compile button does not run the local `elm-test` command.

From the project directory:

```sh
nix develop
just test
```

Or run both steps with:

```sh
nix develop -c just test
```

The project already declares the test package in `elm.json` and provides the runner through Nix. You do not need a global package installation.

The repository's tests are in [tests/GameTest.elm](../tests/GameTest.elm). `just test` runs `elm-test`, which finds this suite and imports the real [src/Game.elm](../src/Game.elm).

The application's source directory in `elm.json` is `"src"`. Tests go in `tests/`, while the runner's generated files go in `elm-stuff/`. Keeping these directories separate avoids overlapping source directories. Add tests to `GameTest.elm`, or create another test module under `tests/`; the existing command discovers them automatically.

## 4. Understand a standard Elm test

Here is the shape of a test module:

```elm
module ExampleTest exposing (suite)

import Expect
import Game exposing (Direction(..))
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Movement"
        [ test "moving right increases x by one" <|
            \_ ->
                Game.nextHead Right { x = 5, y = 7 }
                    |> Expect.equal { x = 6, y = 7 }
        ]
```

- `describe` groups related tests.
- `test` names one behavior.
- `\_ ->` is a function the runner calls when it is time to run the test. The underscore means we do not need its input.
- `Game.nextHead ...` produces the actual result.
- `Expect.equal` compares the expected position with that result.
- `|>` sends the result into the next function. This is equivalent to `Expect.equal expected actual`.

The tests import `Game` directly. There is one implementation of the movement rules, shared by the game and the tests. The explicit `exposing` list at the top of `src/Game.elm` makes those functions and types available to other modules.

To add a test to this repository, open `tests/GameTest.elm` and add a new `test` item to the appropriate `describe` list. Keep the existing module name and imports. You can also save the complete example above as `tests/ExampleTest.elm` and extend it there.

## 5. Test an edge case

An edge case is a situation near a boundary or an unusual input. In the finished game, moving right from the last column wraps to column 0:

```elm
test "moving right from the last column wraps" <|
    \_ ->
        Game.nextHead Right { x = Game.gridSize - 1, y = 5 }
            |> Expect.equal { x = 0, y = 5 }
```

Add a comma before a new test if it follows another item in a list. Run the tests again after each small change.

The original Week 5 starter has a different wall rule: `nextHead` steps outside the grid, and `tickGame` ends the game. This wrapping test belongs to the finished `Game.elm`, not the unchanged starter. Tests should describe the version you are building.

## 6. Test growth

You can create a situation by changing part of the initial model. Put food directly in front of the eagle, advance one tick, and inspect the score:

```elm
test "eating food awards one point" <|
    \_ ->
        let
            initial =
                Game.initialModel

            hungry =
                { initial | food = { x = 11, y = 10 } }

            afterEating =
                Game.tickGame hungry
        in
        afterEating.score
            |> Expect.equal 1
```

Elm record updates use a local variable such as `initial`; you cannot write `{ Game.initialModel | ... }` directly. Each model here is a new value. The test does not change the running game's model.

Try a second test that checks the body's length after eating. Write down the expected length before running it.

## 7. Let Elm try many examples

A fuzz test asks the runner to try many generated inputs. Add these imports to a test module that uses fuzzing:

```elm
import Fuzz
import Test exposing (Test, describe, fuzz2, test)
```

Then add:

```elm
fuzz2
    (Fuzz.intRange 0 (Game.gridSize - 1))
    (Fuzz.intRange 0 (Game.gridSize - 1))
    "right followed by left returns to the starting position"
<|
    \x y ->
        { x = x, y = y }
            |> Game.nextHead Right
            |> Game.nextHead Left
            |> Expect.equal { x = x, y = y }
```

The runner generates different x and y coordinates. If one fails, it reports the inputs so you can investigate. A fuzz test checks a rule across many examples; it does not guarantee that every possible input was tried.

## Choose useful tests

Good game tests ask questions such as:

- Does moving up change y correctly?
- Does eating keep the old tail position and grow the body?
- Does restart keep the high score?
- Do clockwise and counterclockwise corners select the right color bands?
- Does a bend work across a wrapped edge?

Pure functions are especially easy to test: give them an input and inspect their output. For artwork, also play the game and look at the joins. A correct direction value does not prove that an eye, feather, or outline looks right.

Remove deliberately failing experiments when you are finished. Keep the tests that describe how your game should behave.

For random choices, use a fixed seed in a test so failures are reproducible, and check rules such as “the next prey differs from the current prey.” See [variable food](variable-food.md) for examples and the corresponding tests in GameTest.elm.
