antidote="$(brew --prefix antidote)/share/antidote/antidote.zsh"

if [ -f "$antidote" ]; then
    source $antidote

    zstyle ':antidote:bundle' use-friendly-names 'yes'

    antidote load
fi
