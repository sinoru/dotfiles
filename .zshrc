ANTIDOTE="$(brew --prefix antidote)/share/antidote/antidote.zsh"

if [ -f "$ANTIDOTE" ]; then
    source $ANTIDOTE

    source <(antidote init)

    antidote bundle zsh-users/zsh-autosuggestions
    antidote bundle zsh-users/zsh-completions

    antidote bundle mattmc3/zephyr
    antidote bundle mattmc3/zephyr path:plugins/autosuggestions
    antidote bundle mattmc3/zephyr path:plugins/syntax-highlighting

    antidote bundle ohmyzsh/ohmyzsh path:lib
    antidote bundle ohmyzsh/ohmyzsh path:plugins/git
    antidote bundle ohmyzsh/ohmyzsh path:plugins/extract

    antidote bundle mattmc3/zephyr path:plugins/completions

    antidote bundle ohmyzsh/ohmyzsh path:themes/robbyrussell.zsh-theme
fi
