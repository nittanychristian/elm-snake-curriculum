# Week 2: Solution Walkthrough

## What Changed from Main to Solution

The drawing functions are identical. The only change is in `main`: two green body cells were added before the head, so the static snake looks like it already has a body.

---

## The Change: Body Cells in `main`

**Main:**
```elm
(drawBoard
    ++ [ drawCell "#4ade80" 10 10  -- snake head
       , drawCell "#f87171" 5 5    -- food
       ]
)
```

**Solution:**
```elm
(drawBoard
    ++ [ drawCell "#22c55e" 8 10   -- body
       , drawCell "#22c55e" 9 10   -- body
       , drawCell "#4ade80" 10 10  -- head
       , drawCell "#f87171" 5 5    -- food
       ]
)
```

### Why this order matters

SVG draws elements in order — later elements appear on top of earlier ones. The body cells are listed before the head so the head renders on top if they overlap. This is also why `drawBoard` (the dark background grid) comes first in the list — everything else is layered over it.

### Two shades of green

- Body: `"#22c55e"` — slightly darker green
- Head: `"#4ade80"` — lighter green

Both are just `String` values passed to `drawCell`. If students want different colors, they change the string. Point out: this is the same `drawCell` function they've been using — the only difference is the color argument. Functions are reusable.

### What students might have done differently

- Some students may have added more body cells, or placed them in different positions. All fine — the positions are arbitrary for now.
- Some may have tried to draw a circle instead of a rect for the food. Great initiative — `circle` works the same way, just takes `cx`, `cy`, and `r` attributes instead of `x`, `y`, `width`, `height`.
- The stretch goal was to draw the full grid themselves before being given `drawBoard`. Students who reached it can explain `drawRow` and `List.concatMap` to the class.
