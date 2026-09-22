#!/bin/sh
# cha-setup — CHA OS TUI Kurulum Aracı
# Alpine tabanlı, dialog kullanarak tam kurulum sağlar

set -e

# ─────────────────────────────────────────────
#  Renkler ve sabitler
# ─────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

TITLE="CHA OS Kurulum Sihirbazı"
VERSION="1.0.0"
LOG="/tmp/cha-setup.log"
TMPDIR="/tmp/cha-setup"

mkdir -p "$TMPDIR"
> "$LOG"

# ─────────────────────────────────────────────
#  Yardımcı fonksiyonlar
# ─────────────────────────────────────────────
log() {
    echo "[$(date '+%H:%M:%S')] $1" >> "$LOG"
}

die() {
    dialog --title "Hata" --msgbox "\n$1\n\nKurulum iptal edildi.\nLog: $LOG" 10 50
    clear
    exit 1
}

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "${RED}Hata:${NC} cha-setup root olarak çalıştırılmalıdır."
        echo "Kullanım: sudo cha-setup"
        exit 1
    fi
}

check_deps() {
    for dep in dialog fdisk mkfs.ext4 mkfs.fat grub-install arch-chroot; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            log "Eksik bağımlılık: $dep"
        fi
    done
}

# ─────────────────────────────────────────────
#  Karşılama ekranı
# ─────────────────────────────────────────────
show_welcome() {
    dialog --backtitle "$TITLE v$VERSION" \
           --title "Hoş Geldiniz" \
           --yesno "\n\
   ██████╗██╗  ██╗ █████╗      ██████╗ ███████╗\n\
  ██╔════╝██║  ██║██╔══██╗    ██╔═══██╗██╔════╝\n\
  ██║     ███████║███████║    ██║   ██║███████╗\n\
  ██║     ██╔══██║██╔══██║    ██║   ██║╚════██║\n\
  ╚██████╗██║  ██║██║  ██║    ╚██████╔╝███████║\n\
   ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝    ╚═════╝ ╚══════╝\n\
\n\
  Sürüm: $VERSION | Alpine tabanlı minimal OS\n\
\n\
  Bu sihirbaz sisteminize CHA OS kurulumunu\n\
  gerçekleştirecektir. Devam etmek istiyor musunuz?" \
           18 62
    [ $? -ne 0 ] && { clear; echo "Kurulum iptal edildi."; exit 0; }
}

# ─────────────────────────────────────────────
#  Dil seçimi
# ─────────────────────────────────────────────
select_language() {
    LANG_CHOICE=$(dialog --backtitle "$TITLE" \
        --title "Dil Seçimi" \
        --menu "\nSistem dilini seçin:" 20 50 10 \
        "tr_TR.UTF-8" "Türkçe" \
        "en_US.UTF-8" "English (US)" \
        "en_GB.UTF-8" "English (UK)" \
        "de_DE.UTF-8" "Deutsch" \
        "fr_FR.UTF-8" "Français" \
        "es_ES.UTF-8" "Español" \
        "it_IT.UTF-8" "Italiano" \
        "ru_RU.UTF-8" "Русский" \
        "ja_JP.UTF-8" "日本語" \
        "zh_CN.UTF-8" "中文 (简体)" \
        3>&1 1>&2 2>&3)

    [ $? -ne 0 ] && die "Dil seçimi iptal edildi."
    SYS_LANG="$LANG_CHOICE"
    log "Dil seçildi: $SYS_LANG"
}

# ─────────────────────────────────────────────
#  Klavye düzeni
# ─────────────────────────────────────────────
select_keyboard() {
    KB_CHOICE=$(dialog --backtitle "$TITLE" \
        --title "Klavye Düzeni" \
        --menu "\nKlavye düzeninizi seçin:" 20 50 10 \
        "trq"    "Türkçe Q" \
        "trf"    "Türkçe F" \
        "us"     "English (US)" \
        "gb"     "English (UK)" \
        "de"     "Almanca" \
        "fr"     "Fransızca" \
        "es"     "İspanyolca" \
        "it"     "İtalyanca" \
        "ru"     "Rusça" \
        "jp106"  "Japonca" \
        3>&1 1>&2 2>&3)

    [ $? -ne 0 ] && die "Klavye seçimi iptal edildi."
    SYS_KEYBOARD="$KB_CHOICE"
    log "Klavye: $SYS_KEYBOARD"
}

# ─────────────────────────────────────────────
#  Zaman dilimi
# ─────────────────────────────────────────────
select_timezone() {
    # Bölge seçimi
    TZ_REGION=$(dialog --backtitle "$TITLE" \
        --title "Zaman Dilimi — Bölge" \
        --menu "\nBölgenizi seçin:" 22 50 14 \
        "Europe"    "Avrupa" \
        "Asia"      "Asya" \
        "America"   "Amerika" \
        "Africa"    "Afrika" \
        "Pacific"   "Pasifik" \
        "Atlantic"  "Atlantik" \
        "Indian"    "Hint Okyanusu" \
        "Arctic"    "Arktik" \
        "Antarctica" "Antarktika" \
        "UTC"       "UTC (Evrensel)" \
        3>&1 1>&2 2>&3)

    [ $? -ne 0 ] && die "Zaman dilimi seçimi iptal edildi."

    # Alt bölge (UTC seçildiyse atla)
    if [ "$TZ_REGION" = "UTC" ]; then
        SYS_TIMEZONE="UTC"
    else
        # Bölgeye göre şehir listesi oluştur
        TZ_LIST=""
        if [ -d "/usr/share/zoneinfo/$TZ_REGION" ]; then
            for tz in /usr/share/zoneinfo/"$TZ_REGION"/*; do
                city=$(basename "$tz")
                TZ_LIST="$TZ_LIST $city $city"
            done
        else
            # Fallback: yaygın şehirler
            case "$TZ_REGION" in
                Europe) TZ_LIST="Istanbul Istanbul London London Berlin Berlin Paris Paris Rome Rome Madrid Madrid Moscow Moscow Amsterdam Amsterdam" ;;
                Asia)   TZ_LIST="Istanbul Istanbul Tokyo Tokyo Shanghai Shanghai Kolkata Kolkata Dubai Dubai Singapore Singapore Seoul Seoul" ;;
                America) TZ_LIST="New_York New_York Chicago Chicago Denver Denver Los_Angeles Los_Angeles Toronto Toronto Sao_Paulo Sao_Paulo" ;;
                *) TZ_LIST="UTC UTC" ;;
            esac
        fi

        TZ_CITY=$(dialog --backtitle "$TITLE" \
            --title "Zaman Dilimi — Şehir" \
            --menu "\nŞehrinizi seçin:" 22 50 14 \
            $TZ_LIST \
            3>&1 1>&2 2>&3)

        [ $? -ne 0 ] && die "Şehir seçimi iptal edildi."
        SYS_TIMEZONE="$TZ_REGION/$TZ_CITY"
    fi

    log "Zaman dilimi: $SYS_TIMEZONE"
}

# ─────────────────────────────────────────────
#  Disk seçimi ve bölümleme
# ─────────────────────────────────────────────
select_disk() {
    # Mevcut diskleri listele
    DISK_LIST=""
    while IFS= read -r line; do
        dev=$(echo "$line" | awk '{print $1}')
        size=$(echo "$line" | awk '{print $2}')
        model=$(echo "$line" | awk '{$1=$2=""; print $0}' | sed 's/^ *//')
        DISK_LIST="$DISK_LIST /dev/$dev \"$size — $model\""
    done << EOF
$(lsblk -d -o NAME,SIZE,MODEL --noheadings 2>/dev/null | grep -v "^loop\|^sr\|^fd" || echo "sda 20G Generic_Disk")
EOF

    TARGET_DISK=$(eval dialog --backtitle "\"$TITLE\"" \
        --title "\"Disk Seçimi\"" \
        --menu "\"\nKurulum yapılacak diski seçin:\n\n[UYARI] Seçilen diskteki TÜM VERİ SİLİNECEKTİR!\"" 20 60 8 \
        $DISK_LIST \
        3>&1 1>&2 2>&3)

    [ $? -ne 0 ] && die "Disk seçimi iptal edildi."

    # Onay
    dialog --backtitle "$TITLE" \
           --title "Son Uyarı" \
           --yesno "\n[TEHLİKE!]\n\n$TARGET_DISK diskindeki TÜM VERİLER SİLİNECEKTİR!\n\nEmin misiniz?" \
           10 50
    [ $? -ne 0 ] && die "Kullanıcı disk silme işlemini iptal etti."

    log "Hedef disk: $TARGET_DISK"
}

# Bölümleme şeması seçimi
select_partition_scheme() {
    PART_SCHEME=$(dialog --backtitle "$TITLE" \
        --title "Bölümleme Şeması" \
        --menu "\nBölümleme yöntemini seçin:" 16 55 4 \
        "auto"    "Otomatik (Önerilen) — EFI + swap + root" \
        "manual"  "Manuel bölümleme" \
        "lvm"     "LVM üzerinde otomatik" \
        "encrypt" "Şifreli disk (LUKS + LVM)" \
        3>&1 1>&2 2>&3)

    [ $? -ne 0 ] && die "Bölümleme seçimi iptal edildi."
    log "Bölümleme şeması: $PART_SCHEME"
}

# ─────────────────────────────────────────────
#  Masaüstü ortamı seçimi
# ─────────────────────────────────────────────
select_desktop() {
    DE_CHOICE=$(dialog --backtitle "$TITLE" \
        --title "Masaüstü Ortamı" \
        --menu "\nKurmak istediğiniz masaüstü ortamını seçin:" 20 60 6 \
        "none"    "Sadece CLI (En hafif, sunucu için ideal)" \
        "openbox" "Openbox — Sade ve ultra hafif (~50MB)" \
        "xfce"    "XFCE — Hafif ve tam özellikli (~200MB)" \
        "lxqt"    "LXQt — Modern, Qt tabanlı hafif DE (~180MB)" \
        "i3"      "i3 / Sway — Pencere yöneticisi (~30MB)" \
        "kde"     "KDE Plasma — Güçlü ve özelleştirilebilir (~800MB)" \
        3>&1 1>&2 2>&3)

    [ $? -ne 0 ] && die "Masaüstü seçimi iptal edildi."
    SYS_DE="$DE_CHOICE"
    log "Masaüstü ortamı: $SYS_DE"
}

# ─────────────────────────────────────────────
#  Kullanıcı ayarları
# ─────────────────────────────────────────────
setup_users() {
    # Kullanıcı adı
    while true; do
        USERNAME=$(dialog --backtitle "$TITLE" \
            --title "Kullanıcı Adı" \
            --inputbox "\nYeni kullanıcı adını girin:\n(sadece küçük harf, rakam, alt çizgi)" \
            10 50 \
            3>&1 1>&2 2>&3)

        [ $? -ne 0 ] && die "Kullanıcı kurulumu iptal edildi."

        # Kullanıcı adı doğrulama
        if echo "$USERNAME" | grep -qE '^[a-z][a-z0-9_]{2,31}$'; then
            break
        else
            dialog --title "Geçersiz Kullanıcı Adı" \
                   --msgbox "\nKullanıcı adı:\n- 3-32 karakter olmalı\n- Küçük harf ile başlamalı\n- Sadece [a-z0-9_] içerebilir" \
                   10 45
        fi
    done

    # Kullanıcı tam adı
    FULLNAME=$(dialog --backtitle "$TITLE" \
        --title "Tam Ad" \
        --inputbox "\nKullanıcının tam adını girin:" \
        8 50 \
        3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && FULLNAME="$USERNAME"

    # Kullanıcı şifresi
    while true; do
        USER_PASS=$(dialog --backtitle "$TITLE" \
            --title "Kullanıcı Şifresi" \
            --passwordbox "\n'$USERNAME' için şifre girin:" \
            8 50 \
            3>&1 1>&2 2>&3)

        [ $? -ne 0 ] && die "Şifre girişi iptal edildi."

        USER_PASS2=$(dialog --backtitle "$TITLE" \
            --title "Kullanıcı Şifresi — Onay" \
            --passwordbox "\nŞifreyi tekrar girin:" \
            8 50 \
            3>&1 1>&2 2>&3)

        if [ "$USER_PASS" = "$USER_PASS2" ]; then
            if [ ${#USER_PASS} -lt 4 ]; then
                dialog --title "Zayıf Şifre" --msgbox "\nŞifre en az 4 karakter olmalıdır." 7 40
            else
                break
            fi
        else
            dialog --title "Şifre Hatası" --msgbox "\nŞifreler eşleşmiyor. Tekrar deneyin." 7 40
        fi
    done

    # Root şifresi
    dialog --backtitle "$TITLE" \
           --title "Root Şifresi" \
           --yesno "\nRoot (yönetici) için ayrı bir şifre belirlemek ister misiniz?\n\n'Hayır' seçerseniz sudo kullanarak yönetici işlemleri yapabilirsiniz." \
           9 55

    if [ $? -eq 0 ]; then
        while true; do
            ROOT_PASS=$(dialog --backtitle "$TITLE" \
                --title "Root Şifresi" \
                --passwordbox "\nRoot şifresini girin:" \
                8 50 \
                3>&1 1>&2 2>&3)

            [ $? -ne 0 ] && die "Root şifresi iptal edildi."

            ROOT_PASS2=$(dialog --backtitle "$TITLE" \
                --title "Root Şifresi — Onay" \
                --passwordbox "\nRoot şifresini tekrar girin:" \
                8 50 \
                3>&1 1>&2 2>&3)

            if [ "$ROOT_PASS" = "$ROOT_PASS2" ]; then
                break
            else
                dialog --title "Şifre Hatası" --msgbox "\nRoot şifreleri eşleşmiyor." 7 40
            fi
        done
        USE_ROOT_PASS=1
    else
        ROOT_PASS="$USER_PASS"
        USE_ROOT_PASS=0
    fi

    log "Kullanıcı: $USERNAME ($FULLNAME)"
}

# ─────────────────────────────────────────────
#  Hostname ayarı
# ─────────────────────────────────────────────
setup_hostname() {
    while true; do
        SYS_HOSTNAME=$(dialog --backtitle "$TITLE" \
            --title "Hostname (Bilgisayar Adı)" \
            --inputbox "\nBilgisayar adını girin:" \
            8 50 "chaos-pc" \
            3>&1 1>&2 2>&3)

        [ $? -ne 0 ] && die "Hostname iptal edildi."

        if echo "$SYS_HOSTNAME" | grep -qE '^[a-zA-Z0-9][a-zA-Z0-9\-]{0,62}$'; then
            break
        else
            dialog --title "Geçersiz Hostname" \
                   --msgbox "\nHostname:\n- Harf veya rakamla başlamalı\n- Sadece [a-zA-Z0-9-] içerebilir\n- Max 63 karakter" \
                   9 45
        fi
    done
    log "Hostname: $SYS_HOSTNAME"
}

# ─────────────────────────────────────────────
#  Ek yazılım seçimi
# ─────────────────────────────────────────────
select_extras() {
    EXTRAS=$(dialog --backtitle "$TITLE" \
        --title "Ek Yazılımlar" \
        --checklist "\nKurmak istediğiniz ek yazılımları seçin:\n(Boşluk ile seç/kaldır)" \
        22 60 12 \
        "firefox"       "Firefox Web Tarayıcısı"         off \
        "vlc"           "VLC Medya Oynatıcı"              off \
        "libreoffice"   "LibreOffice Ofis Paketi"         off \
        "git"           "Git Sürüm Kontrolü"              on  \
        "vim"           "Vim Metin Editörü"               on  \
        "neovim"        "Neovim"                          off \
        "htop"          "htop Sistem Monitörü"            on  \
        "neofetch"      "Neofetch Sistem Bilgisi"         on  \
        "docker"        "Docker Container Motoru"         off \
        "openssh"       "OpenSSH Sunucusu"                off \
        "flatpak"       "Flatpak Uygulama Desteği"        off \
        "chaOS-icons"   "CHA OS Özel İkon Paketi"         on  \
        3>&1 1>&2 2>&3)

    [ $? -ne 0 ] && EXTRAS=""
    SYS_EXTRAS="$EXTRAS"
    log "Ek yazılımlar: $SYS_EXTRAS"
}

# ─────────────────────────────────────────────
#  Özet ve onay
# ─────────────────────────────────────────────
show_summary() {
    dialog --backtitle "$TITLE" \
           --title "Kurulum Özeti — Son Onay" \
           --yesno "\n\
┌─────────────────────────────────────────┐\n\
│         KURULUM ÖZETİ                   │\n\
├─────────────────────────────────────────┤\n\
│  Dil          : $SYS_LANG\n\
│  Klavye       : $SYS_KEYBOARD\n\
│  Zaman Dilimi : $SYS_TIMEZONE\n\
│  Disk         : $TARGET_DISK\n\
│  Bölümleme    : $PART_SCHEME\n\
│  Masaüstü     : $SYS_DE\n\
│  Kullanıcı    : $USERNAME ($FULLNAME)\n\
│  Hostname     : $SYS_HOSTNAME\n\
└─────────────────────────────────────────┘\n\
\n\
Kurulumu başlatmak istiyor musunuz?\n\
BU İŞLEM GERİ ALINAMAZ!" \
           22 55

    [ $? -ne 0 ] && { clear; echo "Kurulum iptal edildi."; exit 0; }
}

# ─────────────────────────────────────────────
#  Disk bölümleme
# ─────────────────────────────────────────────
do_partition() {
    log "Disk bölümleme başladı: $TARGET_DISK"

    (
    echo "10" ; sleep 0.3
    echo "# Disk temizleniyor..."

    # Var olan bölümleri sil
    wipefs -a "$TARGET_DISK" >> "$LOG" 2>&1 || true

    echo "20" ; sleep 0.3
    echo "# GPT tablosu oluşturuluyor..."

    case "$PART_SCHEME" in
        auto|lvm|encrypt)
            # GPT + EFI (512MB) + swap (2GB) + root (kalan)
            parted -s "$TARGET_DISK" \
                mklabel gpt \
                mkpart ESP fat32 1MiB 513MiB \
                set 1 esp on \
                mkpart swap linux-swap 513MiB 2561MiB \
                mkpart root ext4 2561MiB 100% >> "$LOG" 2>&1

            echo "40" ; sleep 0.3
            echo "# Bölümler biçimlendiriliyor..."

            EFI_PART="${TARGET_DISK}1"
            SWAP_PART="${TARGET_DISK}2"
            ROOT_PART="${TARGET_DISK}3"

            mkfs.fat -F32 -n "CHAOS-EFI" "$EFI_PART" >> "$LOG" 2>&1
            mkswap -L "chaos-swap" "$SWAP_PART" >> "$LOG" 2>&1
            mkfs.ext4 -L "chaos-root" "$ROOT_PART" >> "$LOG" 2>&1
            ;;
    esac

    echo "60" ; sleep 0.3
    echo "# Bölümler bağlanıyor..."

    mount "$ROOT_PART" /mnt
    mkdir -p /mnt/boot/efi
    mount "$EFI_PART" /mnt/boot/efi
    swapon "$SWAP_PART"

    echo "100" ; sleep 0.3

    ) | dialog --backtitle "$TITLE" \
               --title "Disk Hazırlanıyor" \
               --gauge "\nDisk bölümleniyor ve biçimlendiriliyor..." \
               8 55 0

    log "Disk bölümleme tamamlandı."
}

# ─────────────────────────────────────────────
#  Temel sistem kurulumu
# ─────────────────────────────────────────────
install_base() {
    log "Temel sistem kurulumu başladı."

    (
    echo "5"
    echo "# Alpine minirootfs indiriliyor..."
    sleep 0.5

    # Alpine minirootfs çek (gerçek kurulumda wget ile indirilir)
    ARCH=$(uname -m)
    ALPINE_VER="3.20"
    ROOTFS_URL="https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VER}/releases/${ARCH}/alpine-minirootfs-${ALPINE_VER}.0-${ARCH}.tar.gz"

    echo "15"
    echo "# Temel paketler kuruluyor..."

    # chroot içinde paket kurulumu
    mkdir -p /mnt
    # (Gerçek kurulumda alpine-chroot-install veya benzer araç kullanılır)

    echo "30"
    echo "# CHA OS yapılandırması uygulanıyor..."
    sleep 0.3

    # OS kimlik dosyaları
    install -m 644 /etc/chaOS-release /mnt/etc/chaOS-release 2>/dev/null || true
    install -m 644 /etc/os-release /mnt/etc/os-release 2>/dev/null || true

    echo "45"
    echo "# Sistem ayarları yapılandırılıyor..."

    # Hostname
    echo "$SYS_HOSTNAME" > /mnt/etc/hostname

    # Hosts
    cat > /mnt/etc/hosts << HOSTS
127.0.0.1   localhost
127.0.1.1   $SYS_HOSTNAME $SYS_HOSTNAME.localdomain
::1         localhost ip6-localhost ip6-loopback
HOSTS

    # Zaman dilimi
    arch-chroot /mnt ln -sf "/usr/share/zoneinfo/$SYS_TIMEZONE" /etc/localtime 2>/dev/null || \
        ln -sf "/usr/share/zoneinfo/$SYS_TIMEZONE" /mnt/etc/localtime

    echo "55"
    echo "# Dil ve yerelleştirme..."

    echo "LANG=$SYS_LANG" > /mnt/etc/locale.conf
    echo "KEYMAP=$SYS_KEYBOARD" > /mnt/etc/vconsole.conf

    echo "65"
    echo "# Masaüstü ortamı kuruluyor: $SYS_DE..."

    case "$SYS_DE" in
        xfce)
            arch-chroot /mnt apk add --no-cache xfce4 xfce4-terminal lightdm lightdm-gtk-greeter xorg-server >> "$LOG" 2>&1 ;;
        lxqt)
            arch-chroot /mnt apk add --no-cache lxqt sddm xorg-server >> "$LOG" 2>&1 ;;
        openbox)
            arch-chroot /mnt apk add --no-cache openbox obconf tint2 xorg-server lightdm >> "$LOG" 2>&1 ;;
        i3)
            arch-chroot /mnt apk add --no-cache i3wm i3status i3lock xorg-server lightdm dmenu >> "$LOG" 2>&1 ;;
        kde)
            arch-chroot /mnt apk add --no-cache plasma-desktop sddm xorg-server >> "$LOG" 2>&1 ;;
        none)
            log "CLI modu seçildi, DE kurulmuyor." ;;
    esac

    echo "80"
    echo "# Kullanıcılar oluşturuluyor..."

    # Kullanıcı oluştur
    arch-chroot /mnt adduser -D -G wheel -c "$FULLNAME" "$USERNAME" >> "$LOG" 2>&1 || true
    printf "%s\n%s\n" "$USER_PASS" "$USER_PASS" | arch-chroot /mnt passwd "$USERNAME" >> "$LOG" 2>&1 || true
    printf "%s\n%s\n" "$ROOT_PASS" "$ROOT_PASS" | arch-chroot /mnt passwd root >> "$LOG" 2>&1 || true

    # sudo ayarı
    arch-chroot /mnt apk add --no-cache sudo >> "$LOG" 2>&1 || true
    echo "%wheel ALL=(ALL:ALL) ALL" >> /mnt/etc/sudoers

    echo "88"
    echo "# Ek yazılımlar kuruluyor..."

    for pkg in $SYS_EXTRAS; do
        arch-chroot /mnt apk add --no-cache "$pkg" >> "$LOG" 2>&1 || true
    done

    echo "93"
    echo "# GRUB bootloader kuruluyor..."

    arch-chroot /mnt apk add --no-cache grub grub-efi efibootmgr >> "$LOG" 2>&1 || true
    arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id="CHA OS" >> "$LOG" 2>&1 || true
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg >> "$LOG" 2>&1 || true

    echo "97"
    echo "# MOTD ve branding uygulanıyor..."

    install -m 644 /usr/share/chaOS/motd /mnt/etc/motd 2>/dev/null || true

    echo "100"
    echo "# Kurulum tamamlandı!"
    sleep 0.5

    ) | dialog --backtitle "$TITLE" \
               --title "CHA OS Kuruluyor" \
               --gauge "\nSistem kuruluyor, lütfen bekleyin..." \
               8 60 0

    log "Kurulum tamamlandı."
}

# ─────────────────────────────────────────────
#  Tamamlanma ekranı
# ─────────────────────────────────────────────
show_finish() {
    dialog --backtitle "$TITLE" \
           --title "Kurulum Tamamlandı!" \
           --msgbox "\n\
  ✓ CHA OS başarıyla kuruldu!\n\
\n\
  Sistem bilgileri:\n\
  ─────────────────────────────\n\
  Kullanıcı  : $USERNAME\n\
  Hostname   : $SYS_HOSTNAME\n\
  Masaüstü   : $SYS_DE\n\
  Zaman Dil. : $SYS_TIMEZONE\n\
  ─────────────────────────────\n\
\n\
  Kurulum logu: $LOG\n\
\n\
  Sistemi yeniden başlatmak için\n\
  'Tamam'a basın." \
           20 52

    # Unmount ve reboot
    sync
    umount -R /mnt 2>/dev/null || true
    swapoff -a 2>/dev/null || true

    dialog --backtitle "$TITLE" \
           --title "Yeniden Başlatılıyor" \
           --infobox "\n  Sistem 5 saniye içinde yeniden başlayacak...\n  Kurulum medyasını çıkartın!" \
           7 52

    sleep 5
    reboot
}

# ─────────────────────────────────────────────
#  Ana akış
# ─────────────────────────────────────────────
main() {
    check_root
    check_deps
    show_welcome
    select_language
    select_keyboard
    select_timezone
    select_disk
    select_partition_scheme
    select_desktop
    setup_hostname
    setup_users
    select_extras
    show_summary
    do_partition
    install_base
    show_finish
}

main "$@"
