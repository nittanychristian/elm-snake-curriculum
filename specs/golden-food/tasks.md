# Tasks

- [x] T001 Add catch counting, golden cadence, bonus scoring, halo, and score labels in src/Game.elm.
- [x] T002 Test fifth/tenth scoring, movement, one-segment growth, stopped state, restart, and best score in tests/GameTest.elm.
- [x] T003 Add an Ellie-ready example under tutorials/examples/golden-food and an incremental tutorial, linked from README.md.
- [x] T004 Format Elm, run tests, build the game, and compile the example through Nix; review the final diff.

## Validation

- `nix develop -c just test`: all 52 tests pass (eight new golden-food tests).
- `nix build --no-link`: finished game builds successfully.
- Tutorial example: `elm make Main.elm` in its own directory through the Nix development shell compiles successfully.
- Changed Elm files formatted with elm-format; `git diff --check` passes.
- All lesson materials are under tutorials/; week5/ has no edits.
