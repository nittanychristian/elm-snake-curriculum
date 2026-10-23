# Plan

Work in the golden-food sibling worktree, based on master. Use the existing repository's unnumbered spec convention and Nix development environment. There is no local Spec Kit template or constitution to extend.

Add foodEaten to Model and initialModel. isGoldenFood takes the number already eaten and tests modBy 5 (foodEaten + 1) == 0. foodPoints returns three or one. tickGame computes the award from the old counter, then increments the counter on a catch. Existing restart uses initialModel, so it naturally resets the new field.

Draw a quiet gold circle behind the existing prey image only when golden, using grid coordinates. Show Score separately from the catch count, and label the current prey's value. Keep the existing score-based speed progression.

Use tests/GameTest.elm to exercise actual tick/update behavior and cadence over ten successive catches. Create a smaller complete example from week5/Main.elm with the same helpers and halo around its plain food. Explain the changes incrementally in tutorials/golden-food.md, including both rendering variants and an Elm test. Compile both applications, format changed Elm, and run all game tests.
