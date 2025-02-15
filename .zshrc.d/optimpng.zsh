optimpng() {
    oxipng -o max -p --fast -Z --zi 20 -t $(( $(sysctl -n hw.logicalcpu) - ${$(sysctl -n hw.perflevel1.logicalcpu 2> /dev/null):-0} )) $@
}
