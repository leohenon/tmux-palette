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

@test "custom commands appear after catalogue" {
  mkdir -p "$(dirname "$CUSTOM_COMMANDS_FILE")"
  printf 'My custom cmd\trun-custom\n' > "$CUSTOM_COMMANDS_FILE"
  local output
  output="$(build_list)"
  local catalogue_line custom_line
  catalogue_line="$(echo "$output" | grep -n 'split-window -h' | head -1 | cut -d: -f1)"
  custom_line="$(echo "$output" | grep -n 'run-custom' | head -1 | cut -d: -f1)"
  [[ "$catalogue_line" -lt "$custom_line" ]]
}

@test "custom commands are deduped against history" {
  printf 'My custom cmd\trun-custom\n' > "$HISTORY_FILE"
  mkdir -p "$(dirname "$CUSTOM_COMMANDS_FILE")"
  printf 'My custom cmd\trun-custom\n' > "$CUSTOM_COMMANDS_FILE"
  local output count
  output="$(build_list)"
  count="$(echo "$output" | grep -c 'run-custom')"
  [[ "$count" -eq 1 ]]
}

@test "empty custom commands file is handled gracefully" {
  mkdir -p "$(dirname "$CUSTOM_COMMANDS_FILE")"
  : > "$CUSTOM_COMMANDS_FILE"
  local output count
  output="$(build_list)"
  count="$(echo "$output" | wc -l | tr -d ' ')"
  [[ "$count" -eq "${#COMMANDS[@]}" ]]
}

@test "missing custom commands file is handled gracefully" {
  rm -f "$CUSTOM_COMMANDS_FILE"
  local output count
  output="$(build_list)"
  count="$(echo "$output" | wc -l | tr -d ' ')"
  [[ "$count" -eq "${#COMMANDS[@]}" ]]
}

@test "custom file without trailing newline still reads last line" {
  mkdir -p "$(dirname "$CUSTOM_COMMANDS_FILE")"
  printf 'My custom cmd\trun-custom' > "$CUSTOM_COMMANDS_FILE"
  local output
  output="$(build_list)"
  echo "$output" | grep -q 'run-custom'
}

@test "comment lines in custom file are skipped" {
  mkdir -p "$(dirname "$CUSTOM_COMMANDS_FILE")"
  printf '# a comment\tignored\nReal cmd\trun-real\n' > "$CUSTOM_COMMANDS_FILE"
  local output
  output="$(build_list)"
  echo "$output" | grep -q 'run-real'
  ! echo "$output" | grep -q 'ignored'
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
