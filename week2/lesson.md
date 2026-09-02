# Week 2: Drawing with SVG

## Learning Objectives

- Understand that SVG shapes are values described by attributes — just more function calls
- Use `List.map` to apply a function to every item in a list and collect the results
- Draw the Snake game board as a grid of rectangles

## Key Elm Concepts

- `Svg` and `Svg.Attributes` modules
- `svg`, `rect`, `circle` as functions that return `Svg` values
- Attribute values as `String` (SVG quirk — `x "10"` not `x 10`)
- `List.map : (a -> b) -> List a -> List b` — transform every element
- `List.range 0 19` — produces `[0, 1, 2, ..., 19]`
- `List.concatMap` — map then flatten (for nested lists)

## Session Structure (~60 min)

| Time | Activity |
|------|----------|
| 0–5 min | Recap: last week functions produced text. Today they produce pictures. |
| 5–15 min | Teacher shows starter: one rectangle, explains coordinate system (top-left is 0,0) |
| 15–25 min | Students place three differently-colored rectangles at different positions |
| 25–40 min | Introduce `List.map` — teacher live-codes a row of boxes |
| 40–55 min | Challenge: draw the full 20×20 Snake grid |
| 55–60 min | Preview: next week these shapes respond to keyboard input |

## Activity

**Step 1:** Understand coordinates. Place a circle at `(100, 100)`. Move it to a corner.

**Step 2:** Write a `drawCell : String -> Int -> Int -> Svg msg` function that draws one grid cell at grid coordinates (col, row).

**Step 3:** Use `List.map` to draw a row of 20 cells. Before writing any code, the teacher asks: "You have a list of column numbers `[0, 1, 2, ..., 19]`. What do you want to do to each one?" Students should say "draw a cell." `List.map` applies `drawCell` to each number and collects the results — a list of rectangles. No loop. Just a description of the transformation.

**Step 4 (stretch):** Nest two `List.map` calls (via `List.concatMap`) to draw all 20 rows.

### Key Teaching Moments

**On `List.map`:** "You have a cookie cutter and 20 pieces of dough. `List.map` presses the cookie cutter onto each piece and collects the results. You describe what pressing looks like — `List.map` handles the rest. You never say 'first piece, second piece, third piece...'"

**On anonymous functions (`\col -> ...`):**
`List.map` needs a function to apply to each column number. We need one that also knows the current `row` — but `row` changes every time `drawRow` is called, so we can't use a fixed top-level function.

The solution is an *anonymous function* — a function defined right where it's used, with no name:

```elm
\col -> drawCell "#1a1a2e" col row
```

Read it as: "a function that takes a number, calls it `col`, and draws a cell at that column in this row."

The `\` introduces the argument (like the word "function"), the `->` separates it from the body. The anonymous function automatically captures `row` from the surrounding `drawRow` call.

Think of it as a sticky note: "take a number, call it `col`, do this." The sticky note is created fresh each time `drawRow` runs, with the right `row` already baked in.

## What Students Have Working by End of Session

An SVG canvas showing a 20×20 dark grid — the empty Snake board — plus a green cell for the snake head and a red cell for food, placed manually.

## Starter Code

See [`Main.elm`](Main.elm) in this directory. Load it in Ellie at the start of the session and share the link with students.

## Common Stumbling Blocks

**SVG attributes must be `String`.**
Students will try `x 10` and get a type error. Explain: "SVG in HTML is text-based at heart, so Elm's SVG library takes `String` values. The fix is always `String.fromInt`." Keep this rule on the board.

**`List.concatMap` vs `List.map`.**
Drawing the full grid needs `concatMap` because `List.map drawRow` produces `List (List (Svg msg))` — a list of lists. `concatMap` maps then flattens. If this is too much for the group, provide `drawBoard` as a given and let students focus on `drawRow`.

**Anonymous function syntax `(\col -> ...)`.**
The backslash is Elm's lambda. Some students find it strange. Analogy: "It's a function with no name — like a sticky note that says 'take a number, draw a cell at that column.'" If it's causing too much confusion, define a named helper function instead and use that in `List.map`.

**Coordinate system.**
Y increases downward (standard for screens, counterintuitive for students who've used graph paper). Draw a labeled diagram on the board and leave it up.
