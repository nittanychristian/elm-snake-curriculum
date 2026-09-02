# Week 3: Solution Walkthrough

## What Changed from Main to Solution

Main.elm is a box that moves on individual key presses. Solution.elm is a snake head that moves automatically and responds to direction changes. The transformation happens in two stages during class.

| Change | When |
|--------|------|
| Boundary clamping (`max`/`min`) | Part 1 challenge (box still) |
| `Direction` custom type replacing `MoveUp`/… | Part 2, Step 1 |
| `Position` type alias for `{ x, y }` | Part 2, Step 3 |
| `Time.every` timer + `Tick` message | Part 2, Step 2 |
| `Sub.batch` combining keyboard + timer | Part 2, Step 2 |
| `initialModel` reset on wall hit | Part 2, Step 2 |
| Full grid board in `view` | Part 2, Step 3 |

---

## Part 1 Challenge: Boundary Clamping

**Main — no boundary check:**
```elm
MoveUp ->
    { model | boxY = model.boxY - 10 }

MoveDown ->
    { model | boxY = model.boxY + 10 }
```

**After challenge — clamped with `max` and `min`:**
```elm
MoveUp ->
    { model | boxY = max 0 (model.boxY - 10) }

MoveDown ->
    { model | boxY = min (boardSize - boxSize) (model.boxY + 10) }
```

`max 0 x` returns `x` unless it would go negative, in which case it returns `0` — the box can never move above the top edge. `min (boardSize - boxSize) x` caps the position so the *right/bottom edge* of the box never exceeds the board. We subtract `boxSize` because `boxX`/`boxY` is the *top-left corner* of the box, not the right edge.

Some students may write this with `if/else` instead:
```elm
MoveUp ->
    if model.boxY - 10 < 0 then
        { model | boxY = 0 }
    else
        { model | boxY = model.boxY - 10 }
```
Both are correct. `max`/`min` is more concise; `if/else` is more explicit. Either is fine.

---

## Part 2, Step 1: Direction Custom Type

**Main — four separate message variants:**
```elm
type Msg
    = MoveUp
    | MoveDown
    | MoveLeft
    | MoveRight
    | Other
```

**Solution — one message carrying a `Direction`:**
```elm
type Direction
    = Up
    | Down
    | Left
    | Right

type Msg
    = Tick Time.Posix
    | KeyPressed Direction
    | Ignore
```

The `Direction` type is now a value we can store on the model and pass to functions. `toMsg` returns `KeyPressed Up` instead of `MoveUp` — the direction travels with the message rather than being encoded in the message name.

The model gains a `direction` field:
```elm
type alias Model =
    { head : Position
    , direction : Direction
    }
```

And `update` stores the direction but doesn't move yet:
```elm
KeyPressed dir ->
    ( { model | direction = dir }, Cmd.none )
```

---

## Part 2, Step 2: Timer

**Main — subscriptions (keyboard only):**
```elm
subscriptions _ =
    onKeyDown keyDecoder
```

**Solution — Sub.batch combines keyboard + timer:**
```elm
subscriptions _ =
    Sub.batch
        [ Time.every 200 Tick
        , onKeyDown keyDecoder
        ]
```

`Time.every 200 Tick` fires a `Tick` message every 200 milliseconds. `Sub.batch` makes both the keyboard and timer active at the same time.

`Tick` is handled in `update` — when it fires, compute the next head position and either move or reset:

```elm
Tick _ ->
    let
        newHead =
            nextHead model.direction model.head
    in
    if isOutOfBounds newHead then
        ( initialModel, Cmd.none )
    else
        ( { model | head = newHead }, Cmd.none )
```

`nextHead` is a pure function that applies the current direction to the current position:
```elm
nextHead dir pos =
    case dir of
        Up    -> { pos | y = pos.y - 1 }
        Down  -> { pos | y = pos.y + 1 }
        Left  -> { pos | x = pos.x - 1 }
        Right -> { pos | x = pos.x + 1 }
```

`isOutOfBounds` checks whether the head has left the grid:
```elm
isOutOfBounds pos =
    pos.x < 0 || pos.x >= gridSize || pos.y < 0 || pos.y >= gridSize
```

Hitting a wall resets to `initialModel` (center of the grid, facing right). Week 4 will replace this with a proper `GameOver` status.

---

## Part 2, Step 3: Position Type Alias + Grid View

**`Position` type alias:**
```elm
type alias Position =
    { x : Int, y : Int }
```

This doesn't create a new type — it gives a readable name to the `{ x : Int, y : Int }` record shape. Function signatures like `nextHead : Direction -> Position -> Position` now tell their story clearly.

**`view` switches from a single SVG box to the full 20×20 grid:**

The grid is drawn the same way as in Week 2:
```elm
drawBoard : List (Svg msg)
drawBoard =
    List.concatMap
        (\row ->
            List.map
                (\col -> drawCell "#0a1628" { x = col, y = row })
                (List.range 0 (gridSize - 1))
        )
        (List.range 0 (gridSize - 1))
```

Then the head is drawn on top:
```elm
(drawBoard ++ [ drawCell "#f0ede0" model.head ])
```

The game now has a navy grid, a white head that moves automatically, and arrow-key direction control. The full game model is in place — body and food come next.
