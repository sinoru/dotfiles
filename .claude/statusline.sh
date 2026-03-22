#!/bin/bash

# === Color Constants ===
RST='\033[0m'
DIM='\033[2m'
RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[0;33m'
CYN='\033[1;36m'
BLU='\033[0;34m'

# === Helper Functions ===

# _util_color <pct> <warn_threshold> <crit_threshold>
_util_color() {
  [[ $# -lt 3 ]] && { echo "$GRN"; return; }
  local int_pct
  int_pct=$(printf '%.0f' "$1" 2>/dev/null) || int_pct=0
  if (( int_pct >= $3 )); then echo "$RED"
  elif (( int_pct >= $2 )); then echo "$YLW"
  else echo "$GRN"
  fi
}

# Get access token from credentials
_get_access_token() {
  local cred_json
  if [[ "$(uname)" == "Darwin" ]]; then
    cred_json=$(/usr/bin/security find-generic-password -s "Claude Code-credentials" -a "$USER" -w 2>/dev/null)
  else
    cred_json=$(cat ~/.claude/.credentials.json 2>/dev/null)
  fi
  [[ -z "$cred_json" ]] && return 1

  local expires_at
  expires_at=$(echo "$cred_json" | jq -r '.claudeAiOauth.expiresAt // 0')
  local now_ms=$(( $(date +%s) * 1000 ))
  (( expires_at > 0 && expires_at < now_ms )) && return 1

  echo "$cred_json" | jq -r '.claudeAiOauth.accessToken // empty'
}

# Get usage JSON (with file cache, TTL 300s via mtime)
_get_usage_json() {
  local cache="$HOME/.claude/usage.statusline.json"
  local token="$1"
  local now
  now=$(date +%s)

  if [[ -f "$cache" ]]; then
    local mtime
    if [[ "$(uname)" == "Darwin" ]]; then
      mtime=$(stat -f %m "$cache" 2>/dev/null)
    else
      mtime=$(stat -c %Y "$cache" 2>/dev/null)
    fi
    if (( now - mtime < 300 )); then
      cat "$cache"
      return 0
    fi
  fi

  local response
  response=$(curl -s --max-time 5 \
    -H "Authorization: Bearer ${token}" \
    -H "anthropic-beta: oauth-2025-04-20" \
    "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)

  if [[ -n "$response" ]] && echo "$response" | jq -e . >/dev/null 2>&1; then
    echo "$response" > "$cache"
    echo "$response"
  elif [[ -f "$cache" ]]; then
    cat "$cache"
  fi
}

# Format remaining time from ISO8601 reset timestamp
_fmt_remaining() {
  local resets_at="$1"
  [[ -z "$resets_at" || "$resets_at" == "null" ]] && return

  local reset_epoch
  if [[ "$(uname)" == "Darwin" ]]; then
    local normalized
    normalized=$(echo "$resets_at" | sed 's/\.[0-9]*//' | sed 's/+\([0-9][0-9]\):\([0-9][0-9]\)$/+\1\2/' | sed 's/-\([0-9][0-9]\):\([0-9][0-9]\)$/-\1\2/')
    reset_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "$normalized" "+%s" 2>/dev/null)
  else
    reset_epoch=$(date -d "$resets_at" +%s 2>/dev/null)
  fi
  [[ -z "$reset_epoch" ]] && return

  local diff=$(( reset_epoch - $(date +%s) ))
  (( diff <= 0 )) && echo "0m" && return

  local hours=$(( diff / 3600 ))
  local mins=$(( (diff % 3600) / 60 ))
  if (( hours >= 24 )); then
    local days=$(( hours / 24 ))
    local rem_h=$(( hours % 24 ))
    (( rem_h > 0 )) && echo "${days}d ${rem_h}h" || echo "${days}d"
  elif (( hours > 0 )); then
    (( mins > 0 )) && echo "${hours}h ${mins}m" || echo "${hours}h"
  else
    echo "${mins}m"
  fi
}

# _add_period <label> <jq_path> <usage_json>
_add_period() {
  local label="$1" jq_path="$2" usage_json="$3"
  local util resets_at
  util=$(echo "$usage_json" | jq -r "${jq_path}.utilization // empty")
  resets_at=$(echo "$usage_json" | jq -r "${jq_path}.resets_at // empty")
  [[ -z "$util" ]] && return
  local color remaining
  color=$(_util_color "$util" 80 95)
  remaining=$(_fmt_remaining "$resets_at")
  local int_util
  int_util=$(printf '%.0f' "$util")
  local seg="${label}: ${color}${int_util}%${RST}"
  [[ -n "$remaining" ]] && seg+=" ${DIM}(${remaining})${RST}"
  echo "$seg"
}

# Build Line 4
_build_usage_line() {
  local usage_json="$1"
  local parts=()
  local sep=" ${DIM}|${RST} "
  local seg

  seg=$(_add_period "5h"     ".five_hour"        "$usage_json"); [[ -n "$seg" ]] && parts+=("$seg")
  seg=$(_add_period "7d"     ".seven_day"        "$usage_json"); [[ -n "$seg" ]] && parts+=("$seg")
  seg=$(_add_period "Sonnet" ".seven_day_sonnet" "$usage_json"); [[ -n "$seg" ]] && parts+=("$seg")
  seg=$(_add_period "Opus"   ".seven_day_opus"   "$usage_json"); [[ -n "$seg" ]] && parts+=("$seg")

  local extra_enabled
  extra_enabled=$(echo "$usage_json" | jq -r '.extra_usage.is_enabled // false')
  if [[ "$extra_enabled" == "true" ]]; then
    local used limit util_pct
    used=$(echo "$usage_json" | jq -r '.extra_usage.used_credits // empty')
    limit=$(echo "$usage_json" | jq -r '.extra_usage.monthly_limit // empty')
    util_pct=$(echo "$usage_json" | jq -r '.extra_usage.utilization // empty')
    if [[ -n "$used" && -n "$limit" ]]; then
      local used_fmt limit_fmt
      used_fmt=$(printf '%.2f' "$(echo "$used / 100" | bc -l 2>/dev/null || echo 0)")
      limit_fmt=$(printf '%.2f' "$(echo "$limit / 100" | bc -l 2>/dev/null || echo 0)")
      local color=""
      [[ -n "$util_pct" ]] && color=$(_util_color "$util_pct" 80 95)
      local seg="${color}\$${used_fmt}/\$${limit_fmt}${RST}"
      [[ -n "$util_pct" ]] && seg+=" ${DIM}($(printf '%.0f' "$util_pct")%)${RST}"
      parts+=("$seg")
    fi
  fi

  [[ ${#parts[@]} -eq 0 ]] && return

  local line="⚡ "
  for i in "${!parts[@]}"; do
    (( i > 0 )) && line+="$sep"
    line+="${parts[$i]}"
  done
  echo "$line"
}

# === Data Fetching ===

IFS=$'\x1f' read -r dir branch model pct win cost in_tok out_tok added removed <<< "$(jq -r '
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

if [[ -z "$branch" ]]; then
  branch=$(git -C "$dir" branch --show-current 2>/dev/null)
fi

cost_fmt=$(printf '%.2f' "$cost")

token=$(_get_access_token)
usage_json=""
[[ -n "$token" ]] && usage_json=$(_get_usage_json "$token")

# === Rendering ===

pct_color=$(_util_color "$pct" 70 90)

line1="${CYN}📂 ${dir}${RST}"
[[ -n "$branch" ]] && line1+=" ${DIM}|${RST} ${GRN}🌿 ${branch}${RST}"

line2="🤖 ${model}"
line2+=" ${DIM}|${RST} ${pct_color}📊 ${pct}%${RST} ${DIM}(${win})${RST}"
line2+=" ${DIM}|${RST} ${YLW}💰 \$${cost_fmt}${RST}"

line3="🔤 ${RED}↑${in_tok}${RST} ${BLU}↓${out_tok}${RST}"
line3+=" ${DIM}|${RST} ✏️ ${GRN}+${added}${RST} ${RED}-${removed}${RST}"

echo -e "${line1}"
echo -e "${line2}"
echo -e "${line3}"

if [[ -n "$usage_json" ]]; then
  line4=$(_build_usage_line "$usage_json")
  [[ -n "$line4" ]] && echo -e "$line4"
fi
