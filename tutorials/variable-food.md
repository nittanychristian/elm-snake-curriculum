# Give your eagle different kinds of food

The Week 5 starter represents food with a position and draws a red square. In this tutorial, food also has a **type**: a mouse, rabbit, duck, or another kind of prey. When the eagle catches it, the next type is chosen randomly from the other nine.

Start with [week5/Main.elm](../week5/Main.elm), or continue your customized game. The complete implementation is [src/Game.elm](../src/Game.elm). The original Week 5 game stops at walls; the finished game wraps. Changing food does not require changing your wall rule.

## 1. Meet the ten food types

You can [view all ten drawings together](../images/food-preview.svg).

| Type | SVG drawing |
| --- | --- |
| Mouse | [mouse.svg](../images/food/mouse.svg) |
| Vole | [vole.svg](../images/food/vole.svg) |
| Rat | [rat.svg](../images/food/rat.svg) |
| Rabbit | [rabbit.svg](../images/food/rabbit.svg) |
| Squirrel | [squirrel.svg](../images/food/squirrel.svg) |
| Duck | [duck.svg](../images/food/duck.svg) |
| Quail | [quail.svg](../images/food/quail.svg) |
| Snake | [snake.svg](../images/food/snake.svg) |
| Lizard | [lizard.svg](../images/food/lizard.svg) |
| Frog | [frog.svg](../images/food/frog.svg) |

Each picture has a transparent background and a 100 × 100 canvas. The game displays it in a 20 × 20 cell. Eagles eat a range of mammals, birds, reptiles, and amphibians; their diets vary by species and location. See the [Cornell Lab's eagle diet description](https://www.allaboutbirds.org/guide/bald_eagle/lifehistory).

Every catch still awards **one point**. The existing rule for moving food to a new position stays the same. This lesson changes the type and picture, rather than making the position random.

## 2. Describe the choices with a custom type

Add this near your other type definitions:

```elm
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


allFoodTypes : List FoodType
allFoodTypes =
    [ Mouse, Vole, Rat, Rabbit, Squirrel, Duck, Quail, Snake, Lizard, Frog ]
```

`FoodType` gives Elm a fixed set of valid choices. `Mouse` is a value of that type, rather than a string someone could misspell.

Keep the list and type together when you add more choices. The selection code will use the list as its catalogue.

## 3. Give the model a type and a random seed

Keep the existing `food : Position` field. Add these two fields to your `Model`:

```elm
, foodType : FoodType
, randomSeed : Random.Seed
```

Add these values to `initialModel`:

```elm
, foodType = Mouse
, randomSeed = Random.initialSeed 0
```

The position answers “Where is the food?” The type answers “What is it?” Keeping them separate means the existing collision check, `newHead == model.food`, continues to work.

The seed is the random generator's state. Each choice produces both a value and a new seed. Save that new seed for the next choice.

Add these imports:

```elm
import Random
import Task
```

The Week 5 starter already imports `Time`.

In Ellie at https://ellie-app.com/, use the Packages panel to add **elm/random 1.0.0**. The local project already declares it in `elm.json`. Do not paste JSON into Ellie's Elm editor.

## 4. Exclude the current food before choosing

Add this helper:

```elm
differentFood : FoodType -> Random.Generator FoodType
differentFood current =
    case List.filter ((/=) current) allFoodTypes of
        first :: rest ->
            Random.uniform first rest

        [] ->
            Random.constant Mouse
```

`List.filter ((/=) current)` removes the current type. If the current food is `Rabbit`, the list contains the other nine types.

`first :: rest` splits a nonempty list into its first item and remaining items. `Random.uniform first rest` gives every remaining type an equal chance. It describes a choice; it has not made that choice yet.

The empty-list branch makes the function handle every possible list shape. It cannot be reached with our ten-type catalogue and one excluded value. Keep at least two distinct types if you change the catalogue.

Filtering first guarantees a different next type. Choosing from all ten and hoping not to repeat would not provide that guarantee. A sequence such as Mouse → Rabbit → Mouse is allowed: the rule excludes only the immediately previous type.

## 5. Make a choice when food is eaten

In `tickGame`, find the `let` block that already calculates `ateFood`, `newBody`, and `newFood`. Add:

```elm
( newFoodType, newSeed ) =
    if ateFood then
        Random.step (differentFood model.foodType) model.randomSeed

    else
        ( model.foodType, model.randomSeed )
```

Then include the new fields in the returned model update:

```elm
, foodType = newFoodType
, randomSeed = newSeed
```

`Random.step` returns a pair: the chosen type and the next seed. On a tick without a catch, both values stay unchanged. The food will not flicker between pictures as the eagle moves.

Leave the existing body-growth, score, and position calculations in place. You do not need to change `tickGame`'s type: it is still `Model -> Model`.

## 6. Start with a different sequence each session

The seed `0` is useful while testing, because it produces a repeatable sequence. For normal play, ask Elm for the current time once and use it as the starting seed.

Add this variant to `Msg`:

```elm
| InitializeFood Time.Posix
```

Add this branch to `update`:

```elm
InitializeFood now ->
    let
        ( newFoodType, newSeed ) =
            Random.step
                (Random.uniform Mouse (List.drop 1 allFoodTypes))
                (Random.initialSeed (Time.posixToMillis now))
    in
    ( { model | foodType = newFoodType, randomSeed = newSeed }, Cmd.none )
```

This starting choice includes all ten types. It has no previous catch to exclude. The first list item is `Mouse`, so `List.drop 1` supplies the other nine without counting Mouse twice.

Finally, change the `init` field in `main` to:

```elm
init = \_ -> ( initialModel, Task.perform InitializeFood Time.now )
```

Elm gets the time through a command, then sends `InitializeFood` to `update`. During play, `tickGame` can use the saved seed as a pure calculation. You can therefore test it without waiting for the clock or receiving commands.

This is pseudo-randomness: the same seed gives the same sequence. Clock-based seeds normally differ between sessions, but they do not promise a unique sequence every time.

## 7. Connect each type to its picture

Open [src/Game.elm](../src/Game.elm) and copy the complete `foodIcon` function. It matches each of the ten constructors to its embedded SVG data URI. Also copy `foodName`, which returns the matching label.

The beginning of `foodName` looks like:

```elm
foodName : FoodType -> String
foodName foodType =
    case foodType of
        Mouse ->
            "Mouse"

        Vole ->
            "Vole"
```

That shortened example is not a complete function: your `case` needs a branch for all ten constructors. Use the complete version from the game.

To draw a replacement image yourself, use SVGEdit at https://svgedit.netlify.app/index.html. Convert the saved file at https://svgencoder.com/ by choosing **Base64**, **Data URI**, then **Copy**. Replace the corresponding quoted value in `foodIcon` with the entire copied string. See [the custom SVG tutorial](custom-svg.md) for detailed drawing instructions.

Add this renderer:

```elm
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
```

The Week 5 starter already imports `Svg` and `Svg.Attributes as SA`. In `view`, replace:

```elm
++ [ drawCell "#dc2626" model.food ]
```

with:

```elm
++ [ drawFood model.foodType model.food ]
```

You can add this paragraph to the outer list of HTML children, near the score:

```elm
p [] [ text ("Next prey: " ++ foodName model.foodType) ]
```

The SVG title and visible name help identify small pictures. Because the image data is inside the Elm file, a shared Ellie needs no image server.

## 8. Keep randomness moving when restarting

The finished game has a `Restart` message. The original Week 5 starter does not; skip this step if you have not added restart yet.

For the finished game's restart branch, choose a new type using the current seed, then restore the starting positions:

```elm
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
```

This keeps the best score, chooses a different prey type, and continues the random sequence. Resetting the seed to `0` on every restart would repeat the same sequence.

## 9. Test the rule rather than one lucky result

The exact next type can vary, but these rules should always hold:

- There are ten distinct choices with ten distinct images.
- The next choice belongs to the catalogue and differs from the current type.
- A catch still grows the eagle and awards one point.
- An ordinary tick preserves the food type and seed.
- Restart preserves the best score while choosing a different type.

Here is one test you can add to the `describe` list in [tests/GameTest.elm](../tests/GameTest.elm). Its imports already include `Random` and `FoodType(..)`:

```elm
test "the next food differs from Mouse" <|
    \_ ->
        let
            ( next, _ ) =
                Random.step (Game.differentFood Mouse) (Random.initialSeed 42)
        in
        next |> Expect.notEqual Mouse
```

The repository suite goes further: it checks 200 seeds for every current type and verifies that all nine alternatives can be selected. A fixed seed makes a failing random example reproducible. Read [the testing tutorial](testing-elm.md) for how to run and extend the suite.

In a local development shell, run:

```sh
just test
```

## Try the picker without playing a whole game

The committed [picker example](examples/variable-food/Main.elm) uses the actual game's catalogue, images, and selection helper. Click its button to choose another prey repeatedly.

From a local checkout:

```sh
nix develop
just dev tutorials/examples/variable-food
```

This example imports `Game` through its own [elm.json](examples/variable-food/elm.json), so it is a local companion to the tutorial. For Ellie, paste the complete `src/Game.elm` and add `elm/random`, or make the step-by-step changes above to your single-file game.
