#!/usr/bin/env bats

load test_helper

setup() {
  setup_common
  source_palette
}

teardown() {
  teardown_common
}

@test "@ prefixed commands call the function name" {
  my_test_func() {
    echo "function called" > "${TEST_TMPDIR}/func_called"
    return 0
  }

  run_command "@my_test_func"
  [[ -f "${TEST_TMPDIR}/func_called" ]]
  [[ "$(cat "${TEST_TMPDIR}/func_called")" == "function called" ]]
}

@test "non-@ commands run via eval tmux" {
  run_command "new-window"
  [[ -f "$TMUX_CALLS_FILE" ]]
  grep -q "new-window" "$TMUX_CALLS_FILE"
}

@test "non-@ commands pass flags correctly" {
  run_command "split-window -h"
  grep -q "split-window -h" "$TMUX_CALLS_FILE"
}

@test "source-file commands return result code" {
  run_command "source-file /tmp/tmux.conf"
  local result=$?
  [[ $result -eq 0 ]]
}

@test "@ command propagates function return code" {
  failing_func() {
    return 1
  }

  run run_command "@failing_func"
  [[ "$status" -eq 1 ]]
}

@test "@ command strips @ prefix before calling" {
  pick_session() {
    echo "pick_session called" > "${TEST_TMPDIR}/pick_called"
    return 0
  }

  run_command "@pick_session"
  [[ -f "${TEST_TMPDIR}/pick_called" ]]
}
