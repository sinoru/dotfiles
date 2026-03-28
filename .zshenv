export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
export GPG_TTY=$(tty)
export PYTHON_CONFIGURE_OPTS="$PYTHON_CONFIGURE_OPTS --enable-optimizations --with-lto"

# Load machine-local overrides from the symlink's directory (~ by default).
# Intentionally not using :A — we want the symlink path, not the repo path.
_zshenv_dir="${${(%):-%N}:h}"
if [[ -f "$_zshenv_dir/.zshenv.local" ]]; then
    source "$_zshenv_dir/.zshenv.local"
fi
unset _zshenv_dir
