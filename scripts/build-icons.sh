#!/bin/bash
# scripts/build-icons.sh — chaOS-icons paketini oluşturur
# SVG ikonları PNG'ye dönüştürür ve APKBUILD çıktısı üretir
set -euo pipefail

ICON_SRC="$(dirname "$0")/../chaOS-icons"
OUT_DIR="/tmp/chaOS-icons-build"
SIZES=(16 22 24 32 48 64 96 128)
CONTEXTS=(apps categories places status)

echo "🎨 chaOS-icons paketi oluşturuluyor..."

# ─── Bağımlılık kontrolü ───────────────────────
for dep in inkscape optipng; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        echo "  [!] $dep bulunamadı, SVG kaynak kopyalanacak"
        INKSCAPE_OK=0
    else
        INKSCAPE_OK=1
    fi
done

# ─── Dizin yapısı ────────────────────────────
mkdir -p "$OUT_DIR/usr/share/icons/chaOS-icons"
cp "$ICON_SRC/index.theme" "$OUT_DIR/usr/share/icons/chaOS-icons/"

# ─── Her boyut ve bağlam için dönüştür ───────
for size in "${SIZES[@]}"; do
    for ctx in "${CONTEXTS[@]}"; do
        src_dir="$ICON_SRC/scalable/$ctx"
        dst_dir="$OUT_DIR/usr/share/icons/chaOS-icons/${size}x${size}/$ctx"
        mkdir -p "$dst_dir"

        [ -d "$src_dir" ] || continue

        for svg in "$src_dir"/*.svg; do
            [ -f "$svg" ] || continue
            base=$(basename "$svg" .svg)

            if [ "$INKSCAPE_OK" -eq 1 ]; then
                # SVG → PNG dönüşümü
                inkscape \
                    --export-type=png \
                    --export-width="$size" \
                    --export-height="$size" \
                    --export-filename="$dst_dir/${base}.png" \
                    "$svg" 2>/dev/null

                # PNG optimizasyonu
                optipng -quiet -o2 "$dst_dir/${base}.png" 2>/dev/null || true
            else
                # Inkscape yoksa SVG'yi direkt kopyala
                cp "$svg" "$dst_dir/${base}.svg"
            fi
        done
        echo "  ✅ ${size}x${size}/$ctx"
    done
done

# ─── Scalable ikonları kopyala ─────────────────
for ctx in "${CONTEXTS[@]}"; do
    dst_dir="$OUT_DIR/usr/share/icons/chaOS-icons/scalable/$ctx"
    src_dir="$ICON_SRC/scalable/$ctx"
    mkdir -p "$dst_dir"
    [ -d "$src_dir" ] && cp "$src_dir"/*.svg "$dst_dir/" 2>/dev/null || true
done

# ─── Icon cache oluştur ────────────────────────
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "$OUT_DIR/usr/share/icons/chaOS-icons"
    echo "  ✅ GTK ikon önbelleği güncellendi"
fi

# ─── APK paketi oluştur ───────────────────────
cat > "$OUT_DIR/APKBUILD" << 'APKBUILD'
# Maintainer: tagchaos <chaos@tagchaos.dev>
pkgname="chaOS-icons"
pkgver="1.0.0"
pkgrel=0
pkgdesc="CHA OS resmi ikon paketi"
url="https://github.com/tagchaos/chaOS"
arch="noarch"
license="MIT"
depends="papirus-icon-theme"
source=""

package() {
    cp -r usr/ "$pkgdir/"
    chmod -R 755 "$pkgdir/usr/share/icons"
}
APKBUILD

# ─── Tar arşivi ───────────────────────────────
cd "$OUT_DIR"
tar -czf "/tmp/chaOS-icons-1.0.0.tar.gz" usr/
echo ""
echo "✅ Tamamlandı!"
echo "📦 Arşiv: /tmp/chaOS-icons-1.0.0.tar.gz"
echo "📊 Boyut: $(du -sh /tmp/chaOS-icons-1.0.0.tar.gz | cut -f1)"
