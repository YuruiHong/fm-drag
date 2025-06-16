English | [中文](README_zh.md)

# fm-drag

A small wrapper for your default file manager (Caja, Nautilus, Dolphin, Thunar, etc.) that lets you drag-and-drop only specified files (via a temporary folder with symlinks), while still opening real folders normally.

## Features

- Opens real directories in your default file manager unchanged.  
- For file arguments, creates a temporary folder, symlinks only those files into it, opens that folder—so you can drag-and-drop just those items without other clutter.  
- Auto-detects your system’s default file manager (`xdg-mime query default inode/directory`) and installs itself under that name.

## Installation

```bash
# Download script and make it executable
sudo curl -sSL https://github.com/YuruiHong/fm-drag/raw/main/fm-drag.sh \
          -o /usr/local/bin/fm-drag && sudo chmod +x /usr/local/bin/fm-drag

# Create a single symlink under your default FM name
fm=$(xdg-mime query default inode/directory | sed 's/\.desktop$//')
sudo ln -sf /usr/local/bin/fm-drag /usr/local/bin/"$fm"
````

You can now call e.g. `caja`, `nautilus`, `dolphin`, … with both folders and files as arguments.

## Usage

```bash
# Open real folder normally
caja ~/Documents

# Open only specific files in a temp folder for clean drag-and-drop
caja ~/Pictures/photo1.jpg ~/Documents/report.pdf
```

Behind the scenes, `fm-drag` will:

1. Detect which args are directories → open them directly.
2. For files → make a temp folder in `$XDG_RUNTIME_DIR` (fallback `/tmp`), symlink each file, open that folder.
3. Wait for its window to close, then clean up the temp folder automatically.

## License

MIT © Yurui Hong

