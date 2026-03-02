#!/usr/bin/env bats

load test_helper

setup() {
  setup_common
  source_palette
}

teardown() {
  teardown_common
}

@test "empty selection exits with 0" {
  run bash -c '
    source "'"$PROJECT_ROOT"'/tests/test_helper.bash"
    setup_common
    source_palette
    fzf() { echo ""; return 1; }
    export -f fzf
    source <(sed -n "201,238p" "'"$PROJECT_ROOT"'/scripts/palette.sh")
  '
  [[ "$status" -eq 0 ]]
}

@test "selection records to history and runs command" {
  run bash -c '
    source "'"$PROJECT_ROOT"'/tests/test_helper.bash"
    setup_common
    source_palette
    COUNTER="'"$TEST_TMPDIR"'/fzf_counter"
    echo 0 > "$COUNTER"
    fzf() {
      local n=$(($(cat "$COUNTER") + 1))
      echo $n > "$COUNTER"
      if [[ $n -eq 1 ]]; then
        printf "New window\tnew-window\n"
        return 0
      fi
      echo ""
      return 1
    }
    export -f fzf
    HISTORY_FILE="'"$TEST_TMPDIR"'/palette_history"
    source <(sed -n "201,238p" "'"$PROJECT_ROOT"'/scripts/palette.sh")
  '
  [[ "$status" -eq 0 ]]
  grep -q "New window" "$TEST_TMPDIR/palette_history"
}

@test "non-@ command breaks the loop after one execution" {
  run bash -c '
    source "'"$PROJECT_ROOT"'/tests/test_helper.bash"
    setup_common
    source_palette
    COUNTER="'"$TEST_TMPDIR"'/fzf_counter"
    echo 0 > "$COUNTER"
    fzf() {
      local n=$(($(cat "$COUNTER") + 1))
      echo $n > "$COUNTER"
      if [[ $n -eq 1 ]]; then
        printf "New window\tnew-window\n"
        return 0
      fi
      printf "SHOULD NOT REACH\tsecond-call\n"
      return 0
    }
    export -f fzf
    HISTORY_FILE="'"$TEST_TMPDIR"'/palette_history"
    source <(sed -n "201,238p" "'"$PROJECT_ROOT"'/scripts/palette.sh")
  '
  [[ "$status" -eq 0 ]]
  ! grep -q "SHOULD NOT REACH" "$TEST_TMPDIR/palette_history"
}

@test "@ command with success breaks the loop" {
  run bash -c '
    source "'"$PROJECT_ROOT"'/tests/test_helper.bash"
    setup_common
    source_palette
    pick_session() { return 0; }
    COUNTER="'"$TEST_TMPDIR"'/fzf_counter"
    echo 0 > "$COUNTER"
    fzf() {
      local n=$(($(cat "$COUNTER") + 1))
      echo $n > "$COUNTER"
      if [[ $n -eq 1 ]]; then
        printf "Switch to session\t@pick_session\n"
        return 0
      fi
      echo ""
      return 1
    }
    export -f fzf
    HISTORY_FILE="'"$TEST_TMPDIR"'/palette_history"
    source <(sed -n "201,238p" "'"$PROJECT_ROOT"'/scripts/palette.sh")
  '
  [[ "$status" -eq 0 ]]
}

@test "@ command with failure loops again (ESC_BEHAVIOR=back)" {
  run bash -c '
    source "'"$PROJECT_ROOT"'/tests/test_helper.bash"
    setup_common
    source_palette
    ESC_BEHAVIOR="back"
    pick_session() { return 1; }
    COUNTER="'"$TEST_TMPDIR"'/fzf_counter"
    echo 0 > "$COUNTER"
    fzf() {
      local n=$(($(cat "$COUNTER") + 1))
      echo $n > "$COUNTER"
      if [[ $n -le 2 ]]; then
        printf "Switch to session\t@pick_session\n"
        return 0
      fi
      echo ""
      return 1
    }
    export -f fzf
    HISTORY_FILE="'"$TEST_TMPDIR"'/palette_history"
    source <(sed -n "201,238p" "'"$PROJECT_ROOT"'/scripts/palette.sh")
  '
  [[ "$status" -eq 0 ]]
  local count
  count="$(grep -c "@pick_session" "$TEST_TMPDIR/palette_history")"
  [[ "$count" -eq 2 ]]
}

@test "@ command with failure breaks when ESC_BEHAVIOR=close" {
  run bash -c '
    source "'"$PROJECT_ROOT"'/tests/test_helper.bash"
    setup_common
    source_palette
    ESC_BEHAVIOR="close"
    pick_session() { return 1; }
    COUNTER="'"$TEST_TMPDIR"'/fzf_counter"
    echo 0 > "$COUNTER"
    fzf() {
      local n=$(($(cat "$COUNTER") + 1))
      echo $n > "$COUNTER"
      if [[ $n -eq 1 ]]; then
        printf "Switch to session\t@pick_session\n"
        return 0
      fi
      printf "SHOULD NOT REACH\tsecond\n"
      return 0
    }
    export -f fzf
    HISTORY_FILE="'"$TEST_TMPDIR"'/palette_history"
    source <(sed -n "201,238p" "'"$PROJECT_ROOT"'/scripts/palette.sh")
  '
  [[ "$status" -eq 0 ]]
  local count
  count="$(grep -c "@pick_session" "$TEST_TMPDIR/palette_history")"
  [[ "$count" -eq 1 ]]
}

@test "source-file command breaks with config reloaded message" {
  run bash -c '
    source "'"$PROJECT_ROOT"'/tests/test_helper.bash"
    setup_common
    source_palette
    sleep() { :; }
    COUNTER="'"$TEST_TMPDIR"'/fzf_counter"
    echo 0 > "$COUNTER"
    fzf() {
      local n=$(($(cat "$COUNTER") + 1))
      echo $n > "$COUNTER"
      if [[ $n -eq 1 ]]; then
        printf "Reload tmux config\tsource-file /tmp/tmux.conf\n"
        return 0
      fi
      echo ""
      return 1
    }
    export -f fzf
    HISTORY_FILE="'"$TEST_TMPDIR"'/palette_history"
    source <(sed -n "201,238p" "'"$PROJECT_ROOT"'/scripts/palette.sh")
  '
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Config reloaded"* ]]
}
