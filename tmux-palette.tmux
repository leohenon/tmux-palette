#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

default_key="P"
palette_key="$(tmux show-option -gqv '@palette_key')"
palette_key="${palette_key:-$default_key}"

tmux bind-key "$palette_key" display-popup \
  -E \
  -w 60% -h 60% \
  -b rounded \
  -S "fg=colour241" \
  -T " Command Palette " \
  "${CURRENT_DIR}/scripts/palette.sh"
