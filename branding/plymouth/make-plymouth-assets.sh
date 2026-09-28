#!/usr/bin/env bash
# CHA Plymouth asset: tek logo + 2 adet 1x1 bar (initramfs siskinligi yok)
set -euo pipefail
SRC=branding/logo.svg
DST=branding/plymouth/themes/cha
IMG=convert
command -v magick >/dev/null && IMG=magick
mkdir -p "$DST"
rsvg-convert -w 640 -h 171 "$SRC" -o "$DST/logo.png" 2>/dev/null || $IMG "$SRC" -resize 640x171 "$DST/logo.png"
$IMG -size 1x1 xc:'#2A323A' "$DST/bar-bg.png"
$IMG -size 1x1 xc:'#FFB224' "$DST/bar-fg.png"
# 768p vs 1080p icin ayri asset YOK - cha.script scale ile buyutur (dosya boyutu kucuk kalir)
ls -lh "$DST"
echo "Toplam hedef: <300KB (logo 640px + 2x 1x1). Initramfs'e sadece bu 3 dosya girer."
