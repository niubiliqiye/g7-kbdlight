# G7 键盘灯开关（Ubuntu）

给 **Dell G7 7790** 用的键盘背光开关小应用。打开应用，点“开灯”或“关灯”即可控制键盘背光，不需要每次输密码。

> 已在 Dell G7 7790 + Ubuntu 26.04 + GNOME Wayland 上实测通过。使用同类 AlienFX `AW-ELC` 灯光控制器的 Dell G 系列理论上也能用，但未逐一验证。

## 为什么需要它

很多 Dell 笔记本在 Linux 下可以直接通过 `/sys/class/leds/dell::kbd_backlight` 控制键盘灯。但 G7 7790 没有这个标准接口：

- 系统里不存在 `dell::kbd_backlight` 节点；
- 内核 `alienware-wmi` 驱动的全局亮度接口可以写入，但对键盘灯没有实际效果；
- `rgb_zones` 分区接口写入会直接返回 I/O 错误。

G7 的键盘灯实际挂在一个 USB 灯光控制器上：

```
187c:0550 Alienware Corporation LED controller (AW-ELC)
```

本应用通过开源工具 [alienfx-linux](https://github.com/tr1xem/alienfx-linux) 的 `alienfx_cli`，对 0–7 号灯位写入颜色，实现整块键盘的开关：

- 关灯：所有灯位写入 `0 0 0`
- 开灯：所有灯位写入 `255 255 255`（白色）

## 功能

- 一个 GTK4 小窗口，显示当前状态（亮着 / 已关闭 / 未知）
- “开灯”“关灯”两个按钮，点击立即生效
- 自动安装到应用菜单和桌面
- 普通用户点击即可使用，不需要每次输入 sudo 密码
- 状态记录在 `/run/kbdlight.state`，重启后自动回到“未知（默认亮着）”

## 安装

### 依赖

Ubuntu / Debian：

```bash
sudo apt install git cmake ninja-build libudev-dev g++
```

另外需要 Python 3、GTK4 和 `xdg-user-dirs`（Ubuntu 桌面版默认都有）。

### 安装步骤

```bash
git clone https://github.com/niubiliqiye/g7-kbdlight.git
cd g7-kbdlight
./install.sh
```

安装脚本会做这些事：

1. 检查编译依赖；
2. 把 [alienfx-linux](https://github.com/tr1xem/alienfx-linux) 克隆到 `~/.local/src/alienfx-linux` 并编译出 `alienfx_cli`；
3. 把 `alienfx_cli` 和开关助手安装到 root 拥有的目录；
4. 写入一条只允许 `kbdlight on` / `kbdlight off` 的 sudo 免密规则；
5. 安装 GTK 应用到 `~/.local/share/kbdlight/`，并创建应用菜单和桌面图标。

安装过程中会请求一次 sudo 密码，用于写入 `/usr/local` 和 `/etc/sudoers.d`。

### 使用

在 Ubuntu 应用列表里搜索 **“键盘灯开关”**，或双击桌面上的同名图标。

窗口里：

- **开灯**：键盘背光恢复白色
- **关灯**：键盘背光熄灭
- 顶部会显示当前状态

### 卸载

```bash
cd g7-kbdlight
./uninstall.sh
```

卸载会删除助手、sudo 规则、图形界面和桌面图标，但不会删除 `~/.local/src/alienfx-linux` 源码目录，也不会自动卸载 `cmake` 等编译依赖。

## 安装后的文件位置

| 路径 | 作用 |
| --- | --- |
| `/usr/local/bin/kbdlight` | root 开关助手，只接受 `on` / `off` |
| `/usr/local/libexec/kbdlight/alienfx_cli` | 实际与灯光控制器通信的程序（root 所有） |
| `/etc/sudoers.d/kbdlight` | 仅允许当前用户免密执行 `kbdlight on` / `kbdlight off` |
| `~/.local/share/kbdlight/kbdlight_app.py` | GTK4 图形界面 |
| `~/.local/share/applications/kbdlight.desktop` | 应用菜单入口 |
| `~/桌面/键盘灯开关.desktop` | 桌面图标（如果系统有桌面目录） |
| `/run/kbdlight.state` | 当前状态记录，重启后清空 |

## 安全说明

- sudo 免密规则只允许执行 `/usr/local/bin/kbdlight on` 和 `/usr/local/bin/kbdlight off`，不能借它执行其他命令。
- 真正与硬件通信的 `alienfx_cli` 安装在 root 拥有的 `/usr/local/libexec/kbdlight/`，普通用户无法替换。
- 图形界面以普通用户运行，只有点击按钮时才会通过受限的 sudo 规则调用助手。

## 限制与注意事项

- **重启后键盘灯会恢复默认亮**，应用不会自动启动；需要时再打开应用即可。
- 关灯是通过把灯位写成黑色实现的，不是修改 BIOS 设置；再次开灯会恢复为白色。
- 只在 Dell G7 7790 上做过实机验证。其他 Dell G 系列如果也使用 `187c:0550` AW-ELC 控制器，可能可用，但请先自行测试。
- 这台机器上按 `Fn+F10` 目前不会改变灯光，也没有绑定任何快捷键；本应用不依赖它。
- 应用状态栏在重启后显示“未知（通常为亮着）”，因为 `/run` 是临时目录，状态不会跨重启保存。

## 致谢

- [alienfx-linux](https://github.com/tr1xem/alienfx-linux)：提供 Linux 下的 AlienFX / AW-ELC 控制能力
- [alienfx-tools](https://github.com/T-Troll/alienfx-tools)：alienfx-linux 的上游项目
- [Dell G Series Controller](https://github.com/cemkaya-mpi/Dell-G-Series-Controller) 与 [alienfx-leds](https://github.com/zeecka/alienfx-leds)：相关的社区探索

## 许可证

本仓库中的脚本和图形界面代码使用 MIT 许可证，详见 [LICENSE](LICENSE)。

`alienfx-linux` 是独立项目，使用其自己的许可证，安装脚本只会在运行时从上游仓库获取，不随本仓库分发。
