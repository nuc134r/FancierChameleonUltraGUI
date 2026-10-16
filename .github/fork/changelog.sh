#!/usr/bin/env bash
# Prints the FORK_CHANGELOG.md section for a version (without its heading), for release notes.
# Usage: .github/fork/changelog.sh 1.0.0   — prints nothing if the version has no section.
set -euo pipefail
awk -v v="$1" '
  /^## / { on = ($2 == v); next }
  on
' "$(dirname "$0")/../../FORK_CHANGELOG.md" | sed -e '/./,$!d' | sed -e ':a' -e '/^\n*$/{$d;N;ba' -e '}'
