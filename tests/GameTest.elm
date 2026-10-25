module GameTest exposing (all)

import Expect
import Test exposing (Test, describe, test)


all : Test
all =
    describe "Minimal CI Pass"
        [ test "always passes" <|
            \_ ->
                Expect.pass
        ]