#!/usr/bin/env bash
# CI ISO derleme yuku - docker --privileged icinde calisir, repo kokunden cagrilir.
# Neden dosya: workflow icinde bash -c '...' + awk '...' tirnaklari birbirini olduruyordu.
set -euo pipefail
pacman -Syu --noconfirm --needed archiso mkinitcpio git reflector librsvg imagemagick grub squashfs-tools dosfstools mtools xorriso
# asset uretimi
bash branding/grub/make-grub-assets.sh || {
  mkdir -p branding/grub/themes/cha
  IMG=convert
  command -v magick >/dev/null && IMG=magick
  $IMG -size 1920x1080 xc:'#10151A' branding/grub/themes/cha/background.png
}
bash branding/plymouth/make-plymouth-assets.sh || true
# CI gecici: cha-kernel henuz repoda yok, yerine linux kullan
cp -r iso-profiles/cha-os-releng /tmp/releng-xfce
sed -i "s/^cha-kernel$/linux/" /tmp/releng-xfce/packages.x86_64
cat iso-profiles/cha-os-releng/packages.xfce.x86_64 >> /tmp/releng-xfce/packages.x86_64
# CI: [cha-repo] sunucusu henuz yok -> profil kopyasindan dusur (ISO'da cha-* paketi yok)
awk '/^\[cha-repo\]/{skip=1;next} /^\[/{skip=0} !skip' /tmp/releng-xfce/pacman.conf > /tmp/pac && mv /tmp/pac /tmp/releng-xfce/pacman.conf
mkdir -p out
mkarchiso -v -w /tmp/cha-work -o out/ /tmp/releng-xfce/
