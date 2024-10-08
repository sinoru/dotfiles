export PATH="$HOME/.cargo/bin:$PATH"
export GPG_TTY=$(tty)
export PYTHON_CONFIGURE_OPTS="$PYTHON_CONFIGURE_OPTS --enable-optimizations --with-lto"

# Set PATH, MANPATH, etc., for Homebrew.
if [ -x /opt/homebrew/bin/brew  ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

if (( $+commands[gpgconf] )); then
    if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ] && [ -z "${SSH_CONNECTION}" ]; then
        unset SSH_AGENT_PID
        export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
    fi
fi
