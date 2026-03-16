#!/bin/bash
# Read JSON data sent by Claude Code via stdin
input=$(cat)

# Extract fields using jq
MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
# "// 0" provides a fallback when the field is null
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

# Output status line - ${DIR##*/} extracts only the folder name
echo "[$MODEL] 📁 ${DIR##*/} | ${PCT}% context"
