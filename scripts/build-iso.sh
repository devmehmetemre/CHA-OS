#!/bin/bash
# scripts/build-iso.sh — CHA OS ISO oluşturma betiği
set -euo pipefail

VERSION="${1:-1.0.0}"
ARCH="${2:-x86_64}"
ROOTFS="/tmp/rootfs"
ISO_DIR="/tmp/iso"
ISO_OUT="/tmp/chaOS-${VERSION}-${ARCH}.iso"

echo "💿 CHA OS ISO oluşturuluyor: $ISO_OUT"

# ─── ISO dizin yapısı ─────────────────────────
mkdir -p "$ISO_DIR"/{boot/grub/theme,EFI/BOOT,live}

# ─── SquashFS ─────────────────────────────────
echo "🗜️ SquashFS oluşturuluyor (zstd, maksimum sıkıştırma)..."
mksquashfs "$ROOTFS" "$ISO_DIR/live/filesystem.squashfs" \
    -comp zstd \
    -Xcompression-level 19 \
    -b 1048576 \
    -no-progress \
    -wildcards \
    -e "proc/*" "sys/*" "dev/*" "run/*" "tmp/*"

echo "📊 SquashFS: $(du -sh "$ISO_DIR/live/filesystem.squashfs" | cut -f1)"

# ─── Kernel & initrd ──────────────────────────
echo "🐧 Kernel kopyalanıyor..."
KERNEL=$(find "$ROOTFS/boot" -name 'vmlinuz*' | head -1)
INITRD=$(find "$ROOTFS/boot" -name 'initrd*' -o -name 'initramfs*' | head -1)

[ -z "$KERNEL" ] && { echo "❌ Kernel bulunamadı!"; exit 1; }
[ -z "$INITRD" ] && { echo "❌ initrd bulunamadı!"; exit 1; }

cp "$KERNEL" "$ISO_DIR/boot/vmlinuz"
cp "$INITRD" "$ISO_DIR/boot/initrd.img"

echo "✅ Kernel: $(du -sh "$ISO_DIR/boot/vmlinuz" | cut -f1)"
echo "✅ initrd: $(du -sh "$ISO_DIR/boot/initrd.img" | cut -f1)"

# ─── GRUB config ──────────────────────────────
echo "🔧 GRUB yapılandırılıyor..."
cp -r chaOS-branding/grub-theme/* "$ISO_DIR/boot/grub/theme/"

cat > "$ISO_DIR/boot/grub/grub.cfg" << GRUBCFG
# CHA OS GRUB Yapılandırması
set default=0
set timeout=5
set timeout_style=menu

# Grafik modu
insmod all_video
insmod gfxterm
insmod png
set gfxmode=1920x1080,1280x720,auto
terminal_output gfxterm

# Tema
set theme=/boot/grub/theme/theme.txt

# ── Menü girişleri ──────────────────────────────

menuentry "CHA OS ${VERSION} — Başlat" --class chaos --class gnu-linux {
    linux /boot/vmlinuz \
        quiet splash \
        rd.systemd.show_status=false \
        rd.udev.log_level=3 \
        vt.global_cursor_default=0 \
        mitigations=auto
    initrd /boot/initrd.img
}

menuentry "CHA OS ${VERSION} — Kur (cha-setup)" --class chaos {
    linux /boot/vmlinuz \
        quiet splash \
        chasetup=1 \
        rd.systemd.show_status=false
    initrd /boot/initrd.img
}

menuentry "CHA OS — Güvenli Mod" --class chaos {
    linux /boot/vmlinuz \
        single \
        nomodeset \
        systemd.unit=rescue.target
    initrd /boot/initrd.img
}

menuentry "CHA OS — RAM'e Kopyala (toram)" --class chaos {
    linux /boot/vmlinuz \
        quiet splash \
        toram \
        rd.systemd.show_status=false
    initrd /boot/initrd.img
}

menuentry "Bellek Testi (memtest86+)" {
    linux16 /boot/memtest86+.bin
}

menuentry "Firmware Ayarları (UEFI)" {
    fwsetup
}
GRUBCFG

# ─── GRUB EFI kurulumu ────────────────────────
echo "🔒 EFI imajı oluşturuluyor..."

dd if=/dev/zero of="$ISO_DIR/EFI/efiboot.img" bs=1M count=10 2>/dev/null
mkfs.vfat "$ISO_DIR/EFI/efiboot.img" >/dev/null
mmd -i "$ISO_DIR/EFI/efiboot.img" ::/EFI ::/EFI/BOOT

# GRUB EFI binary oluştur
grub-mkimage \
    --format=x86_64-efi \
    --output=/tmp/BOOTX64.EFI \
    --prefix=/boot/grub \
    part_gpt part_msdos fat iso9660 \
    normal boot linux echo configfile \
    loopback chain efifwsetup efi_gop \
    squash4 all_video video_bochs video_cirrus \
    minicmd png gfxterm gfxterm_background \
    terminal terminfo ls search

mcopy -i "$ISO_DIR/EFI/efiboot.img" /tmp/BOOTX64.EFI ::/EFI/BOOT/BOOTX64.EFI

# ─── ISO oluştur ──────────────────────────────
echo "📀 xorriso ile ISO oluşturuluyor..."

# GRUB BIOS boot imajı
grub-mkimage \
    --format=i386-pc \
    --output=/tmp/core.img \
    --prefix=/boot/grub \
    biosdisk part_gpt part_msdos fat iso9660 \
    normal boot linux echo configfile \
    loopback chain squash4

cat /usr/lib/grub/i386-pc/cdboot.img /tmp/core.img > /tmp/grub-eltorito.img

xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "CHAOSOS" \
    -preparer "CHA OS Build System" \
    -publisher "tagchaos" \
    -application_id "CHA OS ${VERSION}" \
    -output "$ISO_OUT" \
    -b boot/grub/grub-eltorito.img \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    --grub2-boot-info \
    --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -append_partition 2 0xef "$ISO_DIR/EFI/efiboot.img" \
    -e '--interval:appended_partition_2:all::' \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
    "$ISO_DIR" 2>&1 | tail -5

# ─── Checksum ─────────────────────────────────
echo ""
echo "🔐 Checksum hesaplanıyor..."
md5sum "$ISO_OUT" | tee "${ISO_OUT}.md5"
sha256sum "$ISO_OUT" | tee "${ISO_OUT}.sha256"

echo ""
echo "════════════════════════════════════════"
echo "✅ ISO hazır: $ISO_OUT"
echo "📊 Boyut: $(du -sh "$ISO_OUT" | cut -f1)"
echo "════════════════════════════════════════"
