# Elm Snake Curriculum

A 5-week middle school after-school programming club. Students build a fully playable Snake game using Elm — a purely functional language that runs in the browser. No installation required: everything works on [ellie-app.com](https://ellie-app.com), including locked-down school Chromebooks.

## Structure

| Week | Topic | Game Milestone |
|------|-------|----------------|
| [Week 1](week1/) | Values, types, pure functions, `if/else`, `case` | Text output from student-written functions |
| [Week 2](week2/) | Drawing with SVG, `List.map` | Empty Snake board rendered |
| [Week 3](week3/) | The Elm Architecture, `Direction` type, timer | Snake head moves automatically |
| [Week 4](week4/) | Body as a `List`, collision detection, food | Fully playable Snake |
| [Week 5](week5/) | Eagle Strike customization + show and tell | Each student's personalized game |

## Tools

- **[ellie-app.com](https://ellie-app.com)** — online Elm editor, shareable links, no install
- **Teacher prep each week:** open the week's starter snippet in Ellie, verify it compiles, share the link (write it on the board or post it in your class chat)

## Tutorials and artwork

- [Make your own character with SVG](tutorials/custom-svg.md): draw in a browser, embed images in Ellie, and extend the Week 5 starter with bodies, tails, and curves.
- [Write tests for your Elm game](tutorials/testing-elm.md): start with visible checks in Ellie, then learn standard Elm unit and fuzz tests.
- [Add variable food](tutorials/variable-food.md): use ten prey images and randomly choose a different type after each catch.
- [Add a quiet animated sky](tutorials/animated-background.md): draw two faint clouds and let CSS move them behind the game.
- [Catch golden food](tutorials/golden-food.md): make every fifth prey worth three points, draw a golden halo, and test the bonus rule.
- [Share your game with a pull request](tutorials/pr-game-previews.md): submit a game from a fork and get a playable GitHub Pages link, with setup steps for teachers.
- [Editable eagle artwork](images/): transparent 100 × 100 SVGs for the head, repeating body, tail, and two curved body palettes.
- [Prey artwork](images/food/): ten transparent 100 × 100 SVGs, embedded in the game for Ellie.

The Week 5 starter is `week5/Main.elm`. The finished [src/Game.elm](src/Game.elm) includes embedded eagle artwork, the full segment renderer, variable prey, golden food bonuses, and the quiet animated sky, plus wrapping, restart, and high scores. Its tests live in [tests/GameTest.elm](tests/GameTest.elm).

## Local Dev Setup (Nix)

If you have [Nix](https://nixos.org) installed, the repo includes a flake that gives you a full Elm toolchain with no other setup:

```sh
nix develop          # enter the dev shell (elm, elm-live, elm-format, elm-language-server)
```

With [direnv](https://direnv.net) the shell loads automatically when you `cd` into the repo (`direnv allow` once).

Run a live-reload server for any week or the finished game:

```sh
just dev             # src/Game.elm — the finished Week 5 snake
just dev week1       # week1/Main.elm
just dev week3       # week3/Main.elm
```

Build the finished game to `result/index.html`:

```sh
nix build
```

Run the game tests from the development shell:

```sh
just test
```

Or run `nix develop -c just test` directly from your usual shell. The suite checks movement, wrapping, growth, restart, segment orientation, all eight corner/color combinations, and non-repeating random food selection.

Run the PR preview publisher's tests with `nix develop -c just test-previews`.

After changing `elm.json` dependencies, regenerate the lock files:

```sh
elm2nix convert > elm-packages.nix
elm2nix snapshot
```

## Pedagogy

- Elm is purely functional — no mutation, no loops. `List.map`/`filter`/`foldl` replace loops; recursion is available but rarely needed at this level.
- `if/else` and `case` are *expressions* that produce values, not control-flow statements. Teach them that way from day one.
- The Elm Architecture (Model → View → Update) is introduced in Week 3 and is the backbone of all interactive code from then on.
- Elm's compiler errors are beginner-friendly. Teach students to read them rather than guess.

## When Students Are Stuck

1. "Read the error message out loud." Elm's errors tell you exactly what it expected vs. what it got.
2. "What type does this function expect? What type are you giving it?" Most errors are type mismatches.
3. "Can you make a smaller version of the problem?" Delete everything except the broken piece.

## Why Functional? (for students)

> "In most languages, functions can secretly change things — the bug might not be where the error shows up. In Elm, functions only take inputs and return outputs. Nothing else happens. That's why Elm programs almost never have mysterious bugs."
