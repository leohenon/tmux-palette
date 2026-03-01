#!/usr/bin/env bats

load test_helper

setup() {
  setup_common
  source_palette
}

teardown() {
  teardown_common
}

@test "command appended to history file after selection" {
  printf 'New window\tnew-window\n' >> "$HISTORY_FILE"
  [[ -f "$HISTORY_FILE" ]]
  local content
  content="$(cat "$HISTORY_FILE")"
  [[ "$content" == *"New window"*"new-window"* ]]
}

@test "history file created if it doesn't exist" {
  rm -f "$HISTORY_FILE"
  mkdir -p "$(dirname "$HISTORY_FILE")"
  printf 'test\ttest-cmd\n' >> "$HISTORY_FILE"
  [[ -f "$HISTORY_FILE" ]]
}

@test "history trimmed when exceeding MAX_HISTORY * 2" {
  MAX_HISTORY=5
  for i in $(seq 1 11); do
    printf 'cmd%d\tcmd-%d\n' "$i" "$i" >> "$HISTORY_FILE"
  done

  local tail_count
  tail_count="$(wc -l < "$HISTORY_FILE")"
  if (( tail_count > MAX_HISTORY * 2 )); then
    tail -n "$MAX_HISTORY" "$HISTORY_FILE" > "${HISTORY_FILE}.tmp"
    mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
  fi

  local line_count
  line_count="$(wc -l < "$HISTORY_FILE" | tr -d ' ')"
  [[ "$line_count" -eq 5 ]]
}

@test "trimmed history keeps most recent entries" {
  MAX_HISTORY=3
  for i in $(seq 1 8); do
    printf 'cmd%d\tcmd-%d\n' "$i" "$i" >> "$HISTORY_FILE"
  done

  local tail_count
  tail_count="$(wc -l < "$HISTORY_FILE")"
  if (( tail_count > MAX_HISTORY * 2 )); then
    tail -n "$MAX_HISTORY" "$HISTORY_FILE" > "${HISTORY_FILE}.tmp"
    mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
  fi

  local first_line last_line
  first_line="$(head -1 "$HISTORY_FILE")"
  last_line="$(tail -1 "$HISTORY_FILE")"
  [[ "$first_line" == *"cmd6"* ]]
  [[ "$last_line" == *"cmd8"* ]]
}

@test "label and command stored tab-separated" {
  printf 'My Label\tmy-command --flag\n' >> "$HISTORY_FILE"
  local label cmd
  IFS=$'\t' read -r label cmd < "$HISTORY_FILE"
  [[ "$label" == "My Label" ]]
  [[ "$cmd" == "my-command --flag" ]]
}

@test "history not trimmed when within limit" {
  MAX_HISTORY=50
  for i in $(seq 1 10); do
    printf 'cmd%d\tcmd-%d\n' "$i" "$i" >> "$HISTORY_FILE"
  done

  local tail_count
  tail_count="$(wc -l < "$HISTORY_FILE")"
  (( tail_count <= MAX_HISTORY * 2 ))

  local line_count
  line_count="$(wc -l < "$HISTORY_FILE" | tr -d ' ')"
  [[ "$line_count" -eq 10 ]]
}
