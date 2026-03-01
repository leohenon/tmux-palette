#!/usr/bin/env bats

load test_helper

setup() {
  setup_common
  source_palette
}

teardown() {
  teardown_common
}

@test "pick_kill_session excludes current session" {
  local fzf_input="${TEST_TMPDIR}/fzf_input"

  tmux() {
    echo "$*" >> "$TMUX_CALLS_FILE"
    case "$1" in
      display-message) echo "test-session" ;;
      list-sessions) printf 'test-session\nother-session\ndev\n' ;;
      *) return 0 ;;
    esac
  }
  export -f tmux

  fzf() {
    cat > "$fzf_input"
    echo ""
    return 1
  }
  export -f fzf

  run pick_kill_session
  [[ "$status" -eq 1 ]]
  [[ "$(cat "$fzf_input")" != *"test-session"* ]]
}

@test "pick_kill_session returns 1 on empty fzf selection" {
  fzf() { echo ""; return 1; }
  export -f fzf

  run pick_kill_session
  [[ "$status" -eq 1 ]]
}

@test "pick_kill_session calls kill-session on selection" {
  fzf() { echo "other-session"; return 0; }
  export -f fzf

  pick_kill_session
  grep -q "kill-session -t other-session" "$TMUX_CALLS_FILE"
}

@test "pick_swap_window excludes current window" {
  local fzf_input="${TEST_TMPDIR}/fzf_input"

  tmux() {
    echo "$*" >> "$TMUX_CALLS_FILE"
    case "$1" in
      display-message) echo "1" ;;
      list-windows) printf '0 main\n1 editor\n2 logs\n' ;;
      *) return 0 ;;
    esac
  }
  export -f tmux

  fzf() {
    cat > "$fzf_input"
    echo ""
    return 1
  }
  export -f fzf

  run pick_swap_window
  [[ "$status" -eq 1 ]]
  [[ "$(cat "$fzf_input")" != *"1 editor"* ]]
}

@test "pick_swap_window returns 1 on empty selection" {
  fzf() { echo ""; return 1; }
  export -f fzf

  run pick_swap_window
  [[ "$status" -eq 1 ]]
}

@test "pick_swap_window calls swap-window on selection" {
  fzf() { echo "2 logs"; return 0; }
  export -f fzf

  pick_swap_window
  grep -q "swap-window -t 2" "$TMUX_CALLS_FILE"
}

@test "pick_new_session returns 1 on empty fzf selection" {
  fzf() { echo ""; return 1; }
  export -f fzf

  run pick_new_session
  [[ "$status" -eq 1 ]]
}

@test "pick_new_session creates session with sanitized name (dots)" {
  local test_dir="${TEST_TMPDIR}/my.project"
  mkdir -p "$test_dir"

  fzf() { echo "${test_dir}"; return 0; }
  export -f fzf

  pick_new_session
  grep -q "new-session -ds my_project -c" "$TMUX_CALLS_FILE"
}

@test "pick_new_session creates session with sanitized name (spaces)" {
  local test_dir="${TEST_TMPDIR}/my project"
  mkdir -p "$test_dir"

  fzf() { echo "${test_dir}"; return 0; }
  export -f fzf

  pick_new_session
  grep -q "new-session -ds my_project -c" "$TMUX_CALLS_FILE"
}

@test "pick_new_session sanitizes dots and spaces together" {
  local test_dir="${TEST_TMPDIR}/my.cool project"
  mkdir -p "$test_dir"

  fzf() { echo "${test_dir}"; return 0; }
  export -f fzf

  pick_new_session
  grep -q "new-session -ds my_cool_project -c" "$TMUX_CALLS_FILE"
}

@test "pick_new_session handles duplicate session names with suffix" {
  local test_dir="${TEST_TMPDIR}/myproject"
  mkdir -p "$test_dir"

  local call_count=0
  tmux() {
    echo "$*" >> "$TMUX_CALLS_FILE"
    case "$1" in
      has-session)
        call_count=$((call_count + 1))
        if [[ $call_count -le 1 ]]; then
          return 0
        else
          return 1
        fi
        ;;
      *) return 0 ;;
    esac
  }
  export -f tmux

  fzf() { echo "${test_dir}"; return 0; }
  export -f fzf

  pick_new_session
  grep -q "new-session -ds myproject_2" "$TMUX_CALLS_FILE"
}

@test "pick_new_session switches client to new session" {
  local test_dir="${TEST_TMPDIR}/myproject"
  mkdir -p "$test_dir"

  fzf() { echo "${test_dir}"; return 0; }
  export -f fzf

  pick_new_session
  grep -q "switch-client -t myproject" "$TMUX_CALLS_FILE"
}

@test "pick_session returns 1 on empty fzf selection" {
  fzf() { echo ""; return 1; }
  export -f fzf

  run pick_session
  [[ "$status" -eq 1 ]]
}

@test "pick_session switches client on selection" {
  fzf() { echo "dev"; return 0; }
  export -f fzf

  pick_session
  grep -q "switch-client -t dev" "$TMUX_CALLS_FILE"
}

@test "pick_window returns non-zero on empty fzf selection" {
  fzf() { echo ""; return 1; }
  export -f fzf

  run pick_window
  [[ "$status" -ne 0 ]]
}

@test "pick_window selects window and switches client" {
  fzf() { echo "dev:2 logs"; return 0; }
  export -f fzf

  pick_window
  grep -q "select-window -t dev:2" "$TMUX_CALLS_FILE"
  grep -q "switch-client -t dev" "$TMUX_CALLS_FILE"
}

@test "pick_move_pane returns 1 on empty selection" {
  fzf() { echo ""; return 1; }
  export -f fzf

  run pick_move_pane
  [[ "$status" -eq 1 ]]
}

@test "pick_move_pane calls join-pane on selection" {
  fzf() { echo "dev:0 main"; return 0; }
  export -f fzf

  pick_move_pane
  grep -q "join-pane -t dev:0" "$TMUX_CALLS_FILE"
}

@test "pick_buffer pipes list-buffers to fzf" {
  local fzf_input="${TEST_TMPDIR}/fzf_input"
  fzf() {
    cat > "$fzf_input"
    echo ""
    return 1
  }
  export -f fzf

  pick_buffer || true
  [[ "$(cat "$fzf_input")" == *"buffer0"* ]]
}

@test "pick_keys pipes list-keys to fzf" {
  local fzf_input="${TEST_TMPDIR}/fzf_input"
  fzf() {
    cat > "$fzf_input"
    echo ""
    return 1
  }
  export -f fzf

  pick_keys || true
  [[ "$(cat "$fzf_input")" == *"bind-key"* ]]
}

@test "pick_messages pipes show-messages to fzf" {
  local fzf_input="${TEST_TMPDIR}/fzf_input"
  fzf() {
    cat > "$fzf_input"
    echo ""
    return 1
  }
  export -f fzf

  pick_messages || true
  [[ "$(cat "$fzf_input")" == *"message one"* ]]
}
