#!/usr/bin/env bats

load test_helper

setup() {
  setup_common
  source_palette
}

teardown() {
  teardown_common
}

@test "empty history shows catalogue in default order" {
  local output
  output="$(build_list)"
  local first_line
  first_line="$(echo "$output" | head -1)"
  [[ "$first_line" == *"Split pane horizontally"* ]]
}

@test "catalogue entries all appear with empty history" {
  local output count
  output="$(build_list)"
  count="$(echo "$output" | wc -l | tr -d ' ')"
  [[ "$count" -eq "${#COMMANDS[@]}" ]]
}

@test "history entries appear before catalogue" {
  printf 'Kill current pane\tkill-pane\n' > "$HISTORY_FILE"
  local output first_line
  output="$(build_list)"
  first_line="$(echo "$output" | head -1)"
  [[ "$first_line" == *"Kill current pane"* ]]
}

@test "most recent history entry is first" {
  printf 'New window\tnew-window\n' > "$HISTORY_FILE"
  printf 'Kill current pane\tkill-pane\n' >> "$HISTORY_FILE"
  local output first_line
  output="$(build_list)"
  first_line="$(echo "$output" | head -1)"
  [[ "$first_line" == *"Kill current pane"* ]]
}

@test "duplicate history entries are deduped (only most recent kept)" {
  printf 'New window\tnew-window\n' > "$HISTORY_FILE"
  printf 'Kill current pane\tkill-pane\n' >> "$HISTORY_FILE"
  printf 'New window\tnew-window\n' >> "$HISTORY_FILE"
  local output
  output="$(build_list)"
  local new_window_count
  new_window_count="$(echo "$output" | grep -c 'new-window')"
  [[ "$new_window_count" -eq 1 ]]
  local first_line
  first_line="$(echo "$output" | head -1)"
  [[ "$first_line" == *"New window"* ]]
}

@test "history entries matching catalogue commands are not repeated" {
  printf 'New window\tnew-window\n' > "$HISTORY_FILE"
  local output
  output="$(build_list)"
  local new_window_count
  new_window_count="$(echo "$output" | grep -c 'new-window')"
  [[ "$new_window_count" -eq 1 ]]
}

@test "stale history entries (commands not in catalogue) still appear at top" {
  printf 'My custom\tsome-custom-command\n' > "$HISTORY_FILE"
  local output first_line
  output="$(build_list)"
  first_line="$(echo "$output" | head -1)"
  [[ "$first_line" == *"My custom"* ]]
  [[ "$first_line" == *"some-custom-command"* ]]
}

@test "MAX_HISTORY limit is respected in build_list" {
  MAX_HISTORY=3
  for i in $(seq 1 10); do
    printf 'cmd%d\tcmd-%d\n' "$i" "$i" >> "$HISTORY_FILE"
  done
  local output
  output="$(build_list)"
  local first_line
  first_line="$(echo "$output" | head -1)"
  [[ "$first_line" == *"cmd10"* ]]
  local top_3
  top_3="$(echo "$output" | head -3)"
  [[ "$top_3" != *"cmd1	"* ]]
}
