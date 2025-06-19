#!/usr/bin/env bash
set -euo pipefail

DEST_BIN=/usr/local/bin
SCRIPT_NAME=fm-drag
SCRIPT_URL="https://github.com/YuruiHong/fm-drag/raw/main/fm-drag.sh"

echo "Installing $SCRIPT_NAME to $DEST_BIN/$SCRIPT_NAME…"
curl -sSL "$SCRIPT_URL" -o "$DEST_BIN/$SCRIPT_NAME"
chmod +x "$DEST_BIN/$SCRIPT_NAME"

# 1) Try to detect default FM from mime
desktop=$(xdg-mime query default inode/directory 2>/dev/null || true)
fm_exec=""
if [[ -n "$desktop" ]]; then
  # strip .desktop
  fm_key=${desktop%.desktop}
  # common bin names often match key…
  if command -v "$fm_key" &>/dev/null; then
    fm_exec="$fm_key"
  fi
fi

# 2) Fallback list of common FMs
if [[ -z "$fm_exec" ]]; then
  for name in caja nautilus dolphin thunar pcmanfm; do
    if command -v "$name" &>/dev/null; then
      fm_exec="$name"
      break
    fi
  done
fi

# 3) If found, link; else show manual instructions
if [[ -n "$fm_exec" ]]; then
  echo "Creating symlink: $DEST_BIN/$fm_exec → $SCRIPT_NAME"
  ln -sf "$DEST_BIN/$SCRIPT_NAME" "$DEST_BIN/$fm_exec"
  echo "Done! Now you can restart shell and run '$fm_exec [flags] [paths]' as usual."
else
  cat << 'EOF'
Could not auto-detect your file manager. 

Please manually link:
  sudo ln -sf /usr/local/bin/fm-drag /usr/local/bin/<your-fm>

e.g.:
  sudo ln -sf /usr/local/bin/fm-drag /usr/local/bin/caja
EOF
fi

