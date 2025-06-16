#!/usr/bin/env bash
set -euo pipefail

# Determine which FM we're wrapping
fm_cmd="$(basename "$0")"
ORIG_FM="$(command -v "${fm_cmd}.real" 2>/dev/null || command -v "$fm_cmd" 2>/dev/null || true)"
if [[ -z "$ORIG_FM" || "$ORIG_FM" == "$0" ]]; then
  ORIG_FM="/usr/bin/$fm_cmd"
fi

# Base for temporary dirs
BASE_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"

# --- 显式初始化数组，避免 unbound variable 错误 ---
fm_flags=()
dirs=()
files=()

# Parse arguments: flags (-*) vs paths; "--" as end-of-flags marker
end_of_flags=0
for arg in "$@"; do
  if (( end_of_flags )); then
    # 已遇 "--"，只当作路径处理
    if [[ -d "$arg" ]]; then
      dirs+=("$arg")
    elif [[ -e "$arg" ]]; then
      files+=("$arg")
    else
      echo "Warning: '$arg' not found, skipping." >&2
    fi
  else
    if [[ "$arg" == "--" ]]; then
      end_of_flags=1
    elif [[ "$arg" == -* ]]; then
      fm_flags+=("$arg")
    else
      if [[ -d "$arg" ]]; then
        dirs+=("$arg")
      elif [[ -e "$arg" ]]; then
        files+=("$arg")
      else
        echo "Warning: '$arg' not found, skipping." >&2
      fi
    fi
  fi
done

# If no paths at all → fallback to default behavior (open home or as --browser)
if (( ${#dirs[@]} == 0 && ${#files[@]} == 0 )); then
  exec "$ORIG_FM" "${fm_flags[@]}"
fi

# Open directories (non-blocking)
for d in "${dirs[@]}"; do
  "$ORIG_FM" "${fm_flags[@]}" "$d" &
done

# Handle files via temp folder + symlinks
if (( ${#files[@]} > 0 )); then
  tmpdir=$(mktemp -d "${BASE_RUNTIME_DIR}/drag-dir.XXXXXX")
  for f in "${files[@]}"; do
    ln -s "$(readlink -f "$f")" "$tmpdir/$(basename "$f")"
  done

  # Launch FM on tempdir
  "$ORIG_FM" "${fm_flags[@]}" "$tmpdir" &

  # Wait for window with title exactly matching basename(tmpdir)
  base=$(basename "$tmpdir")
  wid=""
  until wid=$(xdotool search --name "^${base}$" 2>/dev/null | head -n1) && [[ -n "$wid" ]]; do
    sleep 0.5
  done
  # Then wait until that window closes
  while xdotool search --name "^${base}$" >/dev/null 2>&1; do
    sleep 0.5
  done

  # Cleanup
  rm -rf "$tmpdir"
fi

