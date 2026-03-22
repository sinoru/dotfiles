#!/bin/bash
input=$(cat)

IFS=$'\x1f' read -r dir branch model pct win cost in_tok out_tok added removed <<< "$(echo "$input" | jq -r '
  def fmt_tokens:
    if . >= 1000000 then "\(. / 1000000 * 10 | floor / 10)M"
    elif . >= 1000 then "\(. / 1000 * 10 | floor / 10)k"
    else "\(.)"
    end;

  def fmt_window:
    if . >= 1000000 then "\(. / 1000000 | floor)M"
    else "\(. / 1000 | floor)k"
    end;

  [
    (.workspace.current_dir // "~"),
    (.worktree.branch // ""),
    (.model.display_name // "unknown"),
    ((.context_window.used_percentage // 0) | floor | tostring),
    ((.context_window.context_window_size // 200000) | fmt_window),
    (.cost.total_cost_usd // 0 | tostring),
    ((.context_window.total_input_tokens // 0) | fmt_tokens),
    ((.context_window.total_output_tokens // 0) | fmt_tokens),
    (.cost.total_lines_added // 0 | tostring),
    (.cost.total_lines_removed // 0 | tostring)
  ] | join("\u001f")
')"

RST='\033[0m'
DIM='\033[2m'
RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[0;33m'
CYN='\033[1;36m'
MAG='\033[1;35m'
GRY='\033[0;37m'
BLU='\033[0;34m'

# Context percentage color
if (( pct >= 90 )); then pct_color="$RED"
elif (( pct >= 70 )); then pct_color="$YLW"
else pct_color="$GRN"
fi

# Line 1: directory [| branch]
if [[ -z "$branch" ]]; then
  branch=$(git -C "$dir" branch --show-current 2>/dev/null)
fi
line1="${CYN}📂 ${dir}${RST}"
if [[ -n "$branch" ]]; then
  line1+=" ${DIM}|${RST} ${GRN}🌿 ${branch}${RST}"
fi

# Line 2: model | context% (window) | cost
cost_fmt=$(printf '%.2f' "$cost")
line2="🤖 ${model}"
line2+=" ${DIM}|${RST} ${pct_color}📊 ${pct}%${RST} ${DIM}(${win})${RST}"
line2+=" ${DIM}|${RST} ${YLW}💰 \$${cost_fmt}${RST}"

# Line 3: tokens | line changes
line3="🔤 ${RED}↑${in_tok}${RST} ${BLU}↓${out_tok}${RST}"
line3+=" ${DIM}|${RST} ✏️  ${GRN}+${added}${RST} ${RED}-${removed}${RST}"

echo -e "${line1}"
echo -e "${line2}"
echo -e "${line3}"
