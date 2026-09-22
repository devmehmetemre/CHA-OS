#!/bin/bash
# scripts/build-rootfs.sh — CHA OS rootfs oluşturma betiği
set -euo pipefail

# ─── Argümanlar ───────────────────────────────
ROOTFS="/tmp/rootfs"
VERSION="1.0.0"
ARCH="x86_64"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --rootfs)  ROOTFS="$2"; shift 2 ;;
        --version) VERSION="$2"; shift 2 ;;
        --arch)    ARCH="$2"; shift 2 ;;
        *) echo "Bilinmeyen argüman: $1"; exit 1 ;;
    esac
done

echo "🔧 CHA OS Rootfs oluşturuluyor..."
echo "   Rootfs: $ROOTFS"
echo "   Sürüm:  $VERSION"
echo "   Mimari: $ARCH"

# ─── DNS ayarı (chroot için) ───────────────────
echo "nameserver 1.1.1.1" > "$ROOTFS/etc/resolv.conf"
echo "nameserver 8.8.8.8" >> "$ROOTFS/etc/resolv.conf"

# ─── Özel apk deposunu ekle ───────────────────
cat > "$ROOTFS/etc/apk/repositories" << EOF
https://dl-cdn.alpinelinux.org/alpine/v3.20/main
https://dl-cdn.alpinelinux.org/alpine/v3.20/community
EOF

# ─── chroot mount ─────────────────────────────
mount --bind /proc "$ROOTFS/proc"
mount --bind /sys "$ROOTFS/sys"
mount --bind /dev "$ROOTFS/dev"
mount --bind /dev/pts "$ROOTFS/dev/pts"

cleanup() {
    echo "🧹 Mount noktaları temizleniyor..."
    umount -l "$ROOTFS/proc" 2>/dev/null || true
    umount -l "$ROOTFS/sys" 2>/dev/null || true
    umount -l "$ROOTFS/dev/pts" 2>/dev/null || true
    umount -l "$ROOTFS/dev" 2>/dev/null || true
}
trap cleanup EXIT

# ─── Temel paketler ───────────────────────────
echo "📦 Temel paketler kuruluyor..."
chroot "$ROOTFS" apk update
chroot "$ROOTFS" apk add --no-cache \
    alpine-base \
    linux-lts \
    linux-firmware-none \
    openrc \
    util-linux \
    e2fsprogs \
    dosfstools \
    grub \
    grub-efi \
    efibootmgr \
    sudo \
    shadow \
    bash \
    curl \
    wget \
    git \
    dialog \
    whiptail \
    vim \
    nano \
    htop \
    neofetch \
    openssh \
    networkmanager \
    dbus \
    eudev \
    pciutils \
    usbutils \
    ca-certificates \
    tzdata \
    kbd \
    font-terminus \
    terminus-font

# ─── CHA OS özel dosyaları ────────────────────
echo "🎨 CHA OS branding uygulanıyor..."

# MOTD
cp rootfs/etc/motd "$ROOTFS/etc/motd"

# OS kimlik dosyaları
cp rootfs/etc/os-release "$ROOTFS/etc/os-release"
cp rootfs/etc/chaOS-release "$ROOTFS/etc/chaOS-release"

# cha-setup kurulum aracı
mkdir -p "$ROOTFS/usr/local/bin"
cp cha-setup/cha-setup.sh "$ROOTFS/usr/local/bin/cha-setup"
chmod +x "$ROOTFS/usr/local/bin/cha-setup"

# Özel yardım komutları
cp scripts/cha-commands.sh "$ROOTFS/usr/local/bin/cha-help"
cp scripts/cha-commands.sh "$ROOTFS/usr/local/bin/cha-info"
cp scripts/cha-commands.sh "$ROOTFS/usr/local/bin/cha-update"
chmod +x "$ROOTFS/usr/local/bin/cha-"{help,info,update}

# ─── OpenRC servisler ─────────────────────────
echo "⚙️ Servisler yapılandırılıyor..."
chroot "$ROOTFS" rc-update add devfs sysinit
chroot "$ROOTFS" rc-update add dmesg sysinit
chroot "$ROOTFS" rc-update add mdev sysinit
chroot "$ROOTFS" rc-update add hwclock boot
chroot "$ROOTFS" rc-update add modules boot
chroot "$ROOTFS" rc-update add sysctl boot
chroot "$ROOTFS" rc-update add hostname boot
chroot "$ROOTFS" rc-update add bootmisc boot
chroot "$ROOTFS" rc-update add syslog boot
chroot "$ROOTFS" rc-update add networking default
chroot "$ROOTFS" rc-update add sshd default
chroot "$ROOTFS" rc-update add dbus default
chroot "$ROOTFS" rc-update add networkmanager default
chroot "$ROOTFS" rc-update add mount-ro shutdown
chroot "$ROOTFS" rc-update add killprocs shutdown
chroot "$ROOTFS" rc-update add savecache shutdown

# ─── Live ortam ayarı ─────────────────────────
echo "💿 Live ortam yapılandırılıyor..."

# autologin (live için)
mkdir -p "$ROOTFS/etc/init.d"
cat > "$ROOTFS/etc/inittab" << 'EOF'
# CHA OS inittab
::sysinit:/sbin/openrc sysinit
::wait:/sbin/openrc boot
::wait:/sbin/openrc default

# Terminaller — tty1'de autologin (live mod)
tty1::respawn:/sbin/agetty --autologin root --noclear tty1 linux
tty2::respawn:/sbin/agetty tty2 linux
tty3::respawn:/sbin/agetty tty3 linux
tty4::respawn:/sbin/agetty tty4 linux

::shutdown:/sbin/openrc shutdown
::restart:/sbin/openrc shutdown
EOF

# Root bash profili (live MOTD + cha-setup yönlendirmesi)
cat > "$ROOTFS/root/.profile" << 'PROFILE'
export PATH="/usr/local/bin:$PATH"
cat /etc/motd
echo ""
echo "  Live moddasınız. Sistemi kurmak için: cha-setup"
echo ""
PROFILE

# ─── Sürüm numarası ───────────────────────────
echo "$VERSION" > "$ROOTFS/etc/chaOS-version"

# ─── Boyut raporu ─────────────────────────────
echo ""
echo "✅ Rootfs hazır!"
echo "📊 Boyut: $(du -sh "$ROOTFS" | cut -f1)"
echo "📦 Paket sayısı: $(chroot "$ROOTFS" apk info | wc -l)"
