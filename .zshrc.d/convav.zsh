local argzero="${(%):-%N}"
local basename=$argzero:t:r

convav() {
    local tmpdir=$(mktemp -d -t "${basename}")

    if [[ $(sysctl -n hw.perflevel0.name) == 'Performance' ]]; then
        local core_count=$(sysctl -n hw.perflevel0.logicalcpu)
    else
        local core_count=$(sysctl -n hw.physicalcpu)
    fi

    if   (( $core_count <= 1 )); then # PARALLEL_LEVEL_1_RANGE
        local level_of_parallelism=1
    elif (( $core_count <= 2 )); then # PARALLEL_LEVEL_2_RANGE
        local level_of_parallelism=2
    elif (( $core_count <= 6 )); then # PARALLEL_LEVEL_3_RANGE
        local level_of_parallelism=3
    elif (( $core_count <= 12 )); then # PARALLEL_LEVEL_4_RANGE
        local level_of_parallelism=4
    elif (( $core_count <= 24 )); then # PARALLEL_LEVEL_5_RANGE
        local level_of_parallelism=5
    else
        local level_of_parallelism=6
    fi

    local afconvert_encoder_info="afconvert $(afconvert 2>&1 | sed -n 's/.*Version: \([0-9.]\)/\1/p')"

    local ffmpeg_common_options=(
        -hide_banner
        -loglevel repeat+verbose
        -stats
    )

    local input=$1
    local output=$2

    shift 2

    local frame_rate=$(ffprobe \
        -v error \
        -select_streams V \
        -of default=noprint_wrappers=1:nokey=1 \
        -show_entries stream=avg_frame_rate \
        "$input")

    local keyint=$(($(printf "%.0f" $(echo "scale=3;$frame_rate" | bc)) * 5))

    local audio_streams_count=$(
        ffprobe \
        -v error \
        -select_streams a \
        -show_entries stream=index \
        -of csv=p=0 \
        "$input" | wc -w
    )

    local audio_alac_outputs=()
    local ffmpeg_audio_inputs=()
    local ffmpeg_audio_maps=()
    local ffmpeg_audio_metadata_maps=()

    for i in {0..$((audio_streams_count - 1))}; do
        audio_alac_output="${tmpdir}/${output:t:r}.audio.$i.mp4"

        tmpdir="${tmpdir}" convav::convert_alac "$input" "$audio_alac_output" ||
            return $?

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

    rm -f $audio_alac_outputs
}

convav::convert_alac() {
    local input=$1
    local output=$2

    shift 2

    local audio_original_output="$(mktemp -u -p ${tmpdir} -t "${input:t:r}").caf"

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
        "$output" ||
        return $?

    rm -f "$audio_original_output"
}
