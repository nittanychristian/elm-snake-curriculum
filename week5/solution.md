# Week 5: Solution Walkthrough

## What Changed from Main to Solution

The solution demonstrates all Level 1 and Level 2 challenges completed. These are the kinds of changes students should be making during free customization time.

| Change | Category |
|--------|----------|
| `highScore` field added to model | Level 1 |
| Custom color scheme (purple theme) | Level 1 |
| `Restart` message, press R to restart | Level 2 |
| `isOpposite` guard (no reversals) | Level 2 (from Week 4) |
| Wrap-around walls via `modBy` | Level 2 |
| Speed scales with score | Level 2 |
| High score preserved across restarts | Level 2 |
| "GO EAGLES!" and "press R to fly again" on game over | Level 1 |

---

## Change 1: `highScore` in the Model

**Main:**
```elm
type alias Model =
    { head : Position
    , body : List Position
    , direction : Direction
    , food : Position
    , score : Int
    , status : GameStatus
    }
```

**Solution adds `highScore`:**
```elm
type alias Model =
    { ...
    , score : Int
    , highScore : Int   -- new
    , status : GameStatus
    }
```

And in `tickGame`, it's updated whenever score increases:
```elm
, highScore = max model.highScore newScore
```

`max` returns whichever is larger — so `highScore` only ever goes up.

### Preserving high score across restarts

```elm
Restart ->
    ( { initialModel | highScore = model.highScore }, Cmd.none )
```

`initialModel` resets everything to the starting state — but we immediately override `highScore` with the current value. The student's best score survives the restart.

---

## Change 2: Restart

**Main — no restart:**
```elm
type Msg
    = Tick Time.Posix
    | KeyPressed Direction
    | Ignore
```

**Solution adds `Restart`:**
```elm
type Msg
    = Tick Time.Posix
    | KeyPressed Direction
    | Restart
    | Ignore
```

Wired in `toMsg`:
```elm
"r" -> Restart
"R" -> Restart
```

Handled in `update`:
```elm
Restart ->
    ( { initialModel | highScore = model.highScore }, Cmd.none )
```

Adding a `Msg` variant is the standard Elm pattern for any new interaction. The compiler immediately flags every `case msg of` that needs a new branch — students can't forget one.

---

## Change 3: Wrap-Around Walls

**Main — hits wall = game over:**
```elm
nextHead dir pos =
    case dir of
        Up -> { pos | y = pos.y - 1 }
        ...

newStatus =
    if isOutOfBounds newHead || hitsItself newHead model.body then
        GameOver
    else
        Playing
```

**Solution — hits wall = wraps around:**
```elm
nextHead dir pos =
    case dir of
        Up -> { pos | y = modBy gridSize (pos.y - 1) }
        Down -> { pos | y = modBy gridSize (pos.y + 1) }
        Left -> { pos | x = modBy gridSize (pos.x - 1) }
        Right -> { pos | x = modBy gridSize (pos.x + 1) }

newStatus =
    if hitsItself newHead model.body then   -- isOutOfBounds removed
        GameOver
    else
        Playing
```

Two changes together: `modBy` wraps the position, and `isOutOfBounds` is removed from the collision check. Students need to make both or the snake wraps but still dies at the wall.

---

## Change 4: Speed Scaling

**Main — fixed speed:**
```elm
subscriptions _ =
    Sub.batch
        [ Time.every 200 Tick
        , onKeyDown keyDecoder
        ]
```

**Solution — speed increases with score:**
```elm
subscriptions model =
    Sub.batch
        [ Time.every (toFloat (max 80 (200 - model.score * 10))) Tick
        , onKeyDown keyDecoder
        ]
```

Two things to notice:
- `subscriptions` now uses `model` (the `_` became `model`) — needed to read `model.score`
- `max 80` caps the speed so the interval never goes below 80ms (very fast but not impossible)
- `toFloat` converts the `Int` result to `Float` because `Time.every` takes a `Float`

At score 0: `200 - 0 = 200ms`. At score 12: `200 - 120 = 80ms` (max speed). After that, score goes up but speed stays at 80ms.

---

## Common Student Questions During Debrief

**"Why does `{ initialModel | highScore = model.highScore }` work?"**
Record update syntax works on any record, including `initialModel`. Elm copies all fields from `initialModel` and replaces just `highScore` — same syntax they learned in Week 3.

**"Why did I have to change `_` to `model` in subscriptions?"**
`_` means "I'm ignoring this argument." Once we needed `model.score`, we had to give the argument a name so we could use it. The type signature didn't change — `subscriptions` always received the model, we just weren't using it before.

**"Can I make the high score save when I reload the page?"**
Not without localStorage (a browser API accessed via `port`s in Elm). This is a real Elm concept — flag it as "something to explore after this course" rather than trying to implement it in class.
