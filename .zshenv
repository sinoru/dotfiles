unset SSH_AGENT_PID
export SSH_AUTH_SOCK=$HOME/.gnupg/S.gpg-agent.ssh
export GPG_TTY=$(tty)
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(/usr/local/bin/brew --prefix openssl@1.1)"
