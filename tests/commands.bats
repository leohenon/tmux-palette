#!/usr/bin/env bats

load test_helper

setup() {
  setup_common
  source_palette
}

teardown() {
  teardown_common
}

@test "every entry has a label and a command (tab-separated)" {
  for entry in "${COMMANDS[@]}"; do
    local label="${entry%%	*}"
    local cmd="${entry#*	}"
    [[ -n "$label" ]]
    [[ -n "$cmd" ]]
    [[ "$label" != "$entry" ]]
  done
}

@test "no duplicate labels" {
  declare -A labels
  for entry in "${COMMANDS[@]}"; do
    local label="${entry%%	*}"
    if [[ -n "${labels[$label]}" ]]; then
      echo "Duplicate label found: $label" >&2
      return 1
    fi
    labels[$label]=1
  done
}

@test "no empty labels or commands" {
  for entry in "${COMMANDS[@]}"; do
    local label="${entry%%	*}"
    local cmd="${entry#*	}"
    if [[ -z "$label" ]]; then
      echo "Empty label found in entry: $entry" >&2
      return 1
    fi
    if [[ -z "$cmd" ]]; then
      echo "Empty command found for label: $label" >&2
      return 1
    fi
  done
}

@test "no duplicate commands" {
  declare -A cmds
  for entry in "${COMMANDS[@]}"; do
    local cmd="${entry#*	}"
    if [[ -n "${cmds[$cmd]}" ]]; then
      echo "Duplicate command found: $cmd" >&2
      return 1
    fi
    cmds[$cmd]=1
  done
}

@test "all @ commands reference existing functions" {
  for entry in "${COMMANDS[@]}"; do
    local cmd="${entry#*	}"
    if [[ "$cmd" == @* ]]; then
      local func_name="${cmd#@}"
      if ! declare -f "$func_name" > /dev/null 2>&1; then
        echo "Function not found: $func_name (from command: $cmd)" >&2
        return 1
      fi
    fi
  done
}

@test "COMMANDS array is not empty" {
  [[ "${#COMMANDS[@]}" -gt 0 ]]
}

@test "COMMANDS array has expected minimum entries" {
  [[ "${#COMMANDS[@]}" -ge 30 ]]
}
