#!/bin/bash
# Claude Code status line.
# Shows, in order:  context% | model | provider | quota (5h / 7d, subscription only)
#
# Data sources:
#   context%  -> stdin JSON  .context_window.used_percentage
#   model     -> stdin JSON  .model.display_name
#   provider  -> environment (CLAUDE_CODE_USE_VERTEX / _USE_BEDROCK / ANTHROPIC_BASE_URL)
#   quota     -> stdin JSON  .rate_limits.{five_hour,seven_day}.used_percentage
#                (present only for Claude.ai subscription plans; absent for Vertex/Bedrock)

input=$(cat)

RESET=$'\033[0m'
DIM=$'\033[2m'
CYAN=$'\033[36m'
MAGENTA=$'\033[35m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'

# Color a 0-100 percentage: green <70, yellow 70-89, red 90+.
pct_color() {
  local p=$1
  if [ "$p" -ge 90 ]; then printf '%s' "$RED"
  elif [ "$p" -ge 70 ]; then printf '%s' "$YELLOW"
  else printf '%s' "$GREEN"; fi
}

# Truthy env check: non-empty and not "0"/"false". (macOS bash 3.2: no ${x,,})
is_on() {
  local v
  v=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  case "$v" in
    ""|0|false|no|off) return 1 ;;
    *) return 0 ;;
  esac
}

# 1) context usage
CTX=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
[ -z "$CTX" ] && CTX=0
CTX_SEG="$(pct_color "$CTX")ctx ${CTX}%${RESET}"

# 2) model
MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
MODEL_SEG="${CYAN}${MODEL}${RESET}"

# 2b) generation speed of the last API call that started with a thinking block, from the transcript:
#     output tokens / (its last "assistant" entry time - its first token time).
#     First token time = first thinking entry time - its thinkingDurationMs, so time to first token is left out.
#     A call without thinking gives no first token time; it is skipped and the previous speed stays.
# "api-request" entries and thinkingDurationMs are undocumented; when they are missing the segment is just left out.
SPEED_SEG=""
TRANSCRIPT=$(echo "$input" | jq -r '.transcript_path // empty')
if [ -f "$TRANSCRIPT" ]; then
  # ponytail: only the last 100 lines are read; a call with more entries than that shows no speed.
  RATE=$(tail -n 100 "$TRANSCRIPT" | jq -Rrn '
    def ts: .timestamp | (sub("\\.[0-9]+Z$"; "Z") | fromdate) + (try (capture("(?<f>\\.[0-9]+)Z$").f | tonumber) catch 0);
    reduce (inputs | fromjson? | select(.type == "api-request" or (.type == "assistant" and .message.model != "<synthetic>"))) as $e ({};
      if $e.type == "api-request" then .req = ($e | ts) | .t0 = null | .first = true
      elif .req and ($e | ts) > .req then  # entries can land out of order; one older than the request is skipped
        (if .first and $e.message.content[0].type == "thinking" and $e.thinkingDurationMs
         then .t0 = ($e | ts) - $e.thinkingDurationMs / 1000 else . end)
        | .first = false
        | if .t0 then .start = .t0 | .end = ($e | ts) | .out = ($e.message.usage.output_tokens // 0) else . end
      else . end)
    | if .out > 0 and .end > .start then .out / (.end - .start) | floor else empty end')
  [ -n "$RATE" ] && SPEED_SEG="${DIM}${RATE} tok/s${RESET}"
fi

# 3) provider
if is_on "$CLAUDE_CODE_USE_VERTEX"; then
  PROVIDER="Vertex AI"
elif is_on "$CLAUDE_CODE_USE_BEDROCK"; then
  PROVIDER="Bedrock"
elif [ -n "$ANTHROPIC_BASE_URL" ]; then
  PROVIDER="Custom API"
else
  PROVIDER="Claude Plan"
fi
PROVIDER_SEG="${MAGENTA}${PROVIDER}${RESET}"

# 4) quota — only when the subscription rate_limits block is present
FIVE_H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' | cut -d. -f1)
WEEK=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' | cut -d. -f1)
QUOTA_SEG=""
QUOTA_PARTS=""
if [ -n "$FIVE_H" ]; then
  QUOTA_PARTS="$(pct_color "$FIVE_H")5h ${FIVE_H}%${RESET}"
fi
if [ -n "$WEEK" ]; then
  [ -n "$QUOTA_PARTS" ] && QUOTA_PARTS="${QUOTA_PARTS}${DIM} · ${RESET}"
  QUOTA_PARTS="${QUOTA_PARTS}$(pct_color "$WEEK")7d ${WEEK}%${RESET}"
fi
[ -n "$QUOTA_PARTS" ] && QUOTA_SEG="$QUOTA_PARTS"

# 5) current path — home collapsed to ~
CWD=$(echo "$input" | jq -r '.workspace.current_dir // "."')
DIR_DISPLAY="$CWD"
case "$CWD" in
  "$HOME"/*) DIR_DISPLAY="~${CWD#$HOME}" ;;
  "$HOME") DIR_DISPLAY="~" ;;
esac
DIR_SEG="${DIR_DISPLAY}"

# 6) git branch — green if clean, yellow if there are uncommitted changes
GIT_SEG=""
if git -C "$CWD" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  BRANCH=$(git -C "$CWD" --no-optional-locks branch --show-current 2>/dev/null)
  if [ -n "$BRANCH" ]; then
    BRANCH_COLOR="$GREEN"
    git -C "$CWD" --no-optional-locks diff --quiet 2>/dev/null || BRANCH_COLOR="$YELLOW"
    GIT_SEG="${BRANCH_COLOR}${BRANCH}${RESET}"
  fi
fi

SEP="${DIM} | ${RESET}"
OUT="${CTX_SEG}${SEP}${MODEL_SEG}"
[ -n "$SPEED_SEG" ] && OUT="${OUT}${SEP}${SPEED_SEG}"
OUT="${OUT}${SEP}${PROVIDER_SEG}"
[ -n "$QUOTA_SEG" ] && OUT="${OUT}${SEP}${QUOTA_SEG}"
OUT="${OUT}${SEP}${DIR_SEG}"
[ -n "$GIT_SEG" ] && OUT="${OUT}${SEP}${GIT_SEG}"

printf '%b' "$OUT"
