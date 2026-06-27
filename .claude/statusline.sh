#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
PROJ_DIR=$(echo "$input" | jq -r '.workspace.project_dir')

CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; RESET='\033[0m'

# Context bar
if [ -n "$PCT" ]; then
  PCT_INT=${PCT%.*}
  if [ "$PCT_INT" -ge 90 ]; then BAR_COLOR="$RED"
  elif [ "$PCT_INT" -ge 70 ]; then BAR_COLOR="$YELLOW"
  else BAR_COLOR="$GREEN"; fi

  FILLED=$((PCT_INT / 10)); EMPTY=$((10 - FILLED))
  printf -v FILL "%${FILLED}s"; printf -v PAD "%${EMPTY}s"
  BAR="${FILL// /█}${PAD// /░}"
  CTX_INFO=" ${BAR_COLOR}${BAR}${RESET} ${PCT_INT}%"
else
  CTX_INFO=""
fi

BRANCH=""
if [ -d "$PROJ_DIR" ]; then
  BRANCH=$(git -C "$PROJ_DIR" --no-optional-locks branch --show-current 2>/dev/null)
  [ -n "$BRANCH" ] && BRANCH=" | ${GREEN}${BRANCH}${RESET}"
fi

printf "${CYAN}[%s]${RESET} %s%s%s\n" "$MODEL" "${DIR##*/}" "$BRANCH" "$CTX_INFO"