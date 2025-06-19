#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# fm-drag.sh: wrapper for your default file manager that
# 1) Opens real directories normally;
# 2) For file arguments, creates a temp dir with symlinks, opens it,
#    waits for that window to close, then cleans up.
# It auto-detects your FM's real Exec command (and default flags) from its
# .desktop file, so flags like --no-desktop are preserved.
# -----------------------------------------------------------------------------

# 1. Locate the system default file manager's .desktop file
desktop_file=$(xdg-mime query default inode/directory)

# 2. Search for that .desktop in standard locations
desktop_path=""
for d in \
    "${XDG_DATA_HOME:-$HOME/.local/share}/applications" \
    /usr/local/share/applications \
    /usr/share/applications; do
  if [[ -f "$d/$desktop_file" ]]; then
    desktop_path="$d/$desktop_file"
    break
  fi
done
# fallback
desktop_path="${desktop_path:-/usr/share/applications/$desktop_file}"

# 3. Parse its Exec= line, strip out %U/%u/%F/%f, split into command + default flags
exec_line=$(grep -E '^Exec=' "$desktop_path" | head -n1 | sed 's/^Exec=//')
exec_clean=$(echo "$exec_line" | sed -E 's/ *%[uUFf]//g')
ORIG_FM=$(echo "$exec_clean" | awk '{print $1}')
read -r -a default_flags <<< "$(echo "$exec_clean" | cut -d' ' -f2-)"

# 4. Prepare base temp dir
BASE_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"

# 5. Initialize arrays
fm_flags=()
dirs=()
files=()

# 6. Parse args: collect flags (leading -), stop at "--", then paths
end_of_flags=0
for arg in "$@"; do
  if (( end_of_flags )); then
    if [[ -d "$arg" ]]; then
      dirs+=("$arg")
    elif [[ -e "$arg" ]]; then
      files+=("$arg")
    else
      echo "Warning: '$arg' not found, skipping." >&2
    fi
  else
    case "$arg" in
      --) end_of_flags=1 ;;
      -*) fm_flags+=("$arg") ;;
      *)
        if [[ -d "$arg" ]]; then
          dirs+=("$arg")
        elif [[ -e "$arg" ]]; then
          files+=("$arg")
        else
          echo "Warning: '$arg' not found, skipping." >&2
        fi
      ;;
    esac
  fi
done

# 7. If no paths given, just invoke FM (opens home or as per flags)
if (( ${#dirs[@]} == 0 && ${#files[@]} == 0 )); then
  exec "$ORIG_FM" "${default_flags[@]}" "${fm_flags[@]}"
fi

# 8. Open each directory normally (in background)
for d in "${dirs[@]}"; do
  "$ORIG_FM" "${default_flags[@]}" "${fm_flags[@]}" "$d" &
done

# 9. If files provided, build temp dir + symlinks, open, wait, cleanup
if (( ${#files[@]} > 0 )); then
  tmpdir=$(mktemp -d "${BASE_RUNTIME_DIR}/drag-dir.XXXXXX")
  for f in "${files[@]}"; do
    ln -s "$(readlink -f "$f")" "$tmpdir/$(basename "$f")"
  done

  # Open tempdir
  "$ORIG_FM" "${default_flags[@]}" "${fm_flags[@]}" "$tmpdir" &

  # Wait for the FM window titled exactly by tmpdir basename
  base=$(basename "$tmpdir")
  wid=""
  until wid=$(xdotool search --name "^${base}$" 2>/dev/null | head -n1) && [[ -n "$wid" ]]; do
    sleep 0.5
  done

  # Then wait until it closes
  while xdotool search --name "^${base}$" >/dev/null 2>&1; do
    sleep 0.5
  done

  # Cleanup
  rm -rf "$tmpdir"
fi

