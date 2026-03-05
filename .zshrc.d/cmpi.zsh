cmpi() {
    if [ $(($#%2)) -ne 0 ]; then
        echo "Invalid number of arguments. Please provide pairs of images to compare."
        return 1
    fi

    if [[ $# -eq 2 && -d $1 && -d $2  ]]; then
        typeset -A compares=()

        for lhs in $1/*; do
            lhs_name=$(basename "$lhs")

            compares[$lhs_name]=""
        done

        for rhs in $1/*; do
            rhs_name=$(basename "$rhs")

            compares[$rhs_name]=${rhs_name}
        done

        for lhs_name rhs_name in ${(kv)compares}; do
            if ! [[ -f "$1/$lhs_name" ]]; then
                echo "Warning: No matching image found for $lhs_name in $1"
                echo ""
                continue
            elif ! [[ -f "$2/$rhs_name" ]]; then
                echo "Warning: No matching image found for $lhs_name in $2"
                echo ""
                continue
            fi

            cmpi::compare "$1/$lhs_name" "$2/$rhs_name"
        done
    else
        pairs=$(($#/2))

        for ((i=1; i<=$pairs; i++)); do
            lhs=${(P)i}
            rhs=${(P)$((pairs+i))}
            cmpi::compare $lhs $rhs
        done
    fi
}


cmpi::compare() {
    echo "Image: $1"
    echo "Image: $2"

    echo ""

    compare -verbose -metric rmse $1 $2 null: 2>&1 | sed -n 's/^  \(.*\)$/\1/p'
    compare -verbose -metric ssim $1 $2 null: 2>&1 | sed -n 's/^  \(.*\)$/\1/p'
    compare -verbose -metric psnr $1 $2 null: 2>&1 | sed -n 's/^  \(.*\)$/\1/p'

    echo ""
    echo ""
}