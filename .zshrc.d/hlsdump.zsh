hlsdump() {
    if [[ -z "$1" ]]; then
        echo "Usage: hlsdump <HLS_URL> [output.ts]"
        return 1
    fi

    local url="$1"
    local output="${2:-output_$(date +%Y%m%d_%H%M%S).ts}"

    local programs_json
    programs_json=$(ffprobe -extension_picky 0 -v quiet -show_entries \
        program=program_id:program_tags=variant_bitrate \
        -show_entries program_stream=width,height,r_frame_rate \
        -select_streams v -of json -i "$url" 2>/dev/null)

    local programs_list
    programs_list=$(echo "$programs_json" | jq -r '.programs[] | 
        (.tags.variant_bitrate // "0") as $bitrate |
        (.streams[0] // {}) as $s |
        (($s.r_frame_rate // "0/1") | split("/") | (.[0] | tonumber) / (.[1] | tonumber)) as $fps |
        [
            .program_id,
            ($bitrate | tonumber),
            ($s.width // 0),
            ($s.height // 0),
            $fps
        ] | @sh' | \
        sort -t' ' -k2,2nr -k4,4nr -k3,3nr -k5,5nr)

    if [[ -z "$programs_list" ]]; then
        echo "No program found. Downloading with default stream."
        ffmpeg -extension_picky 0 -hide_banner -loglevel error -stats \
            -i "$url" -c copy "$output"
        return
    fi

    echo "Available programs:"
    printf "  %-4s  %-12s  %-12s  %s\n" "ID" "Bitrate" "Resolution" "FPS"
    echo "$programs_list" | while read -r id bitrate width height fps; do
        printf "  %-4s  %-12s  %-12s  %.2f\n" "$id" "$((bitrate / 1000)) kbps" "${width}x${height}" "$fps"
    done
    echo ""

    local best_program best_bitrate best_width best_height best_fps
    read -r best_program best_bitrate best_width best_height best_fps <<< "$(echo "$programs_list" | head -1)"

    echo "Selected: program $best_program (${best_width}x${best_height} @ ${best_fps}fps, $((best_bitrate / 1000)) kbps)"
    ffmpeg -extension_picky 0 -hide_banner -loglevel error -stats \
        -i "$url" \
        -map "0:p:${best_program}" \
        -c copy \
        "$output"
}