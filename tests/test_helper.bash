#!/usr/bin/env bash

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

setup_common() {
  TEST_TMPDIR="$(mktemp -d)"
  export HISTORY_FILE="${TEST_TMPDIR}/palette_history"
  export HOME="$TEST_TMPDIR"
  mkdir -p "$(dirname "$HISTORY_FILE")"

  TMUX_CALLS_FILE="${TEST_TMPDIR}/tmux_calls"
  export TMUX_CALLS_FILE

  tmux() {
    echo "$*" >> "$TMUX_CALLS_FILE"
    case "$1" in
      display-message)
        case "$*" in
          *session_name*) echo "test-session" ;;
          *window_index*)  echo "1" ;;
          *config_files*)  echo "/tmp/tmux.conf" ;;
          *) ;;
        esac
        ;;
      list-sessions)
        printf 'test-session\nother-session\ndev\n'
        ;;
      list-windows)
        printf '0 main\n1 editor\n2 logs\n'
        ;;
      list-buffers)
        printf 'buffer0: 20 bytes: "hello"\nbuffer1: 10 bytes: "world"\n'
        ;;
      list-keys)
        printf 'bind-key -T prefix P display-popup\nbind-key -T prefix c new-window\n'
        ;;
      show-messages)
        printf '[0] message one\n[1] message two\n'
        ;;
      show-option)
        echo ""
        ;;
      has-session)
        return 1
        ;;
      source-file)
        return 0
        ;;
      *)
        return 0
        ;;
    esac
  }
  export -f tmux

  fzf() {
    echo ""
    return 1
  }
  export -f fzf

  find() {
    return 0
  }
  export -f find
}

teardown_common() {
  rm -rf "$TEST_TMPDIR"
}

source_palette() {
  export MAX_HISTORY=50
  export CUSTOM_COMMANDS_FILE="${HOME}/.tmux/palette_commands"
  export ESC_BEHAVIOR="back"

  local FZF_OPTS=(
    --layout=reverse
    --no-info
    --no-scrollbar
    --no-border
    --height=100%
  )
  export FZF_OPTS

  eval "$(sed -n '24,199p' "$PROJECT_ROOT/scripts/palette.sh")"
}

run_main_loop() {
  local script
  script="$(cat "$PROJECT_ROOT/scripts/palette.sh")"
  script="${script/#if ! command -v fzf/if false}"
  eval "$script"
}
