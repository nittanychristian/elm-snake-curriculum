# Week 4: Game Logic as Pure Functions

## Learning Objectives

- Represent the snake body as a `List` and update it without mutation
- Write collision detection as a pure function returning `Bool`
- Understand that all game rules are just functions: input state → output state

## Key Elm Concepts

- `List` operations: `List.map`, `List.member`, `List.length`, `List.take`
- The `::` operator — prepend an element to a list
- `type GameStatus = Playing | GameOver` — custom type for game state
- `let`/`in` expressions for naming intermediate values
- The pipeline pattern: a sequence of pure transformations on the model

## Session Structure (~60 min)

| Time | Activity |
|------|----------|
| 0–5 min | Recap: we have a moving head. Today we add body, food, and losing. |
| 5–15 min | Body algorithm with cards on a table: add to front, remove from back |
| 15–30 min | Students extend the model with `body`, `food`, `score`, `status` |
| 30–45 min | Implement `tickGame` step by step as a pipeline |
| 45–55 min | Render body cells, food cell, score display |
| 55–60 min | Play test — celebrate when someone loses (it means collision works) |

## Activity

### The Body Algorithm

Before writing any code, demonstrate with physical index cards on a table:

- Each card is a snake body segment with a position written on it
- The snake moves: place a new card at the front (the new head position), remove the card at the back
- The snake eats food: place a new card at the front, *don't* remove the back card — the snake grows

In Elm:
- Body is a `List Position`
- Move: `newHead :: List.take (List.length model.body - 1) model.body`
- Grow: `newHead :: model.body`

### The Tick Pipeline

Teach `tickGame` as a sequence of questions answered by pure functions:

```
old model
  → move head to new position
  → did head land on food?
      yes → grow body, respawn food, increment score
      no  → just move body (drop the tail)
  → did head hit a wall or itself?
      yes → GameOver
      no  → Playing
  → new model
```

Each step is its own named value in a `let` expression. No mutation. No loops. Every intermediate value is visible and testable.

### Key Teaching Moment

**On `let`/`in`:** "A `let` expression lets us name intermediate values inside a function. It's not creating variables — these names don't change. They're just aliases for expressions, like giving a nickname to a calculation so we don't have to repeat it."

**On the pipeline:** "Every step takes the model and produces a new value. We never reach back and change something from an earlier step. If you can read the `let` block top to bottom and each line makes sense on its own, the function is well-structured."

## What Students Have Working by End of Session

A fully playable (if unpolished) Snake game: moving snake, food appears when eaten, body grows, hitting a wall or self ends the game and shows "GAME OVER", score is displayed.

## Starter Code

See [`Main.elm`](Main.elm) in this directory. Load it in Ellie at the start of the session and share the link with students.

## Common Stumbling Blocks

**The body-shrinking algorithm.**
`List.take (List.length model.body - 1) model.body` is subtle. Trace through it with a concrete 3-cell example on the board:
- body is `[A, B, C]`, length is 3, take 2, result is `[A, B]`
- then prepend the old head: `[oldHead, A, B]`
- the snake moved one cell and stayed the same length

Draw arrows. Do this before students write any code.

**`List.member` and structural equality.**
`List.member head body` works because Elm uses structural equality for records — two `Position` values are equal if their fields are equal. Students don't need to understand the mechanics; just confirm it works.

**Students want to reverse direction.**
Real Snake doesn't let you reverse (going right, then immediately left). Ask students to identify the problem themselves: "What happens if the snake is going right and you press left?" Then: "How would you fix it?" The fix is a guard in `KeyPressed`: ignore the new direction if it's the direct opposite of the current one. Good self-directed challenge for students who finish early.

**Food spawns inside the snake.**
The deterministic `respawnFood` can place food on the snake's body. This is a known limitation. For now, tell students it's rare enough that it's okay. The stretch goal in Week 5 (true random food) can address it properly.
