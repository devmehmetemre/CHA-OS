#!/usr/bin/env bash
# CHA GRUB asset uretimi: SVG -> PNG raster + terminal_box dilimleri
# Gereken: librsvg, imagemagick, grub-mkfont
set -euo pipefail
SRC=cha-os/branding/logo.svg
DST=cha-os/branding/grub/themes/cha
mkdir -p "$DST"
echo ">> logo raster"
rsvg-convert -w 480 -h 128 "$SRC" -o "$DST/logo.png"
convert "$SRC" -resize 1920x1080 -gravity center -background '#10151A' -extent 1920x1080 "$DST/background-1080.png"
convert "$SRC" -resize 1366x768 -gravity center -background '#10151A' -extent 1366x768 "$DST/background-768.png"
# GRUB tek background bekler -> 1920'yi default yap, 768 testte scale edilir (crop)
cp "$DST/background-1080.png" "$DST/background.png"
echo ">> select box (secili satir: koyu yazi + teal zemin)"
for f in select_c select_e select_w select_nw select_n select_ne select_sw select_s select_se; do
  convert -size 1x1 xc:'#0FB5A6' "$DST/$f.png"
done
echo ">> terminal box (kenarlik 1px #2A323A)"
for f in terminal_box_c terminal_box_e terminal_box_w terminal_box_nw terminal_box_n terminal_box_ne terminal_box_sw terminal_box_s terminal_box_se; do
  convert -size 1x1 xc:'#2A323A' "$DST/$f.png"
done
echo ">> progress bar"
for f in progress_bar_c progress_bar_e progress_bar_w progress_bar_nw progress_bar_n progress_bar_ne progress_bar_sw progress_bar_s progress_bar_se; do
  convert -size 1x1 xc:'#2A323A' "$DST/$f.png"
done
for f in progress_highlight_c progress_highlight_e progress_highlight_w; do
  convert -size 1x1 xc:'#FFB224' "$DST/$f.png"
done
echo ">> fontlar (GRUB pf2)"
grub-mkfont -o "$DST/inter-regular-16.pf2" -s 16 /usr/share/fonts/TTF/Inter-Regular.ttf 2>/dev/null || echo "WARN: Inter bulunamadi, Unifont kullanilacak"
grub-mkfont -o "$DST/inter-bold-16.pf2" -s 16 /usr/share/fonts/TTF/Inter-Bold.ttf 2>/dev/null || true
ls -lh "$DST"
