# Golden food

## Student stories

1. As a player, I can spot every fifth piece of food by its golden halo and earn three points for catching it.
2. As a student, I can follow a browser-friendly tutorial explaining a counter, `modBy`, an `if` expression, SVG layering, and a small Elm test.

## Requirements and acceptance

- Count catches separately from score. Starting at zero catches, food numbers 5, 10, 15, ... are golden; all other food is worth one point.
- Given four catches, the current food has a gold halo; catching it adds three points, adds one catch, grows one segment, and makes the next food ordinary. The tenth food is golden even though the score already includes a bonus.
- Ordinary movement and game-over ticks do not change catches or award points. Restart clears catches and score, preserves the best score, and starts with ordinary food.
- Reuse the existing prey images and random selection; golden is a bonus on any prey type. Label points and catches accurately and show a text cue for golden food.
- Keep the implementation simple: one counter, two small pure helpers, a conditional SVG halo. No new packages, messages, timers, or artwork files.
- Supply a tutorial, a complete runnable Ellie example based on the Week 5 starter, and a README link. Explain how the same changes fit the finished src/Game.elm.
- Test scoring across multiple bonus boundaries, movement, growth, restart, and high score. Build the finished game and compile the example through Nix.

## Success criteria

The fifth and tenth catches are each worth three points; ten catches yield fourteen points. Both game and example compile. A student can paste the example into Ellie and follow the tutorial without installing tools.

## Requirements checklist

- [x] Bonus cadence uses catches, independent of points.
- [x] Starting, ordinary, bonus, stopped, and restarted states are specified.
- [x] Scope fits existing middle school concepts.
