# Run a live-reload dev server.
# Usage:
#   just dev          — serves Game.elm (the finished snake game)
#   just dev week1    — serves week1/Main.elm
#   just dev week2    — serves week2/Main.elm
#   ...

dev dir="":
    #!/usr/bin/env bash
    if [ -z "{{dir}}" ]; then
        elm-live Game.elm --open
    else
        cd {{dir}} && elm-live Main.elm --open
    fi
