#!/usr/bin/env bash
# cha-init-optimize: ilk boot'ta calisir, donanim yoksa servisi kapat (cha-tweaks ile geri acilir)
# Hedef: eMMC'de <15sn soguk boot (systemd-analyze)
set -euo pipefail
has_hw() { lsmod | grep -qi "$1" || lspci 2>/dev/null | grep -qi "$1" || lsusb 2>/dev/null | grep -qi "$1"; }
echo ">> gereksiz servisler kapatiliyor"
# Bluetooth donanim yoksa
if ! has_hw bluetooth && ! has_hw btusb; then systemctl disable --now bluetooth 2>/dev/null || true; echo "bluetooth: off (cha-tweaks ile ac)"; fi
# Yazici yoksa cups
if ! lpstat -p >/dev/null 2>&1; then systemctl disable --now cups cups.socket 2>/dev/null || true; echo "cups: off"; fi
# Avahi gereksizse
systemctl disable --now avahi-daemon 2>/dev/null || true
# ModemManager (WWAN yoksa)
if ! has_hw wwan && ! has_hw modem; then systemctl disable --now ModemManager 2>/dev/null || true; fi
# lvm2/lvmetad (luks/lvm yoksa)
systemctl disable --now lvm2-monitor 2>/dev/null || true
# Gerekliler acik kalsin
systemctl enable --now NetworkManager tlp systemd-zram-setup@zram0 reflector-weekly.timer 2>/dev/null || true
echo ">> boot olcumu"
systemd-analyze blame | head -20
systemd-analyze time
