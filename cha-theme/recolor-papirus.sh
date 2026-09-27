#!/usr/bin/env bash
# Papirus -> Papirus-CHA recolor: klasor rengi teal, tray symbolic accent
# Neden Papirus: 10k+ ikon, recolor scripti hazir, Tela'dan daha aktif
set -euo pipefail
sudo pacman -S --needed papirus-icon-theme papirus-folders
papirus-folders -C teal --theme Papirus
# Kopyala ve yeniden adlandir (orijinali ezme)
sudo cp -r /usr/share/icons/Papirus /usr/share/icons/Papirus-CHA
# Tray override: ag/pil/ses symbolic ikonlari accent'e yakin tut, marka disi kirmizi/mor ikonlari degistir
# Ornek: nm-signal-100 -> teal cizgi (asagi yukari elle SVG duzenlenir, toplu sed):
sudo sed -i 's/#5294e2/#0FB5A6/g' /usr/share/icons/Papirus-CHA/*/panel/*.svg 2>/dev/null || true
echo "Papirus-CHA hazir. GTK ayari: gsettings set org.gnome.desktop.interface icon-theme 'Papirus-CHA'"
echo "XFCE: xfconf-query -c xsettings -p /Net/IconThemeName -s Papirus-CHA"
