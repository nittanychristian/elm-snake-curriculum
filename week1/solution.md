# Week 1: Solution Walkthrough

## What Changed from Main to Solution

One function was added: `grade : Int -> String`. Everything else (`double`, `describeNumber`, `letterGrade`) is the same — the solution just shows them all working together with more test cases in `main`.

---

## The New Function: `grade`

```elm
grade : Int -> String
grade score =
    if score >= 90 then
        "A"
    else if score >= 80 then
        "B"
    else if score >= 70 then
        "C"
    else if score >= 60 then
        "D"
    else
        "F"
```

### Why `if/else` here instead of `case`?

This is the key discussion point from the stretch challenge. `case` matches *specific values* — it can't express "greater than 90". `if/else` is the right tool when you're comparing ranges or doing arithmetic checks.

Ask students: "Could you write `grade` with `case`? What would you have to write?" (They'd need a branch for every integer 0–100 — clearly worse.) The right tool depends on what you're matching.

### The type annotation

`grade : Int -> String` — takes an `Int`, returns a `String`. Every function in the solution has its type written above it. Reinforce: the type annotation is a promise the compiler holds you to. If `grade` returned an `Int` by accident, the compiler would catch it before the program ever runs.

### What students might have done differently

- Some students may have used `>= 90` as the first check, others `> 89`. Both work — good moment to discuss whether the boundary belongs to A or B.
- Some may have written the checks in the wrong order (lowest first). Ask: "What does `grade 95` return if you check `>= 60` first?" (It returns `"D"` — wrong.) Order matters with `if/else` chains.
