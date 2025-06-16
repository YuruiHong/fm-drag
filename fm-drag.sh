#!/usr/bin/env bash
# Wrapper for caja: open dirs normally; collect files into a temp dir with symlinks, open,
# then detect the specific caja window by folder basename and wait for it to close before cleanup

# Determine file manager command based on how this script was invoked
fm_cmd="$(basename "$0")"
# Locate the real FM binary: look for a .real or in /usr/bin
ORIG_FM="$(command -v "$fm_cmd.real" 2>/dev/null || command -v "$fm_cmd" 2>/dev/null)"
# If the real binary is this script itself, assume system binary in /usr/bin
if [[ "$ORIG_FM" == "$0" ]] || [[ -z "$ORIG_FM" ]]; then
  ORIG_FM="/usr/bin/$fm_cmd"
fi

# Fallback runtime dir
BASE_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"

BASE_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"

# Collect directories and files from args
declare -a dirs files
for arg in "$@"; do
  if [[ -d "$arg" ]]; then
    dirs+=("$arg")
  elif [[ -e "$arg" ]]; then
    files+=("$arg")
  else
    echo "Warning: '$arg' not found, skipping." >&2
  fi
done

# Open each directory normally (non-blocking)
for d in "${dirs[@]}"; do
  "$ORIG_FM" "$d" &
done

# Handle files: symlink into temp dir and open
if (( ${#files[@]} > 0 )); then
  tmpdir=$(mktemp -d "${BASE_RUNTIME_DIR}/drag-dir.XXXXXX")
  for f in "${files[@]}"; do
    ln -s "$(readlink -f "$f")" "$tmpdir/$(basename "$f")"
  done

  # Launch caja on the temp dir
  "$ORIG_FM" "$tmpdir" &

  # Identify window by basename and wait for it to appear
  base=$(basename "$tmpdir")
  wid=""
  until wid=$(xdotool search --name "$base" 2>/dev/null | head -n1) && [[ -n "$wid" ]]; do
    sleep 0.5
  done

  # Now wait until that window no longer exists
  while xdotool search --name "$base" >/dev/null 2>&1; do
    sleep 0.5
  done

  # Cleanup symlinks and temp dir
  rm -rf "$tmpdir"
fi

