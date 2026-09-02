# Week 1: Values, Types, and Pure Functions

## Learning Objectives

- Understand that a function is a rule that takes inputs and produces an output — it never changes anything
- Read and write simple Elm type annotations
- Use `if/else` and `case` as *expressions* that produce values (not control-flow statements)

## Key Elm Concepts

- `Int`, `String`, `Bool`, `Float` — the basic types
- Function definition syntax: `name arg = expression`
- Type annotations: `name : InputType -> OutputType`
- `if`/`else` as an expression — must always have an `else`, always produces a value
- `case` as an expression — exhaustive matching, `_` wildcard, compiler enforces completeness
- `view` as the bridge from values to visible output

## Session Structure (~60 min)

| Time | Activity |
|------|----------|
| 0–5 min | Intro: What is a function? Pizza analogy — ingredients in, pizza out, kitchen stays clean |
| 5–15 min | Teacher live-codes the starter snippet, narrates every line |
| 15–25 min | Students modify: add their own functions, change values, read error messages |
| 25–40 min | Mini-challenge: `describeNumber` with `if/else`, then `letterGrade` with `case` |
| 40–50 min | Discuss: both produce a value — neither "does" anything. Compiler requires exhaustiveness. |
| 50–57 min | Three students share their screen, explain one function they wrote |
| 57–60 min | Preview: next week functions produce shapes instead of text |

## Activity

Students open the starter link and complete these challenges in order:

1. Change `myName` to their own name. Make the page say "Hello, [name]!"
2. Write `double : Int -> Int` that multiplies by 2
3. Write `describeNumber : Int -> String` using `if/else` — returns `"positive"`, `"negative"`, or `"zero"`
4. Write `letterGrade : String -> String` using `case` — maps `"A"` → `"Excellent"`, `"B"` → `"Good"`, etc., with `_` as the fallback
5. **Stretch:** Write `grade : Int -> String` — takes a score 0–100, returns `"A"`, `"B"`, `"C"`, `"D"`, or `"F"`. Which style fits better, `if/else` or `case`? Why?

### Key Teaching Moments

**On `if/else`:** "This whole expression equals either `"positive"` or `"negative"` or `"zero"`. It doesn't *do* anything — it *is* a value. Like a vending machine: put in a number, get out a string."

**On `case`:** "Same idea, but more powerful. And notice — Elm won't compile until you've handled every possible input. The `_` means 'anything else.' The compiler is checking your work."

**On the contrast:** Use `if/else` when you're comparing ranges (`n > 0`). Use `case` when you're matching specific values (`"A"`, `"B"`). Both are expressions. Neither is control flow.

## What Students Have Working by End of Session

A page displaying output from their own pure functions, including at least one function using `if/else` and one using `case`.

## Starter Code

See [`Main.elm`](Main.elm) in this directory. Load it in Ellie at the start of the session and share the link with students.

## Common Stumbling Blocks

**`if` without `else`.**
Students from Python or Scratch expect optional `else`. In Elm, `if` must have `else` because it must always produce a value. Frame it: "Every vending machine button must dispense something — you can't press a button and get nothing."

**Forgetting a `case` branch.**
When students add a new value to match but forget a branch, the compiler errors. Frame this positively: "Elm is checking that you handled every possibility. You can't accidentally forget one."

**Type errors on `++`.**
Students will try `"Score: " ++ 42` and get a type error. Explain: `++` joins two `String`s. To join a number, convert it first: `String.fromInt 42`. Same idea as needing the right plug adapter.

**Indentation.**
Elm is whitespace-sensitive. If code won't compile after a student types it in, the first question is: "Did you indent the body of the function?" Have a simple indentation example on the board all session.
