module Main exposing (main)

import Html exposing (Html, div, h1, node, p, text)
import Html.Attributes exposing (class, style)
import Svg
import Svg.Attributes as SA



-- CSS moves the clouds. Elm does not need a timer or animation messages.


skyCss : String
skyCss =
    """
body { margin: 0; }

.sky {
    position: relative;
    overflow: hidden;
    min-height: 100vh;
    box-sizing: border-box;
    padding: 24px;
    background: #071225;
    display: grid;
    place-items: center;
}

.cloud {
    position: absolute;
    left: 0;
    width: 240px;
    height: 90px;
    fill: #dbeafe;
    opacity: 0.06;
    pointer-events: none;
    animation: drift 90s linear infinite;
}

.cloud-one { top: 12%; animation-delay: -30s; }
.cloud-two { top: 70%; animation-duration: 110s; animation-delay: -80s; }

.sky-game { position: relative; }

@keyframes drift {
    from { transform: translateX(-260px); }
    to   { transform: translateX(100vw); }
}

@media (prefers-reduced-motion: reduce) {
    .cloud { animation: none; left: 8%; }
    .cloud-two { left: 60%; }
}
"""


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


withSky : Html msg -> Html msg
withSky game =
    div [ class "sky" ]
        [ node "style" [] [ text skyCss ]
        , cloud "cloud-one"
        , cloud "cloud-two"
        , div [ class "sky-game" ] [ game ]
        ]



-- This still board previews the effect. Wrap your own game's view the same way.


main : Html msg
main =
    withSky
        (div [ style "font-family" "sans-serif", style "text-align" "center" ]
            [ h1 [ style "color" "#e6cba0" ] [ text "EAGLE STRIKE" ]
            , Svg.svg
                [ SA.width "400"
                , SA.height "400"
                , SA.viewBox "0 0 400 400"
                , style "max-width" "80vw"
                , style "height" "auto"
                , style "background" "#0a1628"
                , style "border" "3px solid #1d4ed8"
                , style "border-radius" "10px"
                ]
                (List.map
                    (\x ->
                        Svg.rect
                            [ SA.x (String.fromInt x), SA.y "180", SA.width "20", SA.height "20", SA.rx "3", SA.fill "#15803d" ]
                            []
                    )
                    [ 120, 140, 160 ]
                    ++ [ Svg.rect [ SA.x "180", SA.y "180", SA.width "20", SA.height "20", SA.rx "3", SA.fill "#fffdf1" ] []
                       , Svg.polygon [ SA.points "196,184 207,190 196,196", SA.fill "#f5bb46" ] []
                       , Svg.circle [ SA.cx "250", SA.cy "110", SA.r "8", SA.fill "#e6cba0" ] []
                       ]
                )
            , p [ style "color" "#c4cbd6" ] [ text "Watch the sky for a moment. The board stays still." ]
            ]
        )
