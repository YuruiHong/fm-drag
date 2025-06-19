[English](README.md) | 中文

# fm-drag

一个针对系统默认文件管理器（Caja、Nautilus、Dolphin、Thunar 等）的轻量级包装脚本：  
- 传入文件夹时，正常打开目录；  
- 传入文件时，自动创建临时文件夹并建立软链，只显示这些文件，打开后可精准拖拽，且关闭窗口后自动清理。

## 功能

- 对目录参数 → 直接调用默认文件管理器打开。  
- 对文件参数 → 在 `$XDG_RUNTIME_DIR`（或 `/tmp`）下建目录并软链，打开后仅显示指定文件，避免其他干扰；关闭后自动清理。  
- 自动识别系统默认文件管理器（`xdg-mime query default inode/directory`），并在 `/usr/local/bin` 下创建同名软链，无需手动多次链接。

## 安装

```bash
curl -sSL https://github.com/<YOUR-USER>/fm-drag/raw/main/install.sh | sudo bash
````

安装完成后，你可以直接使用原命令（如 `caja`、`nautilus`、`dolphin` 等）来打开目录或文件。

## 使用示例

```bash
# 正常打开文件夹
nautilus ~/Downloads

# 仅打开指定文件所在的临时目录（用于精准拖拽）
nautilus ~/Documents/resume.pdf ~/Pictures/photo.png
```

## 许可

MIT © Yurui Hong

