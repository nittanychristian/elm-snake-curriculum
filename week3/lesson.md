# Week 3: The Elm Architecture + Typed Game Model

## Learning Objectives

- Understand the Model/View/Update cycle as the single pattern for all interactivity
- Write `update` as a function that returns a new model — nothing is mutated
- Replace stringly-typed values with custom types the compiler can check
- Add a timer subscription so the snake head moves automatically

## Key Elm Concepts

- `Browser.element` — the entry point for interactive Elm apps
- `Model` as the single source of truth (a record)
- `Msg` as a custom type — every possible event the app can handle
- `update : Msg -> Model -> (Model, Cmd Msg)` — takes the old model, returns a new one
- Record update syntax: `{ model | field = newValue }` — creates a new record, does not mutate
- `type Direction = Up | Down | Left | Right` — a custom type the compiler enforces
- `type alias Position = { x : Int, y : Int }` — a named shorthand for a record type
- `Time.every` — fires a message on a regular interval
- `Sub.batch` — combine keyboard and timer subscriptions

## Session Structure (~60 min)

| Time | Activity |
|------|----------|
| 0–5 min | The Big Idea: Elm never changes a variable — it creates a new model |
| 5–15 min | Draw the full cycle on the board; walk through the counter together |
| 15–25 min | Students type the moving box from Main.elm; add boundary checking |
| 25–35 min | Refactor: replace `MoveUp`/`MoveDown`/… with a `Direction` custom type |
| 35–50 min | Add the timer — the head moves automatically every 200 ms |
| 50–57 min | Upgrade model to use `Position`; add the grid board to `view` |
| 57–60 min | The snake head is moving! Preview: next week = body + food + game over |

## Activity

### Part 1: MVU + Moving Box (0–25 min)

**Counter first (10 min, teacher-led):**

Before any code, draw this on the board and leave it up for the rest of the course:

```
user presses key
  → browser fires event
  → Elm calls  update msg currentModel
  → update returns newModel
  → Elm calls  view newModel
  → page redraws
  → (repeat forever)
```

"The model is the only thing that changes between frames — and even then, `update` doesn't change it, it *returns a new one.*"

Show the counter in Ellie. Trace one click through: which `Msg` variant fires? Which branch of `update` runs? What's the new model? What does `view` draw?

Students do NOT type the counter — just watch and trace. Move on after 10 minutes.

**Moving box (15 min, students type):**

Students load Main.elm in Ellie. Walk through the structure together:

- `Model` is a record with two fields: `boxX` and `boxY`
- `Msg` has five variants: `MoveUp`, `MoveDown`, `MoveLeft`, `MoveRight`, `Other`
- `update` matches on the message and returns a new model with one coordinate changed
- `view` draws an SVG `rect` at the box's position

Students run it, move the box around, then tackle the challenge: **make the box stop at the edges** rather than disappearing. Give them 5 minutes. If they're stuck, reveal the `max`/`min` approach:

```elm
MoveUp ->
    { model | boxY = max 0 (model.boxY - 10) }

MoveDown ->
    { model | boxY = min (boardSize - boxSize) (model.boxY + 10) }
```

### Part 2: Direction Type + Timer (25–57 min)

"Now we transform this box into the real Eagle Strike game model. I'll guide — type along with me and ask questions as we go."

**Step 1: Replace `MoveUp`/… with a `Direction` type (25–35 min)**

The current `Msg` has four direction variants plus `Other`. This works, but the direction isn't reusable — we can't write a function that takes "the current direction" as an argument.

Replace the box-specific messages with a `Direction` type:

```elm
type Direction
    = Up
    | Down
    | Left
    | Right
```

Then change `Msg` to carry the direction as data:

```elm
type Msg
    = KeyPressed Direction
    | Ignore
```

Update `toMsg` to produce a `Direction`:

```elm
toMsg key =
    case key of
        "ArrowUp"    -> KeyPressed Up
        "ArrowDown"  -> KeyPressed Down
        "ArrowLeft"  -> KeyPressed Left
        "ArrowRight" -> KeyPressed Right
        _            -> Ignore
```

And `update` to store the direction on the model:

```elm
-- First, add direction to the model:
type alias Model =
    { boxX : Int
    , boxY : Int
    , direction : Direction
    }

update msg model =
    case msg of
        KeyPressed dir ->
            { model | direction = dir }
        Ignore ->
            model
```

**Key teaching moment:** "Before, four different messages each moved the box. Now one message carries the direction *as data*. The direction can be stored on the model and used by other functions. The compiler checks that we handle every possible direction — we can't accidentally miss `Left`."

**Step 2: Add the timer (35–50 min)**

Right now the box moves only when a key is pressed. The snake should move on its own. Add `Time` to the imports and a `Tick` variant to `Msg`:

```elm
import Time

type Msg
    = Tick Time.Posix
    | KeyPressed Direction
    | Ignore
```

Add a `nextHead` function that computes the new position from the current one:

```elm
nextHead : Direction -> Position -> Position
nextHead dir pos =
    case dir of
        Up    -> { pos | y = pos.y - 1 }
        Down  -> { pos | y = pos.y + 1 }
        Left  -> { pos | x = pos.x - 1 }
        Right -> { pos | x = pos.x + 1 }
```

Handle `Tick` in `update` — when the timer fires, move the head:

```elm
Tick _ ->
    let
        newHead = nextHead model.direction model.head
    in
    if isOutOfBounds newHead then
        ( initialModel, Cmd.none )
    else
        ( { model | head = newHead }, Cmd.none )
```

Update subscriptions to use `Sub.batch`:

```elm
subscriptions _ =
    Sub.batch
        [ Time.every 200 Tick
        , onKeyDown keyDecoder
        ]
```

**Step 3: Upgrade the model to use `Position` (50–57 min)**

Replace `{ boxX : Int, boxY : Int }` with a named type alias:

```elm
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
```

Update `view` to draw the full 20×20 grid and the head:

```elm
view model =
    svg [...]
        (drawBoard ++ [ drawCell "#f0ede0" model.head ])
```

Play it! The white head cell glides across the navy grid, changing direction on arrow keys.

---

### Key Teaching Moments

**On custom types (`type Direction = ...`):**

A *custom type* defines a brand-new type with a fixed set of possible values:

```elm
type Direction
    = Up
    | Down
    | Left
    | Right
```

Read the `|` as "or": a `Direction` is either `Up`, or `Down`, or `Left`, or `Right`. Those are the only four values that can ever be a `Direction`.

Before, we used `"ArrowUp"` as a string — nothing stops us from accidentally putting `"Diagonal"` where a direction is expected. With a custom type, the compiler knows every possible `Direction` and rejects anything that isn't one of the four variants.

Good analogy: a traffic light. `type TrafficLight = Red | Yellow | Green` means exactly three states exist. You can't have a purple traffic light.

**On record update syntax:**

```elm
{ model | direction = Left }
```

Read this as: "a new record, just like `model`, except `direction` is replaced with `Left`."

Three things to be clear about:

- **`model` is not changed.** The original record still exists with its original values. Elm creates a brand new record.
- **Only the listed fields are replaced.** Every other field is copied as-is.
- **You can update multiple fields at once:** `{ model | x = 5, y = 10 }`

If students are skeptical, prove it in Ellie: bind the result to a new name and show that the old name still has the original value.

**On `type alias`:**

```elm
type alias Position =
    { x : Int, y : Int }
```

This doesn't create a new type — it creates a *name* for an existing record shape. Anywhere you write `Position`, Elm reads it as `{ x : Int, y : Int }`. It keeps function signatures readable: `nextHead : Direction -> Position -> Position` tells the story at a glance.

**On `Sub.batch`:**

A `Sub` is a subscription — Elm listens for an event and fires a message when it happens. `Sub.batch` takes a list of subscriptions and activates all of them. The keyboard subscription fires when a key is pressed; the timer subscription fires every 200 milliseconds. Both are active at the same time.

## What Students Have Working by End of Session

A 20×20 grid with a white cell that moves automatically every 200 ms. Arrow keys change the direction. Running into a wall resets to the center. The game model, direction type, and timer are all in place — Week 4 adds the body, food, and collision.

## Starter Code

See [`Main.elm`](Main.elm) in this directory — the moving box. Load it in Ellie at the start of the session.

## Common Stumbling Blocks

**Record update syntax looks like mutation.**
This is the most common misconception of the week. Repeat it clearly: "This creates a *brand new record*. `model` still exists, unchanged, right after this line."

**`case` must be exhaustive.**
When students add a `Direction` variant and forget a branch in `nextHead`, the compiler errors. Frame it positively: "Elm is checking that you handled every possible direction. That's a feature."

**`Cmd.none` looks mysterious.**
Tell students: "The command system is how Elm talks to the outside world — HTTP requests, random numbers, that kind of thing. We're not using it yet. Write `Cmd.none` like punctuation and move on."

**`Sub.batch` vs. just one subscription.**
Some students may try to use both `Time.every` and `onKeyDown` without `Sub.batch`. Show them the type: `subscriptions` must return a single `Sub Msg`. `Sub.batch` wraps a list of subscriptions into one.

**Session is fast.**
Part 2 is teacher-led intentionally. Students who don't type every character are still building a mental model. The Solution.elm gives them the complete code to load and explore on their own.
