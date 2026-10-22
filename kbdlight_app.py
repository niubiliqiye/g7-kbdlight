#!/usr/bin/env python3
import subprocess
import sys

import gi

gi.require_version("Gtk", "4.0")
from gi.repository import Gtk

HELPER = "/usr/local/bin/kbdlight"
STATE_FILE = "/run/kbdlight.state"


def read_state():
    try:
        with open(STATE_FILE, encoding="utf-8") as f:
            return f.read().strip()
    except OSError:
        return "unknown"


class LightApp(Gtk.Application):
    def __init__(self):
        super().__init__(application_id="cc.renovia.kbdlight")
        self.window = None

    def do_activate(self):
        if self.window is None:
            self.build()
        self.refresh()
        self.window.present()

    def build(self):
        self.window = Gtk.ApplicationWindow(application=self, title="键盘灯开关")
        self.window.set_default_size(360, 230)
        self.window.set_resizable(False)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        for side in ("top", "bottom", "start", "end"):
            getattr(box, f"set_margin_{side}")(26)

        heading = Gtk.Label(label="G7 键盘背光")
        heading.add_css_class("title-1")
        box.append(heading)

        self.status = Gtk.Label()
        self.status.add_css_class("dim-label")
        box.append(self.status)

        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        row.set_homogeneous(True)
        on_btn = Gtk.Button(label="开灯")
        on_btn.add_css_class("suggested-action")
        on_btn.connect("clicked", self.on_click, "on")
        off_btn = Gtk.Button(label="关灯")
        off_btn.add_css_class("destructive-action")
        off_btn.connect("clicked", self.on_click, "off")
        row.append(on_btn)
        row.append(off_btn)
        box.append(row)

        hint = Gtk.Label(label="关灯后保持熄灭，重启或再次开灯才会恢复。")
        hint.set_wrap(True)
        hint.add_css_class("dim-label")
        box.append(hint)

        self.window.set_child(box)

    def refresh(self):
        state = read_state()
        if state == "on":
            text = "当前状态：亮着"
        elif state == "off":
            text = "当前状态：已关闭"
        else:
            text = "当前状态：未知（通常为亮着）"
        self.status.set_text(text)

    def on_click(self, _button, action):
        try:
            proc = subprocess.run(
                ["sudo", "-n", HELPER, action],
                capture_output=True,
                text=True,
                timeout=30,
            )
        except Exception as exc:
            self.status.set_text(f"操作失败：{exc}")
            return
        if proc.returncode != 0:
            msg = (proc.stderr or proc.stdout or "未知错误").strip()
            self.status.set_text(f"操作失败：{msg}")
            return
        self.refresh()


def main():
    app = LightApp()
    return app.run(sys.argv)


if __name__ == "__main__":
    sys.exit(main())
