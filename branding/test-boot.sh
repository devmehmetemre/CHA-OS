#!/usr/bin/env bash
# CHA boot test: GRUB tema + Plymouth hizli dogrulama (QEMU 2G/2CPU + gercek videoinfo)
set -euo pipefail
echo "== 1. GRUB tema syntax =="
grub-script-check cha-os/branding/grub/themes/cha/theme.txt 2>&1 || echo "(theme.txt grub-script-check'ten gecmez, bu normal - theme parser ayridir, gozle kontrol et)"
echo "== 2. QEMU 1366x768 =="
echo "qemu-system-x86_64 -m 2G -smp 2 -vga std -display gtk -cdrom out/cha-os.iso -boot d -vnc :0"
echo "GRUB'da 'c' -> videoinfo -> gfxmode=1366x768 test et"
echo "== 3. QEMU 1920x1080 =="
echo "qemu-system-x86_64 -m 2G -smp 2 -vga virtio -display gtk,gl=off -cdrom out/cha-os.iso -boot d"
echo "== 4. Plymouth test (kurulu sistemde) =="
echo "sudo plymouth-set-default-theme cha -R"
echo "sudo mkinitcpio -P && sudo plymouthd --debug --debug-file=/tmp/plymouth-debug.log ; sudo plymouth --show-splash ; sleep 5 ; sudo plymouth --quit"
