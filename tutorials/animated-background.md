# Add a quiet, moving sky

Let's put two faint clouds behind the game. They drift slowly across a dark blue sky while the board stays still.

You will add a drawing around the game you already have. Your movement rules, score, model, and messages can stay as they are.

The finished [src/Game.elm](../src/Game.elm) already includes this background. If you are using that version, jump to step 5 to change the settings. The integration steps show how to add it to the Week 5 starter or your own earlier version.

## 1. Try the example

Open [the complete example](examples/animated-background/Main.elm).

In your game's Ellie at https://ellie-app.com/, replace the Elm editor's contents with that file and click **Compile**. It uses the same `elm/html` and `elm/svg` packages as the game. If you start with a blank Ellie, add **elm/svg 1.0.1** in the Packages panel.

The example shows a still board so you can watch the background. The clouds move very slowly: give them a few seconds!

If you are using the local repository instead:

```sh
nix develop
just dev tutorials/examples/animated-background
```

## 2. See how a cloud is made

Each cloud uses shapes you learned in Week 2: one ellipse and two circles.

```elm
cloud : String -> Html msg
cloud name =
    Svg.svg
        [ SA.class ("cloud " ++ name)
        , SA.viewBox "0 0 240 90"
        , SA.width "240"
        , SA.height "90"
        , Html.Attributes.attribute "aria-hidden" "true"
        , Html.Attributes.attribute "focusable" "false"
        ]
        [ Svg.ellipse [ SA.cx "120", SA.cy "62", SA.rx "105", SA.ry "24" ] []
        , Svg.circle [ SA.cx "85", SA.cy "48", SA.r "28" ] []
        , Svg.circle [ SA.cx "140", SA.cy "38", SA.r "34" ] []
        ]
```

`cloud "cloud-one"` and `cloud "cloud-two"` make two copies. Their names let us put them at different heights and give them different speeds. The last two attributes tell the browser that the clouds are decoration.

## 3. Let CSS do the moving

In the example, `skyCss` is a string containing CSS, the browser's language for styling a page. Elm's triple quotation marks let the string span several lines.

This is the animation rule inside that string:

```css
@keyframes drift {
    from { transform: translateX(-260px); }
    to   { transform: translateX(100vw); }
}
```

`translateX` moves something sideways. The cloud starts just outside the left edge and ends outside the right edge. `100vw` means the width of the browser window.

The clouds use this setting:

```css
animation: drift 90s linear infinite;
```

Read it as: “Run `drift` for 90 seconds, at a steady speed, and repeat.” The second cloud uses 110 seconds so they do not travel together.

The browser handles the movement. We do not need an Elm timer, another `Msg`, or an x coordinate in the model.

## 4. Wrap your game in the sky

Start from your own game, [week5/Main.elm](../week5/Main.elm), or [src/Game.elm](../src/Game.elm).

Copy these **three definitions**, including their type annotations, from the [example](examples/animated-background/Main.elm) into your game:

1. `skyCss`
2. `cloud`
3. `withSky`

You do not need to copy the example's `main` or its still board.

The two game versions already import `Svg` and `Svg.Attributes as SA`. Update the HTML imports to include `node` and `class`:

```elm
import Html exposing (Html, div, h1, node, p, text)
import Html.Attributes exposing (class, style)
```

If you already use other HTML functions, keep those in the imports too.

Find your current view function:

```elm
view : Model -> Html Msg
view model =
```

Rename those two lines:

```elm
viewGame : Model -> Html Msg
viewGame model =
```

Keep everything inside that function in place. Then add this small new function:

```elm
view : Model -> Html Msg
view model =
    withSky (viewGame model)
```

Leave `view = view` in `main` as it is. Now the new `view` calls your old drawing function and places its result inside the sky.

`withSky` puts the clouds behind a separate game container. It clips clouds when they leave the window, and `pointer-events: none` lets clicks pass through them. The board keeps its solid navy background so the eagle and prey remain clear.

Compile and play. The sky moves; the board does not.

## 5. Change just three settings

Edit these numbers inside `skyCss`:

| Setting | Starting value | Try changing it to |
| --- | --- | --- |
| Cloud opacity | `opacity: 0.06` | `0.04` for fainter clouds |
| Travel time | `drift 90s` | `120s` for slower movement |
| First cloud's height | `top: 12%` | `20%` to move it down |

Opacity goes from `0` (invisible) to `1` (fully visible). A longer travel time makes movement slower. Keep the clouds faint so they are scenery rather than obstacles.

The second cloud has its own `animation-duration: 110s` and `top: 70%` settings. You can change those too. The negative `animation-delay` values start the clouds partway through their journeys, so you do not have to wait for them to enter the screen.

Try changing one setting at a time, then compile and look at the result.

## 6. Respect reduced motion

The example includes this rule:

```css
@media (prefers-reduced-motion: reduce) {
    .cloud { animation: none; left: 8%; }
    .cloud-two { left: 60%; }
}
```

Some people ask their device to reduce animations. This rule keeps the clouds still for them. Keep it when you customize your sky. If the example's clouds stay still, check whether that preference is enabled on your device.

## Check your work

- Let the game run for a while. Are the clouds slow and faint?
- Does the board stay in one place, with every prey image easy to see?
- Can you still use the controls?
- Make the browser window narrower. Does the background still fill it?
- With reduced motion enabled, do the clouds stay still?

You can use the same idea for another scene later: change the shapes and colors while keeping the movement gentle.
