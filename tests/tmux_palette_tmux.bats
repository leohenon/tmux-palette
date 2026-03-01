#!/usr/bin/env bats

load test_helper

setup() {
  setup_common
}

teardown() {
  teardown_common
}

@test "default key P is bound" {
  tmux() {
    echo "$*" >> "$TMUX_CALLS_FILE"
    case "$1" in
      show-option) echo "" ;;
      bind-key) return 0 ;;
      *) return 0 ;;
    esac
  }
  export -f tmux

  source "$PROJECT_ROOT/tmux-palette.tmux"

  grep -q "bind-key P display-popup" "$TMUX_CALLS_FILE"
}

@test "custom key via @tmux_palette_key is respected" {
  tmux() {
    echo "$*" >> "$TMUX_CALLS_FILE"
    case "$1" in
      show-option) echo "F1" ;;
      bind-key) return 0 ;;
      *) return 0 ;;
    esac
  }
  export -f tmux

  source "$PROJECT_ROOT/tmux-palette.tmux"

  grep -q "bind-key F1 display-popup" "$TMUX_CALLS_FILE"
}

@test "binding includes display-popup with correct flags" {
  tmux() {
    echo "$*" >> "$TMUX_CALLS_FILE"
    case "$1" in
      show-option) echo "" ;;
      *) return 0 ;;
    esac
  }
  export -f tmux

  source "$PROJECT_ROOT/tmux-palette.tmux"

  local bind_call
  bind_call="$(grep "bind-key" "$TMUX_CALLS_FILE")"
  [[ "$bind_call" == *"display-popup"* ]]
  [[ "$bind_call" == *"-E"* ]]
  [[ "$bind_call" == *"-w 60%"* ]]
  [[ "$bind_call" == *"-h 60%"* ]]
  [[ "$bind_call" == *"-b rounded"* ]]
  [[ "$bind_call" == *"-T  Command Palette "* ]]
  [[ "$bind_call" == *"palette.sh"* ]]
}
