convav() {
    if [[ $(sysctl -n hw.perflevel0.name) == 'Performance' ]]; then
        core_count=$(sysctl -n hw.perflevel0.logicalcpu)
    else
        core_count=$(sysctl -n hw.physicalcpu)
    fi

    if   (( $core_count <= 1 )); then # PARALLEL_LEVEL_1_RANGE
        level_of_parallelism=1
    elif (( $core_count <= 2 )); then # PARALLEL_LEVEL_2_RANGE
        level_of_parallelism=2
    elif (( $core_count <= 6 )); then # PARALLEL_LEVEL_3_RANGE
        level_of_parallelism=3
    elif (( $core_count <= 12 )); then # PARALLEL_LEVEL_4_RANGE
        level_of_parallelism=4
    elif (( $core_count <= 24 )); then # PARALLEL_LEVEL_5_RANGE
        level_of_parallelism=5
    else
        level_of_parallelism=6
    fi

    afconvert_encoder_info="afconvert $(afconvert 2>&1 | sed -n 's/.*Version: \([0-9.]\)/\1/p')"

    ffmpeg_common_options=(
        -hide_banner
        -loglevel repeat+verbose
        -stats
    )

    input=$1
    output=$2

    shift 2

    frame_rate=$(ffprobe \
        -v error \
        -select_streams V \
        -of default=noprint_wrappers=1:nokey=1 \
        -show_entries stream=avg_frame_rate \
        "$input")

    keyint=$(($(printf "%.0f" $(echo "scale=3;$frame_rate" | bc)) * 5))

    audio_streams_count=$(
        ffprobe \
        -v error \
        -select_streams a \
        -show_entries stream=index \
        -of csv=p=0 \
        "$input" | wc -w
    )

    audio_alac_outputs=()
    ffmpeg_audio_inputs=()
    ffmpeg_audio_maps=()
    ffmpeg_audio_metadata_maps=()

    for i in {0..$((audio_streams_count - 1))}; do
        audio_original_output=${output}.tmp.audio.$i.caf
        audio_alac_output=${output}.tmp.audio.$i.alac.mp4

        ffmpeg \
            $ffmpeg_common_options \
            -i "$input" \
            -map 0:a:$i \
            -c:a copy \
            "$audio_original_output" ||
            return $?

        afconvert \
            -v \
            -f mp4f \
            -d alac \
            "$audio_original_output" \
            "$audio_alac_output" ||
            return $?

        rm -f "$audio_original_output"

        audio_alac_outputs+=("$audio_alac_output")
        ffmpeg_audio_inputs+=("-i" "$audio_alac_output")
        ffmpeg_audio_maps+=("-map" "$(($i + 1)):a")
        ffmpeg_audio_metadata_maps+=("-map_metadata:s:a:$i" "0:s:a:$i")
    done

    ffmpeg \
        $ffmpeg_common_options \
        -i "$input" \
        $ffmpeg_audio_inputs \
        -map 0 \
        -map -0:a \
        $ffmpeg_audio_maps \
        -map_metadata:g 0:g \
        -map_metadata:s:v 0:s:v \
        $ffmpeg_audio_metadata_maps \
        -metadata modification_date=now \
        -metadata:s:a encoder="$afconvert_encoder_info" \
        -fps_mode passthrough \
        -c copy \
        -c:v libsvtav1 \
        -g $keyint \
        -preset 1 \
        -crf 32 \
        -svtav1-params "
            lp=${level_of_parallelism}:\
            enable-qm=1:\
            qm-min=4:\
            scd=1:\
            enable-overlays=1:\
            tune=0:\
            film-grain=5:\
            film-grain-denoise=1:\
            enable-variance-boost=1:\
            variance-boost-strength=2:\
            variance-octile=6
        " \
        $@ \
        "$output" ||
        return $?

    # ffmpeg \
    #     $ffmpeg_common_options \
    #     -i "$input" \
    #     $ffmpeg_audio_inputs \
    #     -map 0 \
    #     -map -0:a \
    #     $ffmpeg_audio_maps \
    #     -map_metadata:g 0:g \
    #     -map_metadata:s:v 0:s:v \
    #     $ffmpeg_audio_metadata_maps \
    #     -metadata modification_date=now \
    #     -metadata:s:a encoder="$afconvert_encoder_info" \
    #     -c copy \
    #     -c:v libx265 \
    #     -tag:v hvc1 \
    #     -fps_mode vfr \
    #     -g $keyint \
    #     -crf 20 \
    #     -preset veryslow \
    #     -x265-params "\
    #             aq-motion=1:\
    #             bframes=16:\
    #             deblock=-1,-1:\
    #             frame-threads=1:\
    #             hevc-aq=1:\
    #             hme=1:\
    #             hme-search=3,3,3:\
    #             hme-range=24,48,58:\
    #             ipratio=1.25:\
    #             log-level=3:\
    #             me=3:\
    #             merange=58:\
    #             min-keyint=0:\
    #             pbratio=1.15:\
    #             pools=${threads}:\
    #             psy-rd=2.5:\
    #             psy-rdoq=5.0:\
    #             qcomp=0.75:\
    #             qpstep=2:\
    #             rc-lookahead=${keyint}:\
    #             ref=8:\
    #             rskip=2:\
    #             rskip-edge-threshold=1:\
    #             sao=0:\
    #             strong-intra-smoothing=0:\
    #             subme=4:\
    #             tu-intra-depth=4:\
    #             tu-inter-depth=4\
    #         " \
    #     $@ \
    #     "$output" ||
    #     return $?

    rm -f $audio_alac_outputs
}
