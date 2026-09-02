module Main exposing (main)

import Html exposing (Html, div, p, text)


-- A value. This never changes.
myName : String
myName =
    "Ms. Garcia's Class"


-- A function. Give it a number, get a String back.
-- Nothing outside is touched.
double : Int -> Int
double n =
    n * 2


-- if/else is an EXPRESSION. It produces a value.
-- It MUST have an else — otherwise what value does it produce?
describeNumber : Int -> String
describeNumber n =
    if n > 0 then
        "positive"

    else if n < 0 then
        "negative"

    else
        "zero"


-- case is also an EXPRESSION. It produces a value.
-- The compiler requires you to handle EVERY possible input.
-- _ means "anything else"
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


-- view turns our values into something visible on screen.
main : Html msg
main =
    div []
        [ p [] [ text ("Hello, " ++ myName ++ "!") ]
        , p [] [ text ("double 7 = " ++ String.fromInt (double 7)) ]
        , p [] [ text ("describeNumber 5 = " ++ describeNumber 5) ]
        , p [] [ text ("describeNumber -3 = " ++ describeNumber -3) ]
        , p [] [ text ("letterGrade \"A\" = " ++ letterGrade "A") ]
        , p [] [ text ("letterGrade \"Z\" = " ++ letterGrade "Z") ]
        ]
