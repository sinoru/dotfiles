optimpng() {
    oxipng \
        -o max \
        --fast \
        -p \
        -z --zi 250 --ziwi 150 \
        --brute-lines 16 \
        -t $(( $(sysctl -n hw.logicalcpu) - ${$(sysctl -n hw.perflevel1.logicalcpu 2> /dev/null):-0} )) \
        $@
}
