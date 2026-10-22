#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${ALIENFX_SRC:-$HOME/.local/src/alienfx-linux}"
INSTALL_BIN="/usr/local/bin/kbdlight"
LIBEXEC_DIR="/usr/local/libexec/kbdlight"
SUDOERS_FILE="/etc/sudoers.d/kbdlight"
DATA_DIR="$HOME/.local/share/kbdlight"
DESKTOP_DIR="$HOME/.local/share/applications"
DESKTOP_NAME="键盘灯开关.desktop"
USER_NAME="$(id -un)"

say() { printf '\n\033[1m%s\033[0m\n' "$*"; }
die() { printf '错误：%s\n' "$*" >&2; exit 1; }

if [[ $EUID -eq 0 ]]; then
    die "请用普通用户运行本脚本，不要直接 sudo 整个脚本；安装过程中会按需请求 sudo。"
fi

say "1/5 检查编译依赖"
missing=()
for c in git cmake ninja g++; do
    command -v "$c" >/dev/null 2>&1 || missing+=("$c")
done
if ((${#missing[@]})); then
    echo "缺少命令：${missing[*]}"
    echo "Ubuntu / Debian 请先执行："
    echo "  sudo apt install git cmake ninja-build libudev-dev g++"
    exit 1
fi
if [[ ! -e /usr/include/libudev.h ]]; then
    echo "缺少 libudev 开发头文件，请先执行："
    echo "  sudo apt install libudev-dev"
    exit 1
fi

say "2/5 获取并编译 alienfx-linux"
if [[ ! -x "$SRC_DIR/build/alienfx_cli" ]]; then
    if [[ ! -d "$SRC_DIR/.git" ]]; then
        mkdir -p "$(dirname "$SRC_DIR")"
        git clone --depth 1 https://github.com/tr1xem/alienfx-linux.git "$SRC_DIR"
    fi
    mkdir -p "$SRC_DIR/build"
    cmake -S "$SRC_DIR" -B "$SRC_DIR/build" -G Ninja \
        -DALIENFX_BUILD_CLI=ON -DCMAKE_BUILD_TYPE=Release
    ninja -C "$SRC_DIR/build"
fi

say "3/5 安装 root 助手"
sudo install -d -m 0755 -o root -g root "$LIBEXEC_DIR"
sudo install -m 0755 -o root -g root "$SRC_DIR/build/alienfx_cli" "$LIBEXEC_DIR/alienfx_cli"
sudo install -m 0755 -o root -g root "$APP_DIR/kbdlight" "$INSTALL_BIN"

say "4/5 配置 sudo 免密（只允许开灯和关灯）"
tmp_sudoers="$(mktemp)"
trap 'rm -f "$tmp_sudoers"' EXIT
printf '%s ALL=(root) NOPASSWD: %s on, %s off\n' \
    "$USER_NAME" "$INSTALL_BIN" "$INSTALL_BIN" >"$tmp_sudoers"
sudo install -m 0440 -o root -g root "$tmp_sudoers" "$SUDOERS_FILE"
sudo visudo -cf "$SUDOERS_FILE"

say "5/5 安装图形界面"
mkdir -p "$DATA_DIR" "$DESKTOP_DIR"
install -m 0755 "$APP_DIR/kbdlight_app.py" "$DATA_DIR/kbdlight_app.py"
sed "s|@APP_PATH@|$DATA_DIR/kbdlight_app.py|g" \
    "$APP_DIR/kbdlight.desktop" >"$DESKTOP_DIR/kbdlight.desktop"
update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true

DESKTOP_USER_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
if [[ -n "$DESKTOP_USER_DIR" && -d "$DESKTOP_USER_DIR" ]]; then
    install -m 0755 "$DESKTOP_DIR/kbdlight.desktop" \
        "$DESKTOP_USER_DIR/$DESKTOP_NAME"
    gio set "$DESKTOP_USER_DIR/$DESKTOP_NAME" metadata::trusted true >/dev/null 2>&1 || true
fi

say "安装完成"
echo "从应用菜单或桌面打开“键盘灯开关”即可使用。"
echo "注意：关闭后键盘灯会保持熄灭，重启系统会恢复默认亮。"
