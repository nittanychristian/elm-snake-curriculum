# Make your own game character with SVG

You will replace the shapes in the Week 5 eagle with artwork you draw yourself. Start with a custom head, then try a matching body and tail.

The Week 5 starter in this repository is [week5/Main.elm](../week5/Main.elm). If your downloaded copy is called `Game.elm`, use that file instead. The finished [src/Game.elm](../src/Game.elm) shows the complete version with custom artwork, curved bodies, wrapping edges, and tests. Its extra gameplay features are separate from changing the artwork.

## 1. Draw an icon in your browser

Open SVGEdit: https://svgedit.netlify.app/index.html

1. Open the upper-left menu and choose **Document Properties** (shortcut: **D**).
2. Set the canvas width and height to **100** and apply the change. Zoom in if the drawing area looks small.
3. Draw your character's head **facing right**. Keep the background transparent.
4. Use bold shapes and a clear outline. In the game, each 100 × 100 drawing becomes just **20 × 20 pixels**.
5. Save the drawing as an SVG file.

The supplied [eagle head](../images/eagle-head.svg) is an example. Open it in SVGEdit if you want to study or modify it.

An SVG describes shapes rather than storing a grid of colored pixels. Its outer element normally looks like this:

```xml
<svg xmlns="http://www.w3.org/2000/svg"
     width="100" height="100" viewBox="0 0 100 100">
  <!-- Your shapes go here. -->
</svg>
```

## 2. Turn the file into text you can paste

Open SVG Encoder: https://svgencoder.com/

1. Upload your SVG file.
2. Choose **Base64** for encoding and **Data URI** for the output format.
3. Click **Copy**.

The copied text begins with `data:image/svg+xml;base64,`. That prefix tells the browser that the rest of the text contains an SVG image. Copy the whole thing, including the prefix.

You do not need a webserver, account, or terminal. The image will travel with the Elm code when you share your Ellie.

## 3. Replace the Week 5 head

Open your Week 5 game in Ellie: https://ellie-app.com/

Save a copy before experimenting. Keep the module name Ellie already uses, usually `Main`.

The starter's `drawEagleHead` builds a head from a rectangle, triangle, and circle. We will keep its type and replace its contents. This lets the existing `view` continue calling it.

First add this value above `drawEagleHead`. Replace everything between the quotation marks with your copied data URI:

```elm
headIcon : String
headIcon =
    "PASTE_YOUR_COMPLETE_DATA_URI_HERE"
```

Now replace the entire old `drawEagleHead` definition with:

```elm
drawEagleHead : Direction -> Position -> List (Svg msg)
drawEagleHead direction pos =
    let
        orientation =
            case direction of
                Right ->
                    "scale(1 1)"

                Left ->
                    "scale(-1 1)"

                Up ->
                    "rotate(-90)"

                Down ->
                    "rotate(90)"
    in
    [ Svg.g
        [ SA.transform
            ("translate("
                ++ String.fromInt (pos.x * cellSize + cellSize // 2)
                ++ " "
                ++ String.fromInt (pos.y * cellSize + cellSize // 2)
                ++ ") "
                ++ orientation
            )
        ]
        [ Svg.image
            [ SA.xlinkHref headIcon
            , SA.x (String.fromInt (negate cellSize // 2))
            , SA.y (String.fromInt (negate cellSize // 2))
            , SA.width (String.fromInt cellSize)
            , SA.height (String.fromInt cellSize)
            ]
            []
        ]
    ]
```

The starter already imports `Svg` and `Svg.Attributes as SA`. Change its SVG import to:

```elm
import Svg exposing (Svg, rect, svg)
```

Delete `pt`, the coordinate-pair helper, if nothing uses it after removing the old triangle. Keep `drawCell`: the board and food still use rectangles.

Click **Compile**. Try all four directions.

The image is drawn around its own center. `translate` moves that center to the center of the board cell. `rotate` turns it, while `scale(-1 1)` mirrors it horizontally. Mirroring lets a left-facing head stay upright.

## 4. Design a body and tail that join

Make each drawing 100 × 100. Use these connections so the finished game's renderer can place them together:

| Drawing | Connection |
| --- | --- |
| Head | Left edge, from y = 28 to y = 72 |
| Straight body | Both left and right edges, from y = 28 to y = 72 |
| Tail | Right edge, from y = 28 to y = 72 |
| Bend | Left edge from y = 28 to 72, and top edge from x = 28 to 72 |

The body needs to look good when repeated. Keep its joining edges the same thickness and color. Avoid outlines along those edges: an outline would appear as a dividing line between every block. Keep feathers or other decorations inside the body silhouette.

Here are the editable examples:

- [Head](../images/eagle-head.svg)
- [Straight body](../images/eagle-body.svg)
- [Tail](../images/eagle-tail.svg)
- [Bend](../images/eagle-bend.svg)
- [Bend with reversed colors](../images/eagle-bend-reversed.svg)

## 5. Give each segment its own direction

The Week 5 game draws every body position with this line:

```elm
++ List.map (drawCell "#15803d") model.body
```

A custom image needs more information: which picture should appear, and which direction it should face?

Add these types near `Position`:

```elm
type EaglePart
    = EagleHead
    | EagleBody
    | EagleBend Direction
    | EagleTail


type alias Segment =
    { part : EaglePart
    , direction : Direction
    , position : Position
    }
```

You can use different character names if you rename them consistently. `EagleBend Direction` remembers where the segment behind the bend is located.

The model already stores body positions in order, from nearest the head to farthest away. Keep that list. The last position is the tail; it does not need a separate model field.

To find a segment's direction, look toward the position immediately ahead:

```elm
directionToward : Position -> Position -> Direction
directionToward pos ahead =
    if nextHead Right pos == ahead then
        Right

    else if nextHead Left pos == ahead then
        Left

    else if nextHead Up pos == ahead then
        Up

    else
        Down
```

This helper assumes neighboring positions form a valid chain. It reuses `nextHead`, so it also understands wrapping if your version of `nextHead` wraps. The original Week 5 starter ends the game at a wall; adding custom artwork does not require changing that rule.

## 6. Use the finished segmented renderer

For the full body, tail, and curves, open [src/Game.elm](../src/Game.elm) alongside your Week 5 file. Copy the following pieces into your game:

1. The five image constants: `headIcon`, `bodyIcon`, `tailIcon`, `bendIcon`, and `reversedBendIcon`. Replace each data URI with the corresponding artwork you encoded.
2. The `EaglePart` and `Segment` types above, if you have not added them yet.
3. These functions, including their type annotations: `isOpposite`, `directionToward`, `bodySegments`, `eagleSegments`, `cornerRotation`, `oppositeDirection`, `featherSide`, `cornerColors`, `drawEagleImage`, `drawBend`, and `drawEagleSegment`. The original Week 5 starter does not have `isOpposite`; the body renderer needs it to distinguish a straight segment from a corner.

Replace existing definitions rather than adding a second copy. Once this renderer is in place, remove the head-only `drawEagleHead` function from step 3. Keep `drawCell` and `drawBoard`.

Inside `view`, replace these two lines:

```elm
++ List.map (drawCell "#15803d") model.body
++ drawEagleHead model.direction model.head
```

with this one:

```elm
++ List.map drawEagleSegment (eagleSegments model)
```

The complete list of board pictures now looks like:

```elm
(drawBoard
    ++ List.map drawEagleSegment (eagleSegments model)
    ++ [ drawCell "#dc2626" model.food ]
)
```

Your existing movement and growth code can stay. On each drawing, `bodySegments` walks through the positions and works out which ones are straight bodies, bends, or the tail.

## 7. Make turns look continuous

Rotating a straight rectangle does not bend it. At a corner, the renderer uses a curved tile that connects two edges.

The example bend is a quarter of a ring centered at the canvas's top-left corner. Its inner radius is 28 and outer radius is 72, giving it the same 44-unit thickness as the straight body. The renderer rotates this drawing around the cell center for the other corners.

The example has a dark feather band on one side and a light band on the other. Make the reversed bend with those bands exchanged. Keep its shape exactly the same.

`cornerColors` checks the incoming and outgoing directions. `drawBend` selects the normal or reversed tile, or blends them with a mask when their colors need to change sides through the curve. If you use different colors, keep the same dark-side/light-side layout in your five drawings so these rules still match.

## Check your work

- Move right and left: does the head stay upright?
- Turn both clockwise and counterclockwise: do the body edges and colors meet?
- Eat food: does the tail stay attached as the body grows?
- Try several body blocks: can you see dividing lines between tiles?
- If your game wraps, turn near an edge and check the connection on both sides.

If the image is missing, check that the data URI is complete and inside one pair of double quotation marks. If the direction is wrong, check that the original drawing faces right. If you edit an SVG file later, encode it again and replace its embedded value; saving the file alone does not update the Elm string.

The finished game also uses `elm/random` for its prey choices. If you paste the whole file into Ellie, add that package in Ellie's Packages panel.

Next: [write tests for your game](testing-elm.md), or [add variable food](variable-food.md).
