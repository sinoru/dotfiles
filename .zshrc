ANTIGEN="$(brew --prefix antigen)/share/antigen/antigen.zsh"

if [ -f "$ANTIGEN" ]; then
    source $(brew --prefix antigen)/share/antigen/antigen.zsh

    antigen use oh-my-zsh

    antigen bundle git

    antigen bundle zsh-users/zsh-autosuggestions
    antigen bundle zsh-users/zsh-syntax-highlighting

    antigen theme robbyrussell

    antigen apply
fi
