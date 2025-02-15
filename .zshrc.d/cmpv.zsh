cmpv() {
    threads=$(( $(sysctl -n hw.logicalcpu) - ${$(sysctl -n hw.perflevel1.logicalcpu 2> /dev/null):-0} ))

    lhs=$1
    rhs=$2

    shift 2

    frame_rate=$(ffprobe \
        -v error \
        -select_streams V \
        -of default=noprint_wrappers=1:nokey=1 \
        -show_entries stream=r_frame_rate \
        "$lhs")

    time_base=$(sed 's|\([0-9]*\)\/\([0-9]*\)|\2/\1|' <<< "$frame_rate")

    ffmpeg \
        -hide_banner \
        -loglevel repeat+verbose \
        -stats \
        -i "$lhs" \
        -i "$rhs" \
        -fps_mode passthrough \
        -lavfi "[0:V]settb=${time_base},setpts=PTS-STARTPTS,split=3[main1][main2][main3]; \
                [1:V]settb=${time_base},setpts=PTS-STARTPTS,split=3[ref1][ref2][ref3]; \
                [main1][ref1]ssim[ssim]; \
                [main2][ref2]psnr[psnr]; \
                [ref3][main3]libvmaf=n_threads=${threads}[libvmaf]" \
        -map "[ssim]" -map "[psnr]" -map "[libvmaf]" \
        -f null -
}
