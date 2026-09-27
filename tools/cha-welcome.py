#!/usr/bin/env python3
# cha-welcome: GTK3 + Python (libadwaita yok, XFCE/LXQt'de hafif)
# Bagimlilik: python-gobject gtk3 (zaten XFCE/LXQt'de var)
import gi, subprocess, os
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk

PALETTE = {"bg": "#10151A", "fg": "#F2F4F3", "teal": "#0FB5A6", "accent": "#FFB224"}

def detect():
    out = {}
    try:
        r = subprocess.run(["/usr/bin/cha-profile-detect"], capture_output=True, text=True)
        for line in r.stdout.splitlines():
            k, v = line.split("=", 1); out[k] = v
    except Exception as e:
        out = {"PROFILE": "balanced", "KERNEL_SUGGEST": "cha-kernel", "ERROR": str(e)}
    return out

class Welcome(Gtk.Window):
    def __init__(self):
        super().__init__(title="CHA OS'a Hos Geldin")
        self.set_default_size(620, 420)
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        box.set_margin_top(20); box.set_margin_bottom(20)
        box.set_margin_start(20); box.set_margin_end(20)
        self.add(box)
        info = detect()
        title = Gtk.Label(label="<b>CHA OS 2026.10 Kivilcim</b>")
        title.set_use_markup(True)
        box.pack_start(title, False, False, 0)
        txt = f"CPU: {info.get('CORES','?')} cekirdek | RAM: {info.get('MEM_MB','?')}MB | Disk: {info.get('DISK_TYPE','?')}\nOneri: {info.get('PROFILE','')} -> {info.get('KERNEL_SUGGEST','')} | zram {info.get('ZRAM_SUGGEST','')} | compositor {info.get('COMPOSITOR_SUGGEST','')}"
        lbl = Gtk.Label(label=txt)
        box.pack_start(lbl, False, False, 0)
        btn_apply = Gtk.Button(label="Oneriyi Uygula (zram + governor)")
        btn_apply.connect("clicked", self.on_apply, info)
        box.pack_start(btn_apply, False, False, 0)
        btn_tweaks = Gtk.Button(label="cha-tweaks'i Ac")
        btn_tweaks.connect("clicked", lambda b: subprocess.Popen(["cha-tweaks"]))
        box.pack_start(btn_tweaks, False, False, 0)
        link = Gtk.LinkButton(uri="https://cha-os.local/wiki", label="Wiki ve Topluluk")
        box.pack_start(link, False, False, 0)

    def on_apply(self, btn, info):
        # zram + governor uygula (pkexec ile root)
        zram = info.get("ZRAM_SUGGEST", "100%")
        gov = info.get("GOVERNOR_SUGGEST", "schedutil")
        subprocess.Popen(["pkexec", "bash", "-c", f"/usr/bin/cha-zram-apply; echo {gov} | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"])

win = Welcome()
win.connect("destroy", Gtk.main_quit)
win.show_all()
Gtk.main()
