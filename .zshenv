export PATH="$HOME/.cargo/bin:$PATH"
export GPG_TTY=$(tty)
export PYTHON_CONFIGURE_OPTS="$PYTHON_CONFIGURE_OPTS --enable-optimizations --with-lto"

if (( $+commands[brew] )); then
    export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1)"
fi