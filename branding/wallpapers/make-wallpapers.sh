#!/usr/bin/env bash
# CHA 5 duvar kagidi - statik PNG, compositor blur yok, dusuk GPU dostu
# 1920x1080 + 1366x768 cift cozunurluk uretir
set -euo pipefail
OUT=cha-os/branding/wallpapers/out
mkdir -p "$OUT"
mk() { # $1 ad $2 magick args
  local n="$1"; shift
  convert -size 1920x1080 "$@" "$OUT/${n}-1920.png"
  convert "$OUT/${n}-1920.png" -resize 1366x768 "$OUT/${n}-1366.png"
  echo "$n OK"
}
# 1 Abyss Teal: koyu zemin + diyagonal teal gecis (amiral)
mk 01-abyss-teal gradient:'#10151A-#0A3D38' -fill '#0FB5A6' -draw 'roundrectangle 200,800,1720,804 4,4'
# 2 Kivilcim Cizgisi: logo pulse cizgisinin buyuk hali
mk 02-spark-line xc:'#10151A' -fill none -stroke '#FFB224' -strokewidth 4 -draw 'polyline 200,540 700,540 760,480 820,600 880,520 1400,520'
# 3 Geometrik Izgara: dusuk kontrast cizgiler, goz yormaz
mk 03-grid xc:'#14110F' -fill none -stroke '#2A323A' -draw 'line 0,270 1920,270 line 0,540 1920,540 line 0,810 1920,810 line 480,0 480,1080 line 960,0 960,1080 line 1440,0 1440,1080'
# 4 Kum Tepesi (acik mod): acik zemin, goz dostu
mk 04-dune-light gradient:'#F2F4F3-#D8E2DC' -fill '#0A6B62' -draw 'circle 1600,200 1620,200'
# 5 Gece Grafit: saf minimal, OLED/eMMC dostu (saf siyah degil, #0E1116)
mk 05-graphite-night xc:'#0E1116' -fill '#0FB5A6' -draw 'circle 960,540 962,540'
ls -lh "$OUT"
