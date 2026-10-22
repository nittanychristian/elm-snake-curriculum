# Tasks

- [x] T001 Implement embedded eagle head, repeating body, and tail with wrapping-aware orientation.
- [x] T002 Implement curved body tiles and endpoint palette blending for all eight directed turns.
- [x] T003 Organize images/ and remove superseded artwork and terminology.
- [x] T004 Port behavioral checks into repository elm-test tests and expose the tested API explicitly.
- [x] T005 Add just test and update Elm/Nix test dependencies.
- [x] T006 Write and link the custom SVG and Elm testing tutorials.
- [x] T007 Validate tests, compilation, formatting, packaging, asset equality, tutorial examples, and cleanup.

Validation: the user-approved src/ and tests/ layout avoids source-directory overlap, with no root Game.elm copy or symlink. just test passed all 35 tests, including 1,600 adjacency cases, 3,200 bend placements, all eight corner palette mappings, and fuzzed movement. Elm formatting, finished and Week 5 compilation, Nix packaging, the three tutorial transition/browser fixtures, local tutorial links, embedded/source image equality, and obsolete-terminology cleanup passed. Build and dev commands target src/Game.elm.

- [x] T008 Add ten prey SVGs and embed them for the food renderer.
- [x] T009 Add food type, clock-seeded random state, non-repeating selection after catches/restart, and a visible prey name.
- [x] T010 Add behavioral tests and write/link the variable-food tutorial; update earlier tutorials for the new model.
- [x] T011 Validate tests, formatting, build, assets/previews, and tutorial examples.

Variable-food validation: all 44 tests passed, including 2,000 exclusion/catalogue cases, reachability of all nine alternatives, all ten initial choices across clock seeds, and catch/restart/state preservation. Game and committed picker example compile; formatting and Nix packaging pass. All ten SVGs and the committed preview validate, the artwork was visually inspected, embedded bytes match the source images, local documentation links resolve, and the Week 5 transition assembled from the tutorial snippets compiles. Each catch remains worth one point; food positioning uses the existing rule.

- [x] T012 Write the simple animated-sky tutorial and a self-contained example; link the lesson from README.md.
- [x] T013 Validate example formatting/compilation, integration with both game versions, documentation links, and reduced-motion CSS.

Animated-background validation: the committed standalone example passes elm-format and compilation. Applying the tutorial's imports/helpers/view wrapper to both game versions compiles. Documentation links and the example's dev command resolve. CSS includes 6% opacity, 90/110-second transforms, clipped decorative clouds with pointer-events disabled, and a reduced-motion rule that removes animation. No implementation-mirroring tests were added. Animation has not been exercised in a browser here.

- [x] T014 Apply the tutorial's sky background to the active src/Game.elm game and verify compilation and gameplay regression tests.

Active integration: src/Game.elm now contains skyCss, cloud, withSky, and the view/viewGame wrapper. Optimized compilation and all 44 gameplay tests pass. The tutorial tells users of the finished game to customize the existing settings rather than adding the helpers again.
