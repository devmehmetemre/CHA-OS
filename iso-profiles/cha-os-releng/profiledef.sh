#!/usr/bin/env bash
iso_name="cha-os"
iso_label="CHA_OS_$(date +%Y%m)"
iso_publisher="CHA OS Project"
iso_application="CHA OS Live/Install"
iso_version="2026.10-Kivilcim"
install_dir="arch"
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito' 'uefi-x64.systemd-boot.esp' 'uefi-x64.systemd-boot.eltorito')
arch="x86_64"
# Faz1 karari: x86-64-v1 baseline (Core2/Atom N450 dahil). v3 optimize kernel Faz2'de ayri paket olacak.
# ARM portu ertelendi, bu profil sadece x86_64 uretir.
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '15' '-b' '1M')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
)
