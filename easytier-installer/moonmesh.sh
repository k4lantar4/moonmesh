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
# دریافت IP عمومی با fallback بهتر
# =============================================================================

get_public_ip() {
    local ip=""

    # تلاش اول: ipinfo.io
    ip=$(timeout 5 curl -s ipinfo.io/ip 2>/dev/null | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' || echo "")

    if [[ -n "$ip" ]]; then
        echo "$ip"
        return
    fi

    # تلاش دوم: ifconfig.me
    ip=$(timeout 5 curl -s ifconfig.me 2>/dev/null | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' || echo "")

    if [[ -n "$ip" ]]; then
        echo "$ip"
        return
    fi

    # تلاش سوم: httpbin.org
    ip=$(timeout 5 curl -s httpbin.org/ip 2>/dev/null | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' || echo "")

    if [[ -n "$ip" ]]; then
        echo "$ip"
        return
    fi

    # fallback: IP محلی
    ip=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "Unknown")
    echo "$ip"
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

    # IP عمومی با fallback بهتر
    colorize yellow "🔍 Getting your public IP..."
    PUBLIC_IP=$(get_public_ip)

    # پیشفرض‌های جدید
    DEFAULT_LOCAL_IP="10.10.10.1"
    DEFAULT_PORT="1377"
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

    # سوال IPv6
    colorize blue "🌐 Enable IPv6?"
    echo "1) No (Recommended)"
    echo "2) Yes"
    read -p "IPv6 [1]: " IPV6_CHOICE

    case ${IPV6_CHOICE:-1} in
        1) IPV6_MODE="--disable-ipv6" ;;
        2) IPV6_MODE="" ;;
        *) IPV6_MODE="--disable-ipv6" ;;
    esac

    # سوال Multi-thread
    colorize blue "⚡ Enable Multi-thread?"
    echo "1) Yes (Recommended)"
    echo "2) No"
    read -p "Multi-thread [1]: " MULTI_CHOICE

    case ${MULTI_CHOICE:-1} in
        1) MULTI_THREAD="--multi-thread" ;;
        2) MULTI_THREAD="" ;;
        *) MULTI_THREAD="--multi-thread" ;;
    esac

    # تنظیمات اضافی
    ENCRYPTION_OPTION=""  # پیشفرض: فعال

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
    echo "  ⚡ Multi-thread: $([ "$MULTI_THREAD" ] && echo "Enabled" || echo "Disabled")"
    echo "  🌐 IPv6: $([ "$IPV6_MODE" ] && echo "Disabled" || echo "Enabled")"

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
# 7. واچ داگ و پایداری (جدید)
# =============================================================================

watchdog_menu() {
    clear
    colorize purple "🐕 Watchdog & Stability Management"
    echo

    while true; do
        echo -e "${PURPLE}=== Watchdog Menu ===${NC}"
        echo "1) 🔧 Setup Watchdog (Auto-restart on failure)"
        echo "2) 📊 Check Service Health"
        echo "3) 🔄 Auto-restart Timer (Cron)"
        echo "4) 🧹 Clean Service Logs"
        echo "5) 📈 Performance Monitor"
        echo "6) 🚨 Service Alerts Setup"
        echo "7) 🛡️  Stability Optimization"
        echo "8) 🗑️  Remove Watchdog"
        echo "9) ⬅️  Back to Main Menu"
        echo
        read -p "Select [1-9]: " watchdog_choice

        case $watchdog_choice in
            1) setup_watchdog ;;
            2) check_service_health ;;
            3) setup_auto_restart ;;
            4) clean_service_logs ;;
            5) performance_monitor ;;
            6) setup_alerts ;;
            7) stability_optimization ;;
            8) remove_watchdog ;;
            9) return ;;
            *) colorize red "❌ Invalid option" ;;
        esac

        echo
    done
}

setup_watchdog() {
    colorize yellow "🔧 Setting up Watchdog..."

    # ایجاد اسکریپت watchdog
    cat > /usr/local/bin/easytier-watchdog.sh << 'EOF'
#!/bin/bash
# EasyTier Watchdog Script

SERVICE_NAME="easytier"
LOG_FILE="/var/log/easytier-watchdog.log"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

check_service() {
    if ! systemctl is-active --quiet "$SERVICE_NAME"; then
        log_message "Service $SERVICE_NAME is down, restarting..."
        systemctl restart "$SERVICE_NAME"
        sleep 5
        if systemctl is-active --quiet "$SERVICE_NAME"; then
            log_message "Service $SERVICE_NAME restarted successfully"
        else
            log_message "Failed to restart service $SERVICE_NAME"
        fi
    fi
}

# اجرای بررسی
check_service
EOF

    chmod +x /usr/local/bin/easytier-watchdog.sh

    # اضافه کردن به crontab
    (crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/easytier-watchdog.sh") | crontab -

    colorize green "✅ Watchdog setup completed! Checking every 5 minutes."
    press_key
}

check_service_health() {
    colorize cyan "📊 Service Health Check"
    echo

    # بررسی وضعیت سرویس
    if systemctl is-active --quiet easytier; then
        colorize green "✅ Service Status: Active"
    else
        colorize red "❌ Service Status: Inactive"
    fi

    # بررسی فرآیند
    if pgrep -f easytier-core > /dev/null; then
        colorize green "✅ Process: Running"
        echo "   PID: $(pgrep -f easytier-core)"
    else
        colorize red "❌ Process: Not running"
    fi

    # بررسی پورت
    if netstat -tuln 2>/dev/null | grep -q ":1377 "; then
        colorize green "✅ Port 1377: Listening"
    else
        colorize yellow "⚠️  Port 1377: Not listening"
    fi

    # بررسی memory usage
    if command -v ps &> /dev/null; then
        MEM_USAGE=$(ps aux | grep easytier-core | grep -v grep | awk '{print $4}' | head -1)
        if [[ -n "$MEM_USAGE" ]]; then
            colorize cyan "📊 Memory Usage: ${MEM_USAGE}%"
        fi
    fi

    press_key
}

setup_auto_restart() {
    colorize yellow "🔄 Setting up Auto-restart Timer"
    echo
    echo "Select restart interval:"
    echo "1) Every 6 hours"
    echo "2) Every 12 hours"
    echo "3) Daily (3 AM)"
    echo "4) Weekly (Sunday 3 AM)"
    read -p "Select [1-4]: " interval_choice

    case $interval_choice in
        1) CRON_TIME="0 */6 * * *" ;;
        2) CRON_TIME="0 */12 * * *" ;;
        3) CRON_TIME="0 3 * * *" ;;
        4) CRON_TIME="0 3 * * 0" ;;
        *) colorize red "Invalid choice"; return ;;
    esac

    # حذف cron قدیمی
    crontab -l 2>/dev/null | grep -v "systemctl restart easytier" | crontab -

    # اضافه کردن cron جدید
    (crontab -l 2>/dev/null; echo "$CRON_TIME systemctl restart easytier") | crontab -

    colorize green "✅ Auto-restart scheduled successfully"
    press_key
}

clean_service_logs() {
    colorize yellow "🧹 Cleaning service logs..."

    # پاک کردن لاگ‌های قدیمی
    journalctl --vacuum-time=7d

    # پاک کردن لاگ watchdog
    > /var/log/easytier-watchdog.log

    colorize green "✅ Logs cleaned successfully"
    press_key
}

performance_monitor() {
    clear
    colorize cyan "📈 Live Performance Monitor (Ctrl+C to exit)"
    echo

    while true; do
        clear
        colorize cyan "📈 EasyTier Performance Monitor"
        echo "Time: $(date)"
        echo

        # CPU usage
        if command -v top &> /dev/null; then
            CPU_USAGE=$(top -bn1 | grep easytier-core | awk '{print $9}' | head -1)
            echo "🔥 CPU Usage: ${CPU_USAGE:-0}%"
        fi

        # Memory usage
        if command -v ps &> /dev/null; then
            MEM_USAGE=$(ps aux | grep easytier-core | grep -v grep | awk '{print $4, $6}' | head -1)
            echo "💾 Memory: ${MEM_USAGE:-0}"
        fi

        # Network connections
        if command -v netstat &> /dev/null; then
            CONNECTIONS=$(netstat -an | grep :1377 | wc -l)
            echo "🌐 Active Connections: $CONNECTIONS"
        fi

        # Service uptime
        UPTIME=$(systemctl show easytier --property=ActiveEnterTimestamp --value 2>/dev/null)
        if [[ -n "$UPTIME" ]]; then
            echo "⏰ Service Uptime: $UPTIME"
        fi

        sleep 3
    done
}

setup_alerts() {
    colorize yellow "🚨 Setting up Service Alerts"
    echo

    # ایجاد اسکریپت alert
    cat > /usr/local/bin/easytier-alert.sh << 'EOF'
#!/bin/bash
# EasyTier Alert Script

SERVICE_NAME="easytier"
ALERT_LOG="/var/log/easytier-alerts.log"

send_alert() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALERT: $message" >> "$ALERT_LOG"

    # اینجا می‌توانید notification ارسال کنید
    # مثال: curl -X POST webhook_url -d "$message"
}

# بررسی سرویس
if ! systemctl is-active --quiet "$SERVICE_NAME"; then
    send_alert "EasyTier service is down!"
fi

# بررسی memory usage بالا
MEM_USAGE=$(ps aux | grep easytier-core | grep -v grep | awk '{print $4}' | head -1)
if [[ -n "$MEM_USAGE" ]] && (( $(echo "$MEM_USAGE > 80" | bc -l) )); then
    send_alert "High memory usage: ${MEM_USAGE}%"
fi
EOF

    chmod +x /usr/local/bin/easytier-alert.sh

    # اضافه کردن به crontab
    (crontab -l 2>/dev/null; echo "*/10 * * * * /usr/local/bin/easytier-alert.sh") | crontab -

    colorize green "✅ Alerts setup completed! Checking every 10 minutes."
    press_key
}

stability_optimization() {
    colorize yellow "🛡️  Applying Stability Optimizations..."
    echo

    # تنظیمات sysctl برای بهبود شبکه
    cat > /etc/sysctl.d/99-easytier.conf << 'EOF'
# EasyTier Network Optimizations
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 65536 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
net.ipv4.tcp_fastopen = 3
EOF

    sysctl -p /etc/sysctl.d/99-easytier.conf

    # تنظیمات systemd برای بهبود reliability
    mkdir -p /etc/systemd/system/easytier.service.d
    cat > /etc/systemd/system/easytier.service.d/override.conf << 'EOF'
[Service]
Restart=always
RestartSec=10
StartLimitInterval=60
StartLimitBurst=3
WatchdogSec=30
EOF

    systemctl daemon-reload

    colorize green "✅ Stability optimizations applied successfully!"
    echo
    colorize cyan "Applied optimizations:"
    echo "  • Network buffer sizes optimized"
    echo "  • BBR congestion control enabled"
    echo "  • TCP FastOpen enabled"
    echo "  • Service restart limits configured"
    echo "  • Watchdog timer set to 30s"

    press_key
}

remove_watchdog() {
    colorize yellow "🗑️  Removing Watchdog..."

    # حذف اسکریپت‌ها
    rm -f /usr/local/bin/easytier-watchdog.sh
    rm -f /usr/local/bin/easytier-alert.sh

    # حذف cron jobs
    crontab -l 2>/dev/null | grep -v easytier-watchdog | grep -v easytier-alert | crontab -

    # حذف تنظیمات sysctl
    rm -f /etc/sysctl.d/99-easytier.conf

    # حذف override systemd
    rm -rf /etc/systemd/system/easytier.service.d

    systemctl daemon-reload

    colorize green "✅ Watchdog removed successfully"
    press_key
}

# =============================================================================
# 8. ری‌استارت سرویس
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
# 9. حذف سرویس
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
# 10. Ping Test
# =============================================================================

ping_test() {
    echo
    read -p "🎯 Enter IP to ping (e.g., 10.10.10.2): " target_ip

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
# 11. بهینه‌سازی شبکه (جدید)
# =============================================================================

network_optimization() {
    clear
    colorize cyan "⚡ Network & Tunnel Optimization for Ubuntu"
    echo

    colorize yellow "🔧 Applying EasyTier optimizations..."
    echo

    # بهینه‌سازی kernel parameters
    colorize blue "1. Optimizing kernel parameters..."
    cat > /etc/sysctl.d/98-easytier-network.conf << 'EOF'
# EasyTier Network Performance Optimizations

# TCP/UDP Buffer Sizes
net.core.rmem_default = 262144
net.core.rmem_max = 16777216
net.core.wmem_default = 262144
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 5000

# TCP Optimizations
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1

# UDP Optimizations
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192

# Network Security & Performance
net.ipv4.ip_forward = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

# Tunnel Optimizations
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
EOF

    sysctl -p /etc/sysctl.d/98-easytier-network.conf
    colorize green "   ✅ Kernel parameters optimized"

    # بهینه‌سازی فایروال
    colorize blue "2. Configuring firewall for EasyTier..."

    if command -v ufw &> /dev/null; then
        ufw allow 1377/udp comment "EasyTier UDP"
        ufw allow 1377/tcp comment "EasyTier TCP"
        colorize green "   ✅ UFW rules added"
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=1377/udp
        firewall-cmd --permanent --add-port=1377/tcp
        firewall-cmd --reload
        colorize green "   ✅ FirewallD rules added"
    fi

    # بهینه‌سازی network interfaces
    colorize blue "3. Optimizing network interfaces..."

    # تنظیم MTU برای tunnel interfaces
    cat > /etc/systemd/network/99-easytier.network << 'EOF'
[Match]
Name=easytier*

[Network]
MTU=1420
IPForward=yes

[Link]
MTUBytes=1420
EOF

    colorize green "   ✅ Network interface optimization configured"

    # بهینه‌سازی systemd-resolved
    colorize blue "4. Optimizing DNS resolution..."

    if systemctl is-active --quiet systemd-resolved; then
        mkdir -p /etc/systemd/resolved.conf.d
        cat > /etc/systemd/resolved.conf.d/easytier.conf << 'EOF'
[Resolve]
DNS=8.8.8.8 1.1.1.1
FallbackDNS=8.8.4.4 1.0.0.1
Cache=yes
DNSStubListener=yes
EOF
        systemctl restart systemd-resolved
        colorize green "   ✅ DNS optimization applied"
    fi

    # بهینه‌سازی CPU scheduling
    colorize blue "5. Optimizing CPU scheduling for EasyTier..."

    cat > /etc/systemd/system/easytier.service.d/performance.conf << 'EOF'
[Service]
Nice=-10
CPUSchedulingPolicy=1
CPUSchedulingPriority=50
IOSchedulingClass=1
IOSchedulingPriority=4
EOF

    systemctl daemon-reload
    colorize green "   ✅ CPU scheduling optimized"

    # تنظیم network buffer sizes
    colorize blue "6. Setting optimal buffer sizes..."

    # افزایش buffer sizes برای interface های شبکه
    for interface in $(ls /sys/class/net/ | grep -E '^(eth|ens|enp)'); do
        if [[ -w "/sys/class/net/$interface/tx_queue_len" ]]; then
            echo 10000 > "/sys/class/net/$interface/tx_queue_len" 2>/dev/null || true
        fi
    done

    colorize green "   ✅ Network buffer sizes optimized"

    echo
    colorize green "🎉 Network optimization completed successfully!"
    echo
    colorize cyan "📋 Applied optimizations:"
    echo "  • TCP/UDP buffer sizes increased"
    echo "  • BBR congestion control enabled"
    echo "  • TCP FastOpen activated"
    echo "  • Firewall rules configured for port 1377"
    echo "  • MTU optimized for tunnel interfaces"
    echo "  • DNS resolution optimized"
    echo "  • CPU scheduling priority increased"
    echo "  • Network interface buffers enlarged"
    echo
    colorize yellow "💡 Tip: Restart the EasyTier service to apply all optimizations"

    press_key
}

# =============================================================================
# منوی اصلی (مشابه Easy-Mesh)
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
    colorize magenta "	[7] 🐕 Watchdog & Stability"
    colorize yellow "	[8] 🔄 Restart Service"
    colorize red "	[9] 🗑️  Remove Service"
    colorize cyan "	[10] 🏓 Ping Test"
    colorize green "	[11] ⚡ Network Optimization"
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
        7) watchdog_menu ;;
        8) restart_service ;;
        9) remove_service ;;
        10) ping_test ;;
        11) network_optimization ;;
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
