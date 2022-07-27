if (( $+commands[brew] )); then
    eval "$(brew shellenv)"
    export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1)"
fi

if (( $+commands[gpgconf] )); then
    (nohup gpgconf --launch gpg-agent &> /dev/null &)
    unset SSH_AGENT_PID
    export SSH_AUTH_SOCK=$HOME/.gnupg/S.gpg-agent.ssh
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
