#!/bin/bash

# 🌐 EasyTier Manager v2.0 - مشابه Easy-Mesh
# BMad Master - Inspired by Musixal/Easy-Mesh
# سریع، ساده، بدون پیچیدگی

set -e

# رنگ‌ها
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# مسیرها
CONFIG_DIR="/etc/easytier"
LOG_FILE="/var/log/easytier.log"
SERVICE_NAME="easytier"
EASYTIER_DIR="/usr/local/bin"
EASY_CLIENT="$EASYTIER_DIR/easytier-cli"

# =============================================================================
# توابع کمکی
# =============================================================================

colorize() {
    local color="$1"
    local text="$2"
    local style="${3:-normal}"

    case $color in
        red) echo -e "${RED}$text${NC}" ;;
        green) echo -e "${GREEN}$text${NC}" ;;
        yellow) echo -e "${YELLOW}$text${NC}" ;;
        blue) echo -e "${BLUE}$text${NC}" ;;
        cyan) echo -e "${CYAN}$text${NC}" ;;
        purple) echo -e "${PURPLE}$text${NC}" ;;
        white) echo -e "${WHITE}$text${NC}" ;;
        magenta) echo -e "${MAGENTA}$text${NC}" ;;
        *) echo -e "$text" ;;
    esac
}

press_key() {
    echo
    read -p "Press Enter to continue..."
}

# =============================================================================
# بررسی وضعیت core
# =============================================================================

check_core_status() {
    if [[ -f "$EASYTIER_DIR/easytier-core" ]] && [[ -f "$EASYTIER_DIR/easytier-cli" ]]; then
        colorize green "EasyTier Core Installed"
        return 0
    else
        colorize red "EasyTier Core not found"
        return 1
    fi
}

# =============================================================================
# تولید کلید تصادفی
# =============================================================================

generate_random_secret() {
    openssl rand -hex 6 2>/dev/null || echo "$(date +%s)$(shuf -i 1000-9999 -n 1)"
}

# =============================================================================
# 1. اتصال سریع به شبکه (مشابه Easy-Mesh)
# =============================================================================

quick_connect() {
    clear
    colorize cyan "🚀 Quick Connect to Mesh Network"
    echo
    colorize yellow "💡 Tips:
• Leave peer addresses blank for reverse mode
• UDP is more stable than TCP
• Default settings work for most cases"
    echo

    # IP عمومی خودکار
    PUBLIC_IP=$(curl -s ipinfo.io/ip 2>/dev/null || curl -s ifconfig.me 2>/dev/null || echo "Unknown")

    # پیشفرض‌های هوشمند
    DEFAULT_LOCAL_IP="10.144.144.$(shuf -i 2-254 -n 1)"
    DEFAULT_PORT="11011"
    DEFAULT_HOSTNAME="$(hostname)-$(date +%s | tail -c 4)"

    echo "📡 Your Public IP: $PUBLIC_IP"
    echo

    # ورودی‌ها با پیشفرض
    read -p "🌐 Peer Addresses (comma separated, or ENTER for reverse mode): " PEER_ADDRESSES

    read -p "🏠 Local IP [$DEFAULT_LOCAL_IP]: " IP_ADDRESS
    IP_ADDRESS=${IP_ADDRESS:-$DEFAULT_LOCAL_IP}

    read -p "🏷️  Hostname [$DEFAULT_HOSTNAME]: " HOSTNAME
    HOSTNAME=${HOSTNAME:-$DEFAULT_HOSTNAME}

    read -p "🔌 Port [$DEFAULT_PORT]: " PORT
    PORT=${PORT:-$DEFAULT_PORT}

    # تولید کلید خودکار
    NETWORK_SECRET=$(generate_random_secret)
    colorize cyan "🔑 Auto-generated secret: $NETWORK_SECRET"
    read -p "🔐 Network Secret [$NETWORK_SECRET]: " USER_SECRET
    NETWORK_SECRET=${USER_SECRET:-$NETWORK_SECRET}

    # پروتکل پیشفرض UDP
    colorize green "🔗 Select Protocol:"
    echo "1) UDP (Recommended)"
    echo "2) TCP"
    echo "3) WebSocket"
    read -p "Protocol [1]: " PROTOCOL_CHOICE

    case ${PROTOCOL_CHOICE:-1} in
        1) DEFAULT_PROTOCOL="udp" ;;
        2) DEFAULT_PROTOCOL="tcp" ;;
        3) DEFAULT_PROTOCOL="ws" ;;
        *) DEFAULT_PROTOCOL="udp" ;;
    esac

    # تنظیمات اضافی با پیشفرض
    ENCRYPTION_OPTION=""  # پیشفرض: فعال
    MULTI_THREAD="--multi-thread"  # پیشفرض: فعال
    IPV6_MODE="--disable-ipv6"     # پیشفرض: غیرفعال

    # پردازش آدرس‌های peer
    PEER_ADDRESS=""
    if [[ -n "$PEER_ADDRESSES" ]]; then
        IFS=',' read -ra ADDR_ARRAY <<< "$PEER_ADDRESSES"
        PROCESSED_ADDRESSES=()
        for ADDRESS in "${ADDR_ARRAY[@]}"; do
            ADDRESS=$(echo $ADDRESS | xargs)
            if [[ -n "$ADDRESS" ]]; then
                # اضافه کردن پورت اگر وجود ندارد
                if [[ "$ADDRESS" != *:* ]]; then
                    ADDRESS="$ADDRESS:$PORT"
                fi
                PROCESSED_ADDRESSES+=("${DEFAULT_PROTOCOL}://${ADDRESS}")
            fi
        done
        JOINED_ADDRESSES=$(IFS=' '; echo "${PROCESSED_ADDRESSES[*]}")
        PEER_ADDRESS="--peers ${JOINED_ADDRESSES}"
    fi

    LISTENERS="--listeners ${DEFAULT_PROTOCOL}://[::]:${PORT} ${DEFAULT_PROTOCOL}://0.0.0.0:${PORT}"

    # ایجاد سرویس
    SERVICE_FILE="/etc/systemd/system/easytier.service"

cat > $SERVICE_FILE <<EOF
[Unit]
Description=EasyTier Mesh Network Service
After=network.target

[Service]
Type=simple
ExecStart=$EASYTIER_DIR/easytier-core -i $IP_ADDRESS $PEER_ADDRESS --hostname $HOSTNAME --network-secret $NETWORK_SECRET --default-protocol $DEFAULT_PROTOCOL $LISTENERS $MULTI_THREAD $ENCRYPTION_OPTION $IPV6_MODE
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF

    # راه‌اندازی سرویس
    systemctl daemon-reload
    systemctl enable easytier.service
    systemctl start easytier.service

    echo
    colorize green "✅ EasyTier Network Service Started Successfully!"
    echo
    colorize cyan "📋 Connection Details:"
    echo "  🌐 Local IP: $IP_ADDRESS"
    echo "  🏷️  Hostname: $HOSTNAME"
    echo "  🔌 Port: $PORT"
    echo "  🔐 Secret: $NETWORK_SECRET"
    echo "  🔗 Protocol: $DEFAULT_PROTOCOL"
    echo "  📡 Public IP: $PUBLIC_IP"

    press_key
}

# =============================================================================
# 2. نمایش Peers
# =============================================================================

display_peers() {
    if ! command -v $EASY_CLIENT &> /dev/null; then
        colorize red "❌ easytier-cli not found"
        press_key
        return
    fi

    clear
    colorize cyan "👥 Live Peers Monitor (Ctrl+C to exit)"
    echo
    watch -n2 "$EASY_CLIENT peer"
}

# =============================================================================
# 3. نمایش Routes
# =============================================================================

display_routes() {
    if ! command -v $EASY_CLIENT &> /dev/null; then
        colorize red "❌ easytier-cli not found"
        press_key
        return
    fi

    clear
    colorize cyan "🛣️  Live Routes Monitor (Ctrl+C to exit)"
    echo
    watch -n2 "$EASY_CLIENT route"
}

# =============================================================================
# 4. Peer Center
# =============================================================================

peer_center() {
    if ! command -v $EASY_CLIENT &> /dev/null; then
        colorize red "❌ easytier-cli not found"
        press_key
        return
    fi

    clear
    colorize cyan "🎯 Peer Center Monitor (Ctrl+C to exit)"
    echo
    watch -n2 "$EASY_CLIENT peer-center"
}

# =============================================================================
# 5. نمایش کلید شبکه
# =============================================================================

show_network_secret() {
    echo
    if [[ -f "/etc/systemd/system/easytier.service" ]]; then
        NETWORK_SECRET=$(grep -oP '(?<=--network-secret )[^ ]+' /etc/systemd/system/easytier.service)

        if [[ -n $NETWORK_SECRET ]]; then
            colorize cyan "🔐 Network Secret Key: $NETWORK_SECRET"
        else
            colorize red "❌ Network Secret key not found"
        fi
    else
        colorize red "❌ EasyTier service does not exist"
    fi
    echo
    press_key
}

# =============================================================================
# 6. وضعیت سرویس
# =============================================================================

view_service_status() {
    if [[ ! -f "/etc/systemd/system/easytier.service" ]]; then
        colorize red "❌ EasyTier service does not exist"
        press_key
        return
    fi

    clear
    colorize cyan "📊 EasyTier Service Status"
    echo
    systemctl status easytier.service --no-pager -l
    echo
    press_key
}

# =============================================================================
# 7. ری‌استارت سرویس
# =============================================================================

restart_service() {
    echo
    if [[ ! -f "/etc/systemd/system/easytier.service" ]]; then
        colorize red "❌ EasyTier service does not exist"
        press_key
        return
    fi

    colorize yellow "🔄 Restarting EasyTier service..."
    if systemctl restart easytier.service; then
        colorize green "✅ EasyTier service restarted successfully"
    else
        colorize red "❌ Failed to restart EasyTier service"
    fi
    echo
    press_key
}

# =============================================================================
# 8. حذف سرویس
# =============================================================================

remove_service() {
    echo
    if [[ ! -f "/etc/systemd/system/easytier.service" ]]; then
        colorize red "❌ EasyTier service does not exist"
        press_key
        return
    fi

    colorize yellow "⚠️  Are you sure you want to remove EasyTier service? [y/N]: "
    read -r confirm

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        colorize blue "ℹ️  Operation cancelled"
        press_key
        return
    fi

    colorize yellow "🛑 Stopping EasyTier service..."
    systemctl stop easytier.service

    colorize yellow "🚫 Disabling EasyTier service..."
    systemctl disable easytier.service

    colorize yellow "🗑️  Removing service file..."
    rm -f /etc/systemd/system/easytier.service

    colorize yellow "🔄 Reloading systemd daemon..."
    systemctl daemon-reload

    colorize green "✅ EasyTier service removed successfully"
    press_key
}

# =============================================================================
# 9. Ping Test
# =============================================================================

ping_test() {
    echo
    read -p "🎯 Enter IP to ping (e.g., 10.144.144.1): " target_ip

    if [[ -z "$target_ip" ]]; then
        colorize red "❌ Invalid IP address"
        press_key
        return
    fi

    colorize cyan "🏓 Pinging $target_ip..."
    echo
    ping -c 5 "$target_ip" || colorize red "❌ Ping failed"

    press_key
}

# =============================================================================
# 10. منوی اصلی (مشابه Easy-Mesh)
# =============================================================================

display_menu() {
    clear
    # Header زیبا مشابه Easy-Mesh
    echo -e "   ${CYAN}╔════════════════════════════════════════╗"
    echo -e "   ║            🌐 ${WHITE}EasyTier Manager         ${CYAN}║"
    echo -e "   ║        ${WHITE}Simple Mesh Network Solution    ${CYAN}║"
    echo -e "   ╠════════════════════════════════════════╣"
    echo -e "   ║  ${WHITE}Version: 2.0 (BMad Master)           ${CYAN}║"
    echo -e "   ║  ${WHITE}GitHub: k4lantar4/moonmesh           ${CYAN}║"
    echo -e "   ╠════════════════════════════════════════╣${NC}"
    echo -e "   ║        $(check_core_status)         ║"
    echo -e "   ╚════════════════════════════════════════╝"

    echo
    colorize green "	[1] 🚀 Quick Connect to Network"
    colorize yellow "	[2] 👥 Display Peers"
    colorize cyan "	[3] 🛣️  Display Routes"
    colorize blue "	[4] 🎯 Peer-Center"
    colorize purple "	[5] 🔐 Display Secret Key"
    colorize white "	[6] 📊 View Service Status"
    colorize white "	[7] 🏓 Ping Test"
    colorize yellow "	[8] 🔄 Restart Service"
    colorize red "	[9] 🗑️  Remove Service"
    echo -e "	[0] 🚪 Exit"
    echo
}

# =============================================================================
# خواندن گزینه کاربر
# =============================================================================

read_option() {
    echo -e "\t-------------------------------"
    echo -en "\t${MAGENTA}Enter your choice: ${NC}"
    read -r choice
    case $choice in
        1) quick_connect ;;
        2) display_peers ;;
        3) display_routes ;;
        4) peer_center ;;
        5) show_network_secret ;;
        6) view_service_status ;;
        7) ping_test ;;
        8) restart_service ;;
        9) remove_service ;;
        0)
            colorize green "👋 Goodbye!"
            exit 0
            ;;
        *)
            colorize red "❌ Invalid option!"
            sleep 1
            ;;
    esac
}

# =============================================================================
# اجرای اصلی
# =============================================================================

# بررسی دسترسی root
if [[ $EUID -ne 0 ]]; then
    colorize red "❌ This script must be run as root"
    echo "Usage: sudo $0"
    exit 1
fi

# حلقه اصلی
while true; do
    display_menu
    read_option
done
