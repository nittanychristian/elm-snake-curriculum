# Week 5: Customization and Show and Tell

## Learning Objectives

- Apply everything learned to personalize a working program
- Explain code choices to peers in plain language
- See that functional style makes isolated changes easy and safe

## Key Elm Concepts (Review + Extensions)

- Color values as `String` — trivial to swap
- `Time.every` interval as a variable — changing speed
- Adding new `Msg` variants for new interactions (restart, pause)
- `Random` module (stretch) — generating truly random food positions
- `Cmd` (stretch) — the command system for talking to the outside world

## Session Structure (~60 min)

| Time | Activity |
|------|----------|
| 0–10 min | Teacher distributes the completed Week 4 code. Students verify it runs. |
| 10–35 min | Free customization time using the tiered challenge menu below |
| 35–50 min | Show and tell — each student (or pair) shares their screen for 1–2 min |
| 50–57 min | Group discussion: what would be hard to add? What was easier than expected? |
| 57–60 min | Closing: what is functional programming? Students summarize in their own words. |

## Starter Code

[`Main.elm`](Main.elm) in this directory is the completed Week 4 game — the starting point for all customizations. Load it in Ellie and share the link with students at the start of the session.

## Customization Challenge Menu

Hand this out as a printed or posted list. Students pick what interests them. The tiers ensure no one is stuck.

### Level 1 — Appearance (everyone can do these)

- Change the snake color, food color, or background color
- Change the snake speed (just change the number in `Time.every`)
- Add a border or background color to the outer `div`
- Display "HIGH SCORE: X" that persists in the model until the page refreshes
- Make the food blink (alternate colors each tick using `modBy 2 model.score`)

### Level 2 — Gameplay

- **Restart:** add `Restart` to `Msg`, map the `"r"` key to it in `keyDecoder`, handle it in `update` by returning `initialModel`
- **Wrap-around walls:** replace `isOutOfBounds` with `modBy`-based wrapping in `nextHead` (see snippet below)
- **Speed increase:** change `Time.every 200 Tick` to `Time.every (max 80 (200 - model.score * 10)) Tick` — requires passing `model` to `subscriptions`, which it already receives
- **Second food item:** add `food2 : Position` to the model, check it in `tickGame`, render it in `view`
- **Show snake length:** add `text ("Length: " ++ String.fromInt (List.length model.body + 1))` to `view`

### Level 3 — Stretch Challenges

- **True random food:** use `Random.generate NewFood (Random.pair (Random.int 0 19) (Random.int 0 19))` — requires adding `NewFood ( Int, Int )` to `Msg` and returning a `Cmd` from `update`
- **Eye on the head:** add a small `circle` in `view` at the head position, offset based on `model.direction`
- **Pause:** add `Paused` to `GameStatus`, toggle on spacebar, skip `tickGame` when `Paused`, show "PAUSED" in `view`
- **Walls level:** add `walls : List Position` to the model, check `List.member newHead model.walls` in collision detection, render them in `view`

## Useful Code Snippets for Students

### Wrap-around walls (Level 2)

```elm
nextHeadWrapped : Direction -> Position -> Position
nextHeadWrapped dir pos =
    case dir of
        Up ->
            { pos | y = modBy gridSize (pos.y - 1) }

        Down ->
            { pos | y = modBy gridSize (pos.y + 1) }

        Left ->
            { pos | x = modBy gridSize (pos.x - 1) }

        Right ->
            { pos | x = modBy gridSize (pos.x + 1) }
```

Replace the call to `nextHead` in `tickGame` with `nextHeadWrapped`, and remove the `isOutOfBounds` check from `newStatus`.

### Restart (Level 2)

```elm
-- Add to Msg:
-- | Restart

-- Add to toMsg in keyDecoder:
-- "r" -> Restart
-- "R" -> Restart

-- Add to update:
-- Restart -> ( initialModel, Cmd.none )
```

### Speed increase (Level 2)

```elm
-- In subscriptions, change:
--   Time.every 200 Tick
-- to:
--   Time.every (toFloat (max 80 (200 - model.score * 10))) Tick
```

`subscriptions` already receives `model` — use it.

### True random food (Level 3)

```elm
-- Add to imports:
import Random

-- Add to Msg:
-- | NewFood ( Int, Int )

-- In update, when ateFood is True, instead of respawnFood:
-- ( updatedModel, Random.generate NewFood (Random.pair (Random.int 0 19) (Random.int 0 19)) )

-- Handle NewFood in update:
-- NewFood ( fx, fy ) ->
--     ( { model | food = { x = fx, y = fy } }, Cmd.none )
```

## Show and Tell Format

Each student (or pair) shares their screen for 1–2 minutes:

1. Show the game running
2. Point to one change they made in the code
3. Say one sentence about why they made that choice

The explanation only needs to be one sentence. "I changed the color here because I like purple" is a complete answer. The goal is making a deliberate change and being able to point to it — not a polished presentation.

Allow pairs for students who are nervous presenting alone.

## Closing Discussion Questions

- "What would happen if you changed `initialModel`?" (The game would start differently — it's the single source of truth)
- "Why didn't we ever write a loop?" (We described transformations, not steps)
- "What made a bug easy to find this week?" (Pure functions — the input and output are both visible)
- "What would you add if you kept going?"

## Common Stumbling Blocks

**Students stuck on what to change.**
Point them directly at Level 1, first item: change the snake color. Once they make one successful change, their confidence unlocks everything else.

**"I broke it and I don't know what I changed."**
Ellie doesn't have git. Teach the habit: "Before you change something, open a second browser tab with the working code." This is a natural moment to explain why version control exists — and why programmers invented it.

**Show-and-tell anxiety.**
Allow pairs. Remind students that the explanation only needs to be one sentence. If a student truly won't present, ask them to tell you privately what they changed — the articulation matters more than the audience.

**Level 3 confusion about `Cmd`.**
The `Random` stretch goal introduces the command system, which is a bigger concept than this session can fully cover. Frame it: "Commands are how Elm asks the outside world to do something — in this case, give us a random number. It's fine if this is confusing. You've already built a complete game without it."
