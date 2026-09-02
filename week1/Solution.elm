module Solution exposing (main)

import Html exposing (Html, div, h2, p, text)


myName : String
myName =
    "Ada"


double : Int -> Int
double n =
    n * 2


describeNumber : Int -> String
describeNumber n =
    if n > 0 then
        "positive"

    else if n < 0 then
        "negative"

    else
        "zero"


letterGrade : String -> String
letterGrade letter =
    case letter of
        "A" ->
            "Excellent"

        "B" ->
            "Good"

        "C" ->
            "Okay"

        _ ->
            "Keep trying"


-- Stretch challenge: if/else fits here because we're comparing ranges
grade : Int -> String
grade score =
    if score >= 90 then
        "A"

    else if score >= 80 then
        "B"

    else if score >= 70 then
        "C"

    else if score >= 60 then
        "D"

    else
        "F"


main : Html msg
main =
    div []
        [ h2 [] [ text ("Hello, " ++ myName ++ "!") ]
        , p [] [ text ("double 7 = " ++ String.fromInt (double 7)) ]
        , p [] [ text ("double 21 = " ++ String.fromInt (double 21)) ]
        , p [] [ text ("describeNumber 5 = " ++ describeNumber 5) ]
        , p [] [ text ("describeNumber -3 = " ++ describeNumber -3) ]
        , p [] [ text ("describeNumber 0 = " ++ describeNumber 0) ]
        , p [] [ text ("letterGrade \"A\" = " ++ letterGrade "A") ]
        , p [] [ text ("letterGrade \"Z\" = " ++ letterGrade "Z") ]
        , p [] [ text ("grade 95 = " ++ grade 95) ]
        , p [] [ text ("grade 82 = " ++ grade 82) ]
        , p [] [ text ("grade 55 = " ++ grade 55) ]
        ]
