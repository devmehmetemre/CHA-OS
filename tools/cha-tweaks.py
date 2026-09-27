#!/usr/bin/env python3
# cha-tweaks: DE-agnostik ayar merkezi (GTK3, gsettings + xfconf + dosya)
import gi, subprocess
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk

def sh(cmd): subprocess.Popen(["bash", "-c", cmd])

class Tweaks(Gtk.Window):
    def __init__(self):
        super().__init__(title="cha-tweaks")
        self.set_default_size(560, 420)
        nb = Gtk.Notebook()
        self.add(nb)
        # Tema
        b1 = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        b1.set_margin_start(16); b1.set_margin_end(16); b1.set_margin_top(16)
        for theme in ["CHA", "CHA-Light", "Adwaita"]:
            btn = Gtk.Button(label=f"Tema: {theme}")
            btn.connect("clicked", lambda b, t=theme: sh(f"gsettings set org.gnome.desktop.interface gtk-theme '{t}'; xfconf-query -c xsettings -p /Net/ThemeName -s '{t}' || true"))
            b1.pack_start(btn, False, False, 0)
        nb.append_page(b1, Gtk.Label(label="Tema"))
        # Animasyon
        b2 = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        b2.set_margin_start(16); b2.set_margin_top(16)
        on = Gtk.Button(label="Compositor AC (picom)")
        on.connect("clicked", lambda b: sh("picom --daemon || true"))
        off = Gtk.Button(label="Compositor KAPAT (eski GPU)")
        off.connect("clicked", lambda b: sh("pkill picom || true"))
        b2.pack_start(on, False, False, 0); b2.pack_start(off, False, False, 0)
        nb.append_page(b2, Gtk.Label(label="Efekt"))
        # Guc
        b3 = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        b3.set_margin_start(16); b3.set_margin_top(16)
        for p in ["power", "balanced-power", "performance"]:
            btn = Gtk.Button(label=f"powerprofilesctl {p}")
            btn.connect("clicked", lambda b, q=p: sh(f"powerprofilesctl set {q} || tlp start || true"))
            b3.pack_start(btn, False, False, 0)
        nb.append_page(b3, Gtk.Label(label="Guc"))
        # Kernel
        b4 = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        b4.set_margin_start(16); b4.set_margin_top(16)
        lbl = Gtk.Label(label="Kernel degisimi terminalden (guvenli):")
        b4.pack_start(lbl, False, False, 0)
        for k in ["cha-kernel", "cha-kernel-v3", "cha-kernel-lts", "cha-kernel-lowend"]:
            btn = Gtk.Button(label=f"Kur: {k}")
            btn.connect("clicked", lambda b, q=k: sh(f"pkexec pacman -S {q}"))
            b4.pack_start(btn, False, False, 0)
        nb.append_page(b4, Gtk.Label(label="Kernel"))

w = Tweaks()
w.connect("destroy", Gtk.main_quit)
w.show_all()
Gtk.main()
