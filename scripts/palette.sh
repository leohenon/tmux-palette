#!/usr/bin/env bash

if ! command -v fzf &>/dev/null; then
  tmux display-message "tmux-palette: fzf not found"
  exit 1
fi

HISTORY_FILE="${HOME}/.tmux/palette_history"
MAX_HISTORY=50
ESC_BEHAVIOR="$(tmux show-option -gqv '@palette_esc')"
ESC_BEHAVIOR="${ESC_BEHAVIOR:-back}"

FZF_OPTS=(
  --layout=reverse
  --no-info
  --no-scrollbar
  --no-border
  --height=100%
)

mkdir -p "$(dirname "$HISTORY_FILE")"

COMMANDS=(
  "Split pane horizontally	split-window -h"
  "Split pane vertically	split-window -v"
  "New window	new-window"
  "Kill current pane	kill-pane"
  "Kill current window	kill-window"
  "Kill current session	kill-session"
  "Kill another session	@pick_kill_session"
  "New session	@pick_new_session"
  "New directory	@create_dir"
  "Kill all other panes	kill-pane -a"
  "Next window	next-window"
  "Previous window	previous-window"
  "Next layout	next-layout"
  "Select pane: left	select-pane -L"
  "Select pane: right	select-pane -R"
  "Select pane: up	select-pane -U"
  "Select pane: down	select-pane -D"
  "Resize pane left	resize-pane -L 5"
  "Resize pane right	resize-pane -R 5"
  "Resize pane up	resize-pane -U 5"
  "Resize pane down	resize-pane -D 5"
  "Swap pane forward	swap-pane -D"
  "Swap pane backward	swap-pane -U"
  "Zoom/unzoom pane	resize-pane -Z"
  "Rename window	command-prompt -I '#W' 'rename-window \"%%\"'"
  "Rename session	command-prompt -I '#S' 'rename-session \"%%\"'"
  "Choose window (tree)	choose-tree -w"
  "Choose session (tree)	choose-tree -s"
  "Switch to session	@pick_session"
  "Switch to window	@pick_window"
  "Switch to previous session	switch-client -p"
  "Switch to next session	switch-client -n"
  "Move window left	swap-window -t -1"
  "Move window right	swap-window -t +1"
  "Swap window with	@pick_swap_window"
  "Last window	last-window"
  "Break pane to new window	break-pane"
  "Move pane to window	@pick_move_pane"
  "Rotate panes	rotate-window"
  "Last session	switch-client -l"
  "Paste buffer	paste-buffer"
  "List buffers	@pick_buffer"
  "Choose buffer	choose-buffer"
  "Clear pane history	clear-history"
  "Mark pane	select-pane -m"
  "Detach client	detach-client"
  "Reload tmux config	source-file $(tmux display-message -p '#{config_files}' | tr ',' '\n' | tail -1)"
  "Display pane numbers	display-panes"
  "Toggle synchronize panes	set-option synchronize-panes"
  "Enter copy mode	copy-mode"
  "List all key bindings	@pick_keys"
  "Show messages	@pick_messages"
  "Clock mode	clock-mode"
)

pick_swap_window() {
  local current sel
  current="$(tmux display-message -p '#{window_index}')"
  sel="$(tmux list-windows -F '#{window_index} #{window_name}' | grep -v "^${current} " | fzf "${FZF_OPTS[@]}" --prompt='swap with> ' | cut -d' ' -f1)"
  [[ -z "$sel" ]] && return 1
  tmux swap-window -t "$sel"
}

pick_move_pane() {
  local sel
  sel="$(tmux list-windows -a -F '#{session_name}:#{window_index} #{window_name}' | fzf "${FZF_OPTS[@]}" --prompt='move to> ')"
  [[ -z "$sel" ]] && return 1
  local target="${sel%% *}"
  tmux join-pane -t "$target"
}

pick_kill_session() {
  local current sel
  current="$(tmux display-message -p '#{session_name}')"
  sel="$(tmux list-sessions -F '#{session_name}' | grep -v "^${current}$" | fzf "${FZF_OPTS[@]}" --prompt='kill session> ')"
  [[ -z "$sel" ]] && return 1
  tmux kill-session -t "$sel"
}

create_dir() {
  local parent name
  parent="$({ echo "$HOME"; find "$HOME" -mindepth 1 -maxdepth 3 -type d 2>/dev/null | sort; } | fzf "${FZF_OPTS[@]}" --scheme=path --prompt='parent dir> ')"
  [[ -z "$parent" ]] && return 1
  printf '\033[2J\033[H'
  read -r -p "Directory name: " name
  [[ -z "$name" ]] && return 1
  mkdir -p "$parent/$name"
  tmux display-message "Created $parent/$name"
}

pick_new_session() {
  local selected base_name session_name suffix
  selected="$({ echo "$HOME"; find "$HOME" -mindepth 1 -maxdepth 3 -type d 2>/dev/null | sort; } | fzf "${FZF_OPTS[@]}" --scheme=path --prompt='dir> ')"
  [[ -z "$selected" ]] && return 1
  selected="$(cd "$selected" && pwd)"
  base_name="$(basename "$selected")"
  base_name="${base_name//./_}"
  base_name="${base_name// /_}"
  [[ -z "$base_name" ]] && base_name="main"
  session_name="$base_name"
  suffix=2
  while tmux has-session -t="$session_name" 2>/dev/null; do
    session_name="${base_name}_${suffix}"
    suffix=$((suffix + 1))
  done
  tmux new-session -ds "$session_name" -c "$selected"
  tmux switch-client -t "$session_name"
}

pick_session() {
  local sel
  sel="$(tmux list-sessions -F '#{session_name}' | fzf "${FZF_OPTS[@]}" --prompt='session> ')"
  [[ -n "$sel" ]] && tmux switch-client -t "$sel"
  [[ -n "$sel" ]]
}

pick_window() {
  local sel
  sel="$(tmux list-windows -a -F '#{session_name}:#{window_index} #{window_name}' | fzf "${FZF_OPTS[@]}" --prompt='window> ')"
  if [[ -n "$sel" ]]; then
    local target="${sel%% *}"
    tmux select-window -t "$target"
    tmux switch-client -t "${target%%:*}"
  fi
  [[ -n "$sel" ]]
}

pick_buffer() {
  tmux list-buffers | fzf "${FZF_OPTS[@]}" --prompt='buffer> '
}

pick_keys() {
  tmux list-keys | fzf "${FZF_OPTS[@]}" --prompt='key> '
}

pick_messages() {
  tmux show-messages | fzf "${FZF_OPTS[@]}" --prompt='msg> '
}

build_list() {
  declare -A seen

  if [[ -s "$HISTORY_FILE" ]]; then
    while IFS=$'\t' read -r label cmd; do
      if [[ -z "${seen[$cmd]}" ]]; then
        seen[$cmd]=1
        printf '%s\t%s\n' "$label" "$cmd"
      fi
    done < <(tail -n "$MAX_HISTORY" "$HISTORY_FILE" | awk '{a[NR]=$0} END{for(i=NR;i>=1;i--)print a[i]}')
  fi

  for entry in "${COMMANDS[@]}"; do
    label="${entry%%	*}"
    cmd="${entry#*	}"
    if [[ -z "${seen[$cmd]}" ]]; then
      seen[$cmd]=1
      printf '%s\t%s\n' "$label" "$cmd"
    fi
  done
}

run_command() {
  local cmd="$1"
  if [[ "$cmd" == @* ]]; then
    "${cmd#@}"
  else
    eval "tmux $cmd"
  fi
}

while true; do
  selection="$(
    build_list | fzf \
      "${FZF_OPTS[@]}" \
      --prompt="  " \
      --delimiter=$'\t' \
      --with-nth=1 \
      --bind='ctrl-d:half-page-down,ctrl-u:half-page-up'
  )"

  [[ -z "$selection" ]] && exit 0

  label="$(echo "$selection" | cut -f1)"
  cmd="$(echo "$selection" | cut -f2)"

  printf '%s\t%s\n' "$label" "$cmd" >> "$HISTORY_FILE"

  tail_count="$(wc -l < "$HISTORY_FILE")"
  if (( tail_count > MAX_HISTORY * 2 )); then
    tail -n "$MAX_HISTORY" "$HISTORY_FILE" > "${HISTORY_FILE}.tmp"
    mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
  fi

  run_command "$cmd"
  result=$?

  if [[ "$cmd" != @* ]] || [[ $result -eq 0 ]]; then
    break
  fi

  [[ "$ESC_BEHAVIOR" == "close" ]] && break
done
