# Plan

Extend the existing svg-base64 branch. Keep the complete game in src/Game.elm as a single file students can paste into Ellie. There is no root Game.elm copy or symlink.

1. Move editable eagle SVGs into images/. Remove superseded artwork; rename part types and drawing helpers to eagle terminology.
2. Preserve embedded Base64 constants, wrapping-aware segment directions, tail identity, curved tiles, and normal/reversed palette blending.
3. Set the application's source directory to src/ and put the suite in tests/GameTest.elm. Expose tested types and pure functions explicitly. Use elm-explorations/test and Expect assertions, importing Game directly without source rewriting or a JavaScript harness. This standard layout keeps application, test, and generated runner source directories separate.
4. Add just test with the existing Nix-provided elm-test runner. Update Elm and Nix dependency snapshots for test dependencies.
5. Write tutorials/custom-svg.md and tutorials/testing-elm.md and link them from README.md. Explain the actual week5/Main.elm starter and finished src/Game.elm, provide a complete head-only replacement, then explain the segmented renderer. Introduce browser-only checks before local testing.
6. Update the dev command and Nix source fileset/build entry point for src/Game.elm. Validate tests, formatting, finished and Week 5 compilation, Nix packaging, tutorial examples/links, asset equality, and removal of obsolete terminology. Preserve unrelated classroom files and weekly HTML.

## Variable food

Add FoodType, allFoodTypes, foodName, and differentFood with Random.uniform over the filtered catalogue. Keep food as a Position and add foodType and randomSeed fields to Model. Seed randomness through Task.perform InitializeFood Time.now at startup; use Random.step when eating and restarting so movement remains pure. Promote elm/random to a direct application dependency. Preserve existing food placement and score rules.

Draw ten standalone SVG prey icons under images/food/, embed their data URIs in Game.elm, render the selected icon at the current food position, and show its name near the score. Extend the real Elm suite with catalogue, generator, catch, ordinary-movement, startup, and restart checks. Write tutorials/variable-food.md with matching snippets, explain the difference between the food's position and type, and link it from the other student material. Validate formatting, tests, compilation/build, image markup/preview and embedded/source equality, and tutorial examples.

## Animated background tutorial

Create tutorials/animated-background.md and a standalone Main.elm/elm.json under tutorials/examples/animated-background/. Use two simple SVG clouds (an ellipse and two circles), CSS transforms with 90/110-second loops and 6% opacity, and a withSky helper around the existing game view. CSS handles animation without Elm state. Provide a prefers-reduced-motion media query. Teach integration by renaming the existing view to viewGame and adding a small new view wrapper. Link from README.md; compile the example and verify the same wrapper against the current Game module and Week 5 starter. Apply the demonstrated helpers and wrapper to src/Game.elm as requested, preserving gameplay. No implementation-mirroring tests are needed for this presentation change.
