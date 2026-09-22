#!/bin/sh
# CHA OS özel komutlar — cha-help / cha-info / cha-update

CMD=$(basename "$0")

# Renkler
R='\033[0;31m' G='\033[0;32m' B='\033[0;34m'
C='\033[0;36m' Y='\033[0;33m' W='\033[1;37m' N='\033[0m'

chaos_banner() {
    printf "${B}"
    printf "  ██████╗██╗  ██╗ █████╗      ██████╗ ███████╗\n"
    printf " ██╔════╝██║  ██║██╔══██╗    ██╔═══██╗██╔════╝\n"
    printf " ██║     ███████║███████║    ██║   ██║███████╗\n"
    printf " ██║     ██╔══██║██╔══██║    ██║   ██║╚════██║\n"
    printf " ╚██████╗██║  ██║██║  ██║    ╚██████╔╝███████║\n"
    printf "  ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝    ╚═════╝ ╚══════╝${N}\n"
    printf "\n"
}

# ─── cha-help ─────────────────────────────────
cmd_help() {
    chaos_banner
    printf "${W}  CHA OS — Komut Yardımı${N}\n\n"

    printf "${C}  Sistem Komutları:${N}\n"
    printf "  ${G}cha-setup${N}    — Kurulum sihirbazını başlat\n"
    printf "  ${G}cha-info${N}     — Sistem bilgilerini göster\n"
    printf "  ${G}cha-update${N}   — Sistemi güncelle\n"
    printf "  ${G}cha-help${N}     — Bu yardım menüsü\n\n"

    printf "${C}  Paket Yönetimi (Alpine apk):${N}\n"
    printf "  ${G}apk update${N}           — Depoları güncelle\n"
    printf "  ${G}apk add <paket>${N}      — Paket kur\n"
    printf "  ${G}apk del <paket>${N}      — Paket kaldır\n"
    printf "  ${G}apk search <ad>${N}      — Paket ara\n"
    printf "  ${G}apk info${N}             — Kurulu paketler\n\n"

    printf "${C}  Servis Yönetimi (OpenRC):${N}\n"
    printf "  ${G}rc-service <ad> start${N}     — Servis başlat\n"
    printf "  ${G}rc-service <ad> stop${N}      — Servis durdur\n"
    printf "  ${G}rc-update add <ad> default${N} — Servisi etkinleştir\n\n"

    printf "${C}  Ağ:${N}\n"
    printf "  ${G}nmcli device wifi list${N}    — Wi-Fi listesi\n"
    printf "  ${G}nmcli device wifi connect${N} — Wi-Fi'ye bağlan\n\n"

    printf "  ${Y}Daha fazla bilgi: https://github.com/tagchaos/chaOS${N}\n\n"
}

# ─── cha-info ─────────────────────────────────
cmd_info() {
    chaos_banner

    CHAOS_VER=$(cat /etc/chaOS-version 2>/dev/null || echo "1.0.0")
    KERNEL_VER=$(uname -r)
    UPTIME=$(uptime -p 2>/dev/null || uptime)
    HOSTNAME=$(hostname)
    ARCH=$(uname -m)
    CPU=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | sed 's/^ *//' || echo "Bilinmiyor")
    RAM_TOTAL=$(awk '/MemTotal/ {printf "%.0fMB", $2/1024}' /proc/meminfo)
    RAM_FREE=$(awk '/MemAvailable/ {printf "%.0fMB", $2/1024}' /proc/meminfo)
    DISK=$(df -h / 2>/dev/null | awk 'NR==2{print $3"/"$2" ("$5" kullanımda)"}' || echo "N/A")
    SHELL_NAME=$(basename "$SHELL")
    DE="${XDG_CURRENT_DESKTOP:-CLI}"

    printf "${W}  ┌──────────────── Sistem Bilgisi ────────────────┐${N}\n"
    printf "${W}  │${N}  %-18s ${C}%-28s${N} ${W}│${N}\n" "OS:"       "CHA OS $CHAOS_VER"
    printf "${W}  │${N}  %-18s ${C}%-28s${N} ${W}│${N}\n" "Kernel:"   "$KERNEL_VER"
    printf "${W}  │${N}  %-18s ${C}%-28s${N} ${W}│${N}\n" "Mimari:"   "$ARCH"
    printf "${W}  │${N}  %-18s ${C}%-28s${N} ${W}│${N}\n" "Hostname:" "$HOSTNAME"
    printf "${W}  │${N}  %-18s ${C}%-28s${N} ${W}│${N}\n" "CPU:"      "$CPU"
    printf "${W}  │${N}  %-18s ${C}%-28s${N} ${W}│${N}\n" "RAM:"      "$RAM_FREE serbest / $RAM_TOTAL toplam"
    printf "${W}  │${N}  %-18s ${C}%-28s${N} ${W}│${N}\n" "Disk (/):" "$DISK"
    printf "${W}  │${N}  %-18s ${C}%-28s${N} ${W}│${N}\n" "Masaüstü:" "$DE"
    printf "${W}  │${N}  %-18s ${C}%-28s${N} ${W}│${N}\n" "Shell:"    "$SHELL_NAME"
    printf "${W}  │${N}  %-18s ${C}%-28s${N} ${W}│${N}\n" "Uptime:"   "$UPTIME"
    printf "${W}  └──────────────────────────────────────────────┘${N}\n\n"
}

# ─── cha-update ───────────────────────────────
cmd_update() {
    chaos_banner
    printf "${W}  CHA OS — Sistem Güncelleme${N}\n\n"

    # Root kontrolü
    if [ "$(id -u)" -ne 0 ]; then
        printf "  ${R}Hata:${N} Bu komut root yetkisi gerektirir.\n"
        printf "  Kullanım: ${G}sudo cha-update${N}\n\n"
        exit 1
    fi

    printf "  ${C}[1/3]${N} Depolar güncelleniyor...\n"
    apk update 2>&1 | sed 's/^/         /'

    printf "\n  ${C}[2/3]${N} Yükseltmeler kontrol ediliyor...\n"
    UPGRADABLE=$(apk version -l '<' 2>/dev/null | grep -c '<' || echo 0)

    if [ "$UPGRADABLE" -eq 0 ]; then
        printf "  ${G}✓${N} Sistem güncel! Yükseltme gerekmiyor.\n\n"
    else
        printf "  ${Y}!${N} $UPGRADABLE paket güncellenecek.\n\n"
        apk upgrade 2>&1 | sed 's/^/         /'
    fi

    printf "\n  ${C}[3/3]${N} Önbellek temizleniyor...\n"
    apk cache clean 2>/dev/null || true

    printf "\n  ${G}✅ Güncelleme tamamlandı!${N}\n\n"
}

# ─── Komut yönlendirme ────────────────────────
case "$CMD" in
    cha-help)   cmd_help   ;;
    cha-info)   cmd_info   ;;
    cha-update) cmd_update ;;
    *)          cmd_help   ;;
esac
