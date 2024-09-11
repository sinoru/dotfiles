ANTIDOTE="$(brew --prefix antidote)/share/antidote/antidote.zsh"

if [ -f "$ANTIDOTE" ]; then
    source $ANTIDOTE

    source <(antidote init)

    antidote bundle zsh-users/zsh-autosuggestions
    antidote bundle zsh-users/zsh-completions

    autoload -Uz compinit
    compinit

    antidote bundle ohmyzsh/ohmyzsh path:lib
    antidote bundle ohmyzsh/ohmyzsh path:plugins/git
    antidote bundle ohmyzsh/ohmyzsh path:plugins/extract

    antidote bundle ohmyzsh/ohmyzsh path:themes/robbyrussell.zsh-theme
fi

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
