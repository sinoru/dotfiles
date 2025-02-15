ARGZERO="${(%):-%N}"

for script in "${ARGZERO:A:h}/${ARGZERO:A:t}.d/"*.zsh; do
    source "$script"
done
