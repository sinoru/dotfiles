convav() {
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

    ffmpeg \
        -hide_banner \
        -loglevel repeat+verbose \
        -stats \
        -i "$input" \
        -map 0 \
        -map_metadata:g 0:g \
        -map_metadata:s:v 0:s:v \
        -map_metadata:s:a 0:s:a \
        -metadata modification_date=now \
        -fps_mode passthrough \
        -c:v libsvtav1 \
        -g $keyint \
        -preset 1 \
        -crf 21 \
        -svtav1-params "
            lp=${level_of_parallelism}:\
            enable-qm=1:\
            qm-min=4:\
            scd=1:\
            tile-rows=2:\
            tile-columns=2:\
            enable-overlays=1:\
            tune=0:\
            film-grain=5:\
            film-grain-denoise=1:\
            enable-variance-boost=1:\
            variance-boost-strength=2:\
            variance-octile=6
        " \
        -c:a flac \
        -compression_level 12 \
        -exact_rice_parameters 1 \
        -threads $core_count \
        $@ \
        "$output" ||
        return $?
}
