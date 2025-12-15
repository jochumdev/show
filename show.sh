#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2025-present jochumdev <rene@jochum.dev>
#
# SPDX-License-Identifier: MIT OR Apache-2.0
#
# This file is based on: https://github.com/junegunn/fzf/blob/33d8d51c8a6c6e9321b5295b3a63f548b5f18a1f/bin/fzf-preview.sh
set -euo pipefail

if [[ $# -lt 1 ]]; then
  printf "usage: %s <ENV_FILE> [(DIR|FILE<:LINENO><:IGNORED>)]" "$0" >&2
  exit 1
fi

# Argument parsing
env_file=""
dir_or_file=""
if [[ $# -gt 1 ]]; then
  env_file="$1"
  dir_or_file="$2"
else
  dir_or_file="$1"
fi

# Env handling
if [[ -r ${env_file} ]]; then
  # shellcheck source=/dev/null
  source "${env_file}"
fi

BAT_STYLE="${BAT_STYLE:-numbers}"
PREVIEW_SEPERATOR="${PREVIEW_SEPERATOR:-";"}"
PREVIEW_FILES="${PREVIEW_FILES:-"readme.*;*.md;*.rst"}"
PREVIEW_TOP="${PREVIEW_TOP:-"0"}"
PREVIEW_COLUMNS="${PREVIEW_COLUMNS:-""}"
PREVIEW_LINES="${PREVIEW_LINES:-""}"

# TODO(jochumdev): ghostty is a guess
supported_kitten_terms=("kitty" "alacritty" "ghostty")

find_file() {
  local find="$1"
  local dir="$2"
  local sep="$3"
  local files="$4"

  local -a preview_files
  local oifs="$IFS"
  IFS="${sep}"
  read -ra preview_files <<< "${files}"
  IFS="${oifs}"

  for p in "${preview_files[@]}"; do
    match=$("$find" "$dir" -maxdepth 1 -iname "${p}" -print -quit)
    if [[ -n ${match} ]]; then
      printf "%s" "${match}"
      return 0
    fi
  done
}

get_command() {
  command -v "$1" || return 0
}

get_command_exit() {
  local cmd="$1"
  local file="$2"

  local command
  command=$(get_command "$cmd")

  if [[ -z ${command} ]]; then
    file "$file"
    exit 0
  fi

  printf "%s" "$command"
}

show_dir() {
  local dir="$1"

  local cmd_eza
  cmd_eza=$(get_command "eza")
  if [[ -n ${cmd_eza} ]]; then
    eza --tree "$dir"
    exit 0
  fi

  ls -1A "$1"
}

preview_file() {
  local file="$1"

  local center=0
  if [[ ! -r ${file} ]]; then
    if [[ ${file} =~ ^(.+):([0-9]+)\ *$ ]] && [[ -r ${BASH_REMATCH[1]} ]]; then
      file=${BASH_REMATCH[1]}
      center=${BASH_REMATCH[2]}
    elif [[ ${file} =~ ^(.+):([0-9]+):[0-9]+\ *$ ]] && [[ -r ${BASH_REMATCH[1]} ]]; then
      file=${BASH_REMATCH[1]}
      center=${BASH_REMATCH[2]}
    fi
  fi

  type=$(file --brief --dereference --mime -- "$file")
  if [[ ${type} =~ image/ ]]; then
    local term=${TERM:-"unknown"}

    local cmd_sed
    cmd_sed="$(get_command_exit "sed" "$file")"

    local cmd_stty
    cmd_stty="$(get_command_exit "stty" "$file")"
    local cmd_awk
    cmd_awk="$(get_command_exit "awk" "$file")"

    local dim=${PREVIEW_COLUMNS}x${PREVIEW_LINES}
    if [[ ${dim} == x ]]; then
      dim=$(${cmd_stty} size </dev/tty | ${cmd_awk} '{print $2 "x" $1}')
    fi

    # 1. Use icat (from Kitty) if kitten is installed
    local cmd_kitten
    cmd_kitten=$(get_command "kitten")
    if [[ -n ${cmd_sed} ]] && [[ -n ${cmd_kitten} ]] && [[ ":${supported_kitten_terms[*]}:" =~ :$term: ]]; then
      # 1. 'memory' is the fastest option but if you want the image to be scrollable,
      #    you have to use 'stream'.
      #
      # 2. The last line of the output is the ANSI reset code without newline.
      #    This confuses fzf and makes it render scroll offset indicator.
      #    So we remove the last line and append the reset code to its previous line.
      ${cmd_kitten} icat --clear --transfer-mode=memory --unicode-placeholder --stdin=no --place="$dim@0x0" "$file" | ${cmd_sed} '$d' | ${cmd_sed} $'$s/$/\e[m/'
      return 0
    fi

    # 2. Use chafa with Sixel output
    local cmd_chafa
    cmd_chafa=$(get_command "chafa")
    if [[ -n ${cmd_chafa} ]]; then
      if (( PREVIEW_TOP + PREVIEW_LINES == $(${cmd_stty} size </dev/tty | ${cmd_awk} '{print $1}') )); then
        # Avoid scrolling issue when the Sixel image touches the bottom of the screen
        # * https://github.com/junegunn/fzf/issues/2544
        dim=${PREVIEW_COLUMNS}x$(( PREVIEW_LINES - 1 ))
      fi

      ${cmd_chafa} -s "$dim" "$file"
      return 0
    fi

    # 3. Use imgcat
    local cmd_imgcat
    cmd_imgcat=$(get_command "imgcat")
    if [[ -n ${cmd_imgcat} ]]; then
      # NOTE: We should use https://iterm2.com/utilities/it2check to check if the
      # user is running iTerm2. But for the sake of simplicity, we just assume
      # that's the case here.
      ${cmd_imgcat} -W "${dim%%x*}" -H "${dim##*x}" "$file"
      return 0
    fi

    # 4. No image preview program display file info
    file "$file"
    return 0
  fi

  if [[ ${type} =~ =binary ]]; then
    file "$file"
    return 0
  fi

  local cmd_bat
  cmd_bat="$(get_command "bat")"
  if [[ -z ${cmd_bat} ]]; then
    # Sometimes bat is installed as batcat.
    cmd_bat="$(get_command "batcat")"
  fi

  if [[ -n ${cmd_bat} ]]; then
    ${cmd_bat} --style="${BAT_STYLE}" --color=always --pager=never --highlight-line="${center}" -- "${file}"
    return 0
  fi

  if [[ ${type} =~ text/ ]]; then
    local cmd_sed
    cmd_sed=$(get_command_exit "sed" "$file")
    ${cmd_sed} -n "1,200p" "$file"
    return 0
  fi

  file "$file"
  return 0
}

file="${dir_or_file}"
if [ -d "${file}" ]; then
  cmd_find="$(get_command "find")"
  if [[ -z ${cmd_find} ]]; then
    show_dir "$file"
    exit $?
  fi

  file=$(find_file "${cmd_find}" "${dir_or_file}" "${PREVIEW_SEPERATOR}" "$PREVIEW_FILES")
fi

if [[ -n ${file} ]]; then
  preview_file "${file}"
  exit $?
fi

show_dir "${dir_or_file}"
