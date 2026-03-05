#!/bin/bash
# Claude Code가 stdin으로 보내는 JSON 데이터 읽기
input=$(cat)

# jq를 사용하여 필드 추출
MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
# "// 0"은 필드가 null인 경우 폴백을 제공합니다
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

# 상태 표시줄 출력 - ${DIR##*/}는 폴더 이름만 추출합니다
echo "[$MODEL] 📁 ${DIR##*/} | ${PCT}% context"
