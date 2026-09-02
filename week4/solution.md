# Week 4: Solution Walkthrough

## What Changed from Main to Solution

Two additions beyond the base game:

1. **`isOpposite` function** — prevents the snake from reversing direction into itself
2. **Length display** — shows snake length alongside the score in `view`

---

## Change 1: `isOpposite` and the Direction Guard

**Main — any key changes direction:**
```elm
KeyPressed dir ->
    ( { model | direction = dir }, Cmd.none )
```

**Solution — ignores reversals:**
```elm
isOpposite : Direction -> Direction -> Bool
isOpposite a b =
    case ( a, b ) of
        ( Up, Down ) -> True
        ( Down, Up ) -> True
        ( Left, Right ) -> True
        ( Right, Left ) -> True
        _ -> False

-- In update:
KeyPressed dir ->
    if isOpposite model.direction dir then
        ( model, Cmd.none )
    else
        ( { model | direction = dir }, Cmd.none )
```

### Why this matters

Without the guard, pressing the opposite direction causes the head to immediately move into the body — instant game over that feels unfair. Real Snake ignores the input instead.

### `case ( a, b ) of` — matching on a tuple

This is the first time students see `case` on a *tuple* (a pair of values). Elm can pattern-match on any value, including pairs. The compiler still enforces exhaustiveness — the `_` wildcard covers all other direction combinations.

Point out: `isOpposite` is a pure function that takes two `Direction` values and returns a `Bool`. It knows nothing about the model or the game — it just answers one question. This is functional design: small, focused, reusable functions.

---

## Change 2: Length Display

**Main — score only:**
```elm
p [ style "color" "#4ade80", style "margin" "0 0 8px 0" ]
    [ text ("Score: " ++ String.fromInt model.score) ]
```

**Solution — score and length:**
```elm
p [ style "color" "#4ade80", style "margin" "0 0 4px 0" ]
    [ text ("Score: " ++ String.fromInt model.score) ]
, p [ style "color" "#94a3b8", style "margin" "0 0 8px 0" ]
    [ text ("Length: " ++ String.fromInt (List.length model.body + 1)) ]
```

### Why `List.length model.body + 1`

`model.body` is the list of segments *behind* the head. The head itself isn't in that list — it's stored separately in `model.head`. So the total snake length is the body length plus one.

---

## What Students Might Have Added

These are common student-initiated additions during the session — all worth discussing:

- **Restart on game over** — usually implemented as a `Restart` message mapped to a key, returning `initialModel` from `update`
- **Different speeds** — changing `Time.every 200` to a smaller or larger number
- **Color changes** — often the first thing students try
- **Second food** — ambitious students add a `food2 : Position` to the model
