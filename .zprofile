# Set PATH, MANPATH, etc., for Homebrew.
if [ -x /opt/homebrew/bin/brew  ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

if (( $+commands[rbenv] )); then
    eval "$(rbenv init -)"
fi

if (( $+commands[nodenv] )); then
    eval "$(nodenv init -)"
fi

if (( $+commands[pyenv] )); then
    eval "$(pyenv init -)"
fi

if (( $+commands[pyenv-virtualenv] )); then
    eval "$(pyenv virtualenv-init -)"
fi

if (( $+commands[gpgconf] )); then
    (nohup gpgconf --launch gpg-agent &> /dev/null &)
    unset SSH_AGENT_PID
    export SSH_AUTH_SOCK=$HOME/.gnupg/S.gpg-agent.ssh
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
