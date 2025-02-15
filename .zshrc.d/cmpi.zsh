cmpi() {
    compare \
        -metric SSIM \
        $1 \
        $2 \
        /dev/null
}
