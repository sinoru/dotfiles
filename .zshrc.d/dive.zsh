if (( $+commands[dive] )); then
    dive() {
        if test -n "$LANG"
        then
            LANG= LC_CTYPE=UTF-8 env dive "$@"
        else
            env dive "$@"
        fi
    }
fi
