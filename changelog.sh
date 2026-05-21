#!/usr/bin/env bash
#
# changelog.sh — Generate a structured CHANGELOG.md from git history
#
# Usage:
#   bash changelog.sh              # writes CHANGELOG.md
#   bash changelog.sh --stdout     # prints to stdout instead
#
# Requirements: git, bash 4+
# License: MIT

set -euo pipefail

OUTPUT_FILE="CHANGELOG.md"
STDOUT_MODE=false

for arg in "$@"; do
  case "$arg" in
    --stdout) STDOUT_MODE=true; OUTPUT_FILE="" ;;
    --help|-h)
      echo "Usage: bash changelog.sh [--stdout]"
      echo "  (no args)   Write CHANGELOG.md to current directory"
      echo "  --stdout    Print changelog to stdout"
      exit 0 ;;
  esac
done

# ----- helpers -----------------------------------------------------------

# Determine the range of commits to process
# Uses the latest semver tag, or falls back to the first commit.
get_commit_range() {
  local tag
  tag=$(git describe --tags --abbrev=0 2>/dev/null || true)
  if [[ -n "$tag" ]]; then
    echo "${tag}..HEAD"
  else
    # No tags — include every commit
    git rev-list --max-parents=0 HEAD 2>/dev/null || echo "HEAD"
  fi
}

# Categorise a commit message into a section heading.
categorise() {
  local msg="$1"
  # Conventional Commits patterns
  if [[ "$msg" =~ ^feat([^a-zA-Z]|$) ]]; then  echo "Added"; return 0; fi
  if [[ "$msg" =~ ^feature([^a-zA-Z]|$) ]]; then echo "Added"; return 0; fi
  if [[ "$msg" =~ ^add([^a-zA-Z]|$) ]]; then    echo "Added"; return 0; fi
  if [[ "$msg" =~ ^fix([^a-zA-Z]|$) ]]; then     echo "Fixed"; return 0; fi
  if [[ "$msg" =~ ^bug([^a-zA-Z]|$) ]]; then     echo "Fixed"; return 0; fi
  if [[ "$msg" =~ ^patch([^a-zA-Z]|$) ]]; then   echo "Fixed"; return 0; fi
  if [[ "$msg" =~ ^refactor([^a-zA-Z]|$) ]]; then echo "Changed"; return 0; fi
  if [[ "$msg" =~ ^perf([^a-zA-Z]|$) ]]; then    echo "Changed"; return 0; fi
  if [[ "$msg" =~ ^update([^a-zA-Z]|$) ]]; then  echo "Changed"; return 0; fi
  if [[ "$msg" =~ ^change([^a-zA-Z]|$) ]]; then  echo "Changed"; return 0; fi
  if [[ "$msg" =~ ^improve([^a-zA-Z]|$) ]]; then echo "Changed"; return 0; fi
  if [[ "$msg" =~ ^remove([^a-zA-Z]|$) ]]; then  echo "Removed"; return 0; fi
  if [[ "$msg" =~ ^deprecat([^a-zA-Z]|$) ]]; then echo "Removed"; return 0; fi
  if [[ "$msg" =~ ^delete([^a-zA-Z]|$) ]]; then  echo "Removed"; return 0; fi
  if [[ "$msg" =~ ^drop([^a-zA-Z]|$) ]]; then    echo "Removed"; return 0; fi
  if [[ "$msg" =~ ^docs([^a-zA-Z]|$) ]]; then    echo "Documentation"; return 0; fi
  if [[ "$msg" =~ ^style([^a-zA-Z]|$) ]]; then   echo "Styling"; return 0; fi
  if [[ "$msg" =~ ^test([^a-zA-Z]|$) ]]; then    echo "Testing"; return 0; fi
  if [[ "$msg" =~ ^ci([^a-zA-Z]|$) ]]; then      echo "CI/CD"; return 0; fi
  if [[ "$msg" =~ ^chore([^a-zA-Z]|$) ]]; then   echo "Maintenance"; return 0; fi
  # Generic fallback
  echo "Changed"
}

# Strip conventional commit prefix and scope, keep the human-readable part.
strip_prefix() {
  local msg="$1"
  # Remove type(scope)!: or type(scope): or type!: or type:
  msg=$(echo "$msg" | sed -E 's/^[a-zA-Z_-]+(\([^)]*\))?!?:[[:space:]]*//')
  # Capitalise first letter
  msg="$(tr '[:lower:]' '[:upper:]' <<< "${msg:0:1}")${msg:1}"
  echo "$msg"
}

# ----- collect commits ---------------------------------------------------

RANGE=$(get_commit_range)

declare -A SECTIONS
SECTIONS["Added"]=""
SECTIONS["Fixed"]=""
SECTIONS["Changed"]=""
SECTIONS["Removed"]=""

# Also allow extra categories
declare -A EXTRA
EXTRA["Documentation"]=""
EXTRA["Styling"]=""
EXTRA["Testing"]=""
EXTRA["CI/CD"]=""
EXTRA["Maintenance"]=""

ORDER=("Added" "Fixed" "Changed" "Removed" "Documentation" "Styling" "Testing" "CI/CD" "Maintenance")

# Determine version / date
VERSION=""
if git describe --tags --abbrev=0 2>/dev/null; then
  VERSION=$(git describe --tags --abbrev=0 2>/dev/null || true)
fi
DATE=$(date +%Y-%m-%d)

# Build prefix line
HEADER_LINE="## ${VERSION:-Unreleased} (${DATE})"

# Process each commit
while IFS= read -r line; do
  # Merge commits often start with "Merge" — skip them
  [[ "$line" =~ ^Merge ]] && continue
  [[ "$line" =~ ^[[:space:]]*$ ]] && continue

  # Extract the first line (subject)
  subject="${line%%$'\n'*}"

  section=$(categorise "$subject")
  clean=$(strip_prefix "$subject")

  if [[ -n "${SECTIONS[$section]+x}" ]]; then
    SECTIONS["$section"]+="  - ${clean}"$'\n'
  else
    # Put it in Changed if unknown
    SECTIONS["Changed"]+="  - ${clean}"$'\n'
  fi
done < <(git log --oneline --no-merges "$RANGE" 2>/dev/null || echo "")

# ----- render output -----------------------------------------------------

render() {
  local header="$1"

  cat <<EOF
# Changelog

All notable changes to this project will be documented in this file.

${header}

EOF

  for section in "${ORDER[@]}"; do
    local content=""
    if [[ -n "${SECTIONS[$section]+x}" ]]; then
      content="${SECTIONS[$section]}"
    fi
    if [[ -z "$content" && -n "${EXTRA[$section]+x}" ]]; then
      content="${EXTRA[$section]}"
    fi
    if [[ -n "$content" ]]; then
      echo "### ${section}"
      echo ""
      echo -n "$content"
      echo ""
    fi
  done
}

OUTPUT=$(render "$HEADER_LINE")

if [[ "$STDOUT_MODE" == true ]]; then
  echo "$OUTPUT"
else
  echo "$OUTPUT" > "$OUTPUT_FILE"
  echo "✔ CHANGELOG.md written (${#OUTPUT} bytes)"
fi
