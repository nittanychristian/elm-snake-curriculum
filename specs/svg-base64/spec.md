# Custom eagle artwork and student testing

Students can draw SVG sprites, adapt the Week 5 game to display them, and write tests for gameplay and orientation. The finished src/Game.elm uses the eagle artwork as a complete example.

## Requirements

- Preserve position-based movement, growth, collision, high score, and restart behavior.
- Embed SVG data URLs so the game remains usable in Ellie without hosting assets.
- Store the five editable, transparent 100 × 100 eagle SVGs under images/.
- Face right by default, mirror left-facing artwork, and rotate vertical artwork.
- Derive segment direction and tail identity from existing positions. Recognize wrapping neighbors and bends.
- Match the dark and light bands at both endpoints of all eight directed turns.
- Use eagle terminology throughout code, specs, tutorials, and tests. Remove superseded artwork.
- Provide a beginner custom SVG tutorial starting from week5/Main.elm, explaining the transition to Game.elm with full browser URLs and no student hosting or terminal requirement.
- Commit standard Elm tests importing the real Game module. Provide just test and Nix-managed test dependencies.
- Use src/Game.elm and tests/GameTest.elm with no root game copy or symlink. Dev and build commands target src/Game.elm.
- Provide a testing tutorial with a browser-only introduction and a local elm-test path, covering expected/actual results, a failing example, and adding tests.
- Provide ten prey types (mouse, vole, rat, rabbit, squirrel, duck, quail, snake, lizard, frog), each with a transparent 100 × 100 SVG under images/food/ and an embedded image for Ellie.
- Randomly initialize food type from a clock-derived seed; after each catch, choose uniformly from the other nine types so consecutive catches never present the same type. Preserve the existing food position rule and one-point scoring.
- Keep random state in the model so tickGame remains pure and testable. Ordinary movement does not change food type or consume random state. Restart chooses a different type and continues the random sequence.
- Add tutorials/variable-food.md explaining the transition from position-only food to a food type, its image, seeded randomness, and tests.
- Add a simple animated-background tutorial and committed, self-contained example: two faint clouds drifting slowly across a navy sky, a stationary board, no extra model fields or update messages, and reduced-motion support. Explain three student settings: opacity, duration, and height. Apply the same sky wrapper to the active src/Game.elm game.

## Acceptance scenarios

- Initial rendering contains a right-facing head, body, and tail. All eight turns, including wrapping turns, join correctly.
- Eating grows the body and retains the tail; ordinary movement advances the tail. Restart preserves the high score. Empty and singleton bodies are safe.
- In the project Nix shell, just test runs tests of Game directly, without temporary source copies or private scripts.
- Tutorials link to real files and distinguish the Week 5 wall-collision behavior from the final game's wrapping behavior.
- Editable assets and embedded constants use the same eagle set.
- Every food type has a unique name/image, all random results are valid prey, and repeated catches always change type. The variable-food tutorial links to the actual sources and artwork.

## Requirements checklist

- [x] Gameplay, rendering, wrapping, corner palettes, and delivery are explicit.
- [x] Student browser constraints and Week 5 starting point are explicit.
- [x] Repository tests and their entry point are explicit.
