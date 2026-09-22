# CHA OS

<div align="center">

```
   ██████╗██╗  ██╗ █████╗      ██████╗ ███████╗
  ██╔════╝██║  ██║██╔══██╗    ██╔═══██╗██╔════╝
  ██║     ███████║███████║    ██║   ██║███████╗
  ██║     ██╔══██║██╔══██║    ██║   ██║╚════██║
  ╚██████╗██║  ██║██║  ██║    ╚██████╔╝███████║
   ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝    ╚═════╝ ╚══════╝
```

**Minimal. Hızlı. Güçlü. Senin OS'un.**

![Build](https://github.com/tagchaos/chaOS/actions/workflows/build-iso.yml/badge.svg)
![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Based On](https://img.shields.io/badge/based%20on-Alpine%20Linux-0D597F)
![License](https://img.shields.io/badge/license-MIT-green)

</div>

---

## 🌟 Nedir?

**CHA OS**, Alpine Linux tabanlı, tam özelleştirilebilir, minimal bir işletim sistemidir.
Hem hafif makinelerde sorunsuz bir deneyim, hem de güçlü makinelerde üstün başarı sağlamak
üzere tasarlanmıştır.

## ✨ Özellikler

| Özellik | Açıklama |
|---------|----------|
| 🪶 **Ultra Hafif** | Alpine minirootfs tabanlı, ~200MB temel boyut |
| ⚡ **Hızlı Açılış** | Özelleştirilmiş chaos-lts kernel ile <5 saniye |
| 🎨 **Tam Özelleştirme** | Özel GRUB teması, ikon paketi, wallpaper |
| 🖥️ **Masaüstü Seçimi** | XFCE, LXQt, Openbox, i3/Sway, KDE Plasma |
| 🛠️ **cha-setup** | Kolay TUI kurulum sihirbazı |
| 📦 **apk** | Alpine'ın hızlı paket yöneticisi |

## 🖥️ Sistem Gereksinimleri

| | Minimum | Önerilen |
|--|---------|----------|
| **RAM** | 512MB (CLI) / 1GB (DE) | 2GB+ |
| **Disk** | 4GB | 10GB+ |
| **İşlemci** | x86_64 | x86_64, herhangi bir hız |
| **Boot** | BIOS veya UEFI | UEFI |

## 📥 Kurulum

### 1. ISO'yu İndir
[Releases](https://github.com/tagchaos/chaOS/releases) sayfasından en son ISO'yu indir.

### 2. USB'ye Yaz
```bash
# Linux
sudo dd if=chaOS-1.0.0-x86_64.iso of=/dev/sdX bs=4M status=progress

# Windows: Rufus veya balenaEtcher kullan
```

### 3. Kur
USB'den önyükle → `cha-setup` sihirbazını başlat → talimatları izle.

## 📂 Proje Yapısı

```
chaOS/
├── rootfs/                  # Temel sistem dosyaları
│   └── etc/                 # OS kimliği, MOTD
├── cha-setup/               # TUI kurulum sihirbazı
│   └── cha-setup.sh         # Ana kurulum betiği (dialog tabanlı)
├── chaOS-kernel/            # Özel kernel yapılandırması
│   └── chaos-kernel.config  # Hafifletilmiş kernel config
├── chaOS-branding/          # Görsel kimlik
│   ├── grub-theme/          # GRUB önyükleme teması
│   ├── wallpapers/          # Duvar kağıtları
│   ├── logos/               # CHA OS logoları
│   └── plymouth/            # Açılış animasyonu
├── chaOS-icons/             # Özel ikon paketi
├── scripts/                 # Build ve yardımcı betikler
│   ├── build-rootfs.sh
│   ├── build-iso.sh
│   └── cha-commands.sh      # cha-help, cha-info, cha-update
└── .github/workflows/       # GitHub Actions pipeline
    └── build-iso.yml
```

## 🔧 Geliştirme / Build

### Gereksinimler
```bash
apk add alpine-sdk squashfs-tools xorriso grub grub-efi mtools dosfstools bash
```

### ISO Oluştur
```bash
# Rootfs oluştur
sudo bash scripts/build-rootfs.sh --version 1.0.0 --arch x86_64

# ISO oluştur
sudo bash scripts/build-iso.sh 1.0.0 x86_64
```

### GitHub Actions ile Build
`main` branch'e push edildiğinde veya yeni bir tag oluşturulduğunda
otomatik olarak ISO derlenir ve Releases'e yüklenir.

```bash
git tag v1.0.0
git push origin v1.0.0
```

## 🎮 Özel Komutlar

| Komut | Açıklama |
|-------|----------|
| `cha-setup` | Kurulum sihirbazını başlat |
| `cha-info` | Sistem bilgilerini göster |
| `cha-update` | Sistemi güncelle |
| `cha-help` | Yardım menüsü |

## 🗺️ Yol Haritası

- [x] Proje yapısı ve MOTD
- [x] `cha-setup` TUI kurulum sihirbazı
- [x] Özel kernel yapılandırması
- [x] GRUB özel teması
- [x] GitHub Actions build pipeline
- [x] Özel `cha-*` komutları
- [ ] Özel ikon paketi (chaOS-icons)
- [ ] Plymouth açılış animasyonu
- [ ] Özel wallpaper seti
- [ ] chaOS-welcome (ilk açılış ekranı)
- [ ] Web sitesi

## 📄 Lisans

MIT © [tagchaos](https://github.com/tagchaos)

---

<div align="center">
<i>Alpine Linux'un değerini hissettiren, hafif makinelerde bile sorunsuz çalışan bir OS.</i>
</div>
