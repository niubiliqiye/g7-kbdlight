#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="$HOME/.local/share/kbdlight"
DESKTOP_DIR="$HOME/.local/share/applications"
DESKTOP_NAME="键盘灯开关.desktop"

echo "正在卸载键盘灯开关..."
sudo rm -f /usr/local/bin/kbdlight /etc/sudoers.d/kbdlight
sudo rm -rf /usr/local/libexec/kbdlight
rm -rf "$DATA_DIR"
rm -f "$DESKTOP_DIR/kbdlight.desktop"

DESKTOP_USER_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
if [[ -n "$DESKTOP_USER_DIR" ]]; then
    rm -f "$DESKTOP_USER_DIR/$DESKTOP_NAME"
fi

update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true
echo "卸载完成。已安装的 alienfx-linux 源码（如有）不会被删除。"
