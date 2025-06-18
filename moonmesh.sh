#!/bin/bash

# 🌐 EasyTier Manager - Similar to MoonMesh
# K4lantar4 - Inspired by K4lantar4/MoonMesh
# Fast, Simple, No Complexity

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Paths
CONFIG_DIR="/etc/easytier"
LOG_FILE="/var/log/easytier.log"
SERVICE_NAME="easytier"
EASYTIER_DIR="/usr/local/bin"
EASY_CLIENT="$EASYTIER_DIR/easytier-cli"
HAPROXY_CONFIG="/etc/haproxy/haproxy.cfg"

# =============================================================================
# Helper Functions
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
# Check Core Status
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
# Generate Random Secret
# =============================================================================

generate_random_secret() {
    openssl rand -hex 6 2>/dev/null || echo "$(date +%s)$(shuf -i 1000-9999 -n 1)"
}

# =============================================================================
# Get All System IPs (Public + Non-Private) in Simple Format
# =============================================================================

get_all_ips() {
    # دریافت تمام IP ها بجز loopback و private IPs
    local ips=""
    
    # دریافت همه IP ها از ip a
    while read -r ip; do
        # حذف IP های private و loopback
        if [[ ! "$ip" =~ ^127\. ]] && \
           [[ ! "$ip" =~ ^10\. ]] && \
           [[ ! "$ip" =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]] && \
           [[ ! "$ip" =~ ^192\.168\. ]] && \
           [[ ! "$ip" =~ ^169\.254\. ]]; then
            if [[ -z "$ips" ]]; then
                ips="$ip"
            else
                ips="$ips,$ip"
            fi
        fi
    done < <(ip a | grep -oP '(?<=inet )[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(?=/[0-9]+)')
    
    echo "$ips"
}

# Legacy function for backward compatibility
get_public_ip() {
    local all_ips=$(get_all_ips)
    if [[ -n "$all_ips" ]]; then
        echo "$all_ips" | cut -d',' -f1
    else
        echo "Unknown"
    fi
}

# =============================================================================
# 1. Quick Connect to Network (Similar to Easy-Mesh)
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

    # بررسی وجود سرویس قبلی
    SERVICE_EXISTS=false
    if [[ -f "/etc/systemd/system/easytier.service" ]]; then
        SERVICE_EXISTS=true
        colorize yellow "⚠️  Existing EasyTier service detected. It will be reconfigured and restarted."
        echo
    fi

    # دریافت تمام IP های سیستم
    colorize yellow "🔍 Getting your system IPs..."
    ALL_IPS=$(get_all_ips)

    # پیشفرض‌های جدید
    DEFAULT_LOCAL_IP="10.10.10.1"
    DEFAULT_PORT="1377"
    DEFAULT_HOSTNAME="$(hostname)-$(date +%s | tail -c 4)"

    if [[ -n "$ALL_IPS" ]]; then
        echo "📡 Your IPs: $ALL_IPS"
    else
        echo "📡 Your IPs: No public IPs found"
    fi
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
    
    # اگر سرویس قبلاً موجود بود، restart کن، وگرنه start کن
    if [[ "$SERVICE_EXISTS" == "true" ]]; then
        colorize yellow "🔄 Restarting EasyTier service to apply new configuration..."
        systemctl restart easytier.service
        sleep 2
        if systemctl is-active --quiet easytier.service; then
            colorize green "✅ EasyTier Network Service Restarted Successfully!"
        else
            colorize red "❌ Failed to restart EasyTier service"
            colorize yellow "🔍 Check logs: journalctl -u easytier.service -f"
            press_key
            return
        fi
    else
        colorize yellow "🚀 Starting EasyTier service..."
        systemctl start easytier.service
        sleep 2
        if systemctl is-active --quiet easytier.service; then
            colorize green "✅ EasyTier Network Service Started Successfully!"
        else
            colorize red "❌ Failed to start EasyTier service"
            colorize yellow "🔍 Check logs: journalctl -u easytier.service -f"
            press_key
            return
        fi
    fi
    echo
    colorize cyan "📋 Connection Details:"
    echo "  🌐 Local IP: $IP_ADDRESS"
    echo "  🏷️  Hostname: $HOSTNAME"
    echo "  🔌 Port: $PORT"
    echo "  🔐 Secret: $NETWORK_SECRET"
    echo "  🔗 Protocol: $DEFAULT_PROTOCOL"
    if [[ -n "$ALL_IPS" ]]; then
        echo "  📡 IPs: $ALL_IPS"
    else
        echo "  📡 IPs: No public IPs found"
    fi
    echo "  ⚡ Multi-thread: $([ "$MULTI_THREAD" ] && echo "Enabled" || echo "Disabled")"
    echo "  🌐 IPv6: $([ "$IPV6_MODE" ] && echo "Disabled" || echo "Enabled")"

    press_key
}

# =============================================================================
# 2. Live Peers Monitor
# =============================================================================

live_peers_monitor() {
    if ! command -v $EASY_CLIENT &> /dev/null; then
        colorize red "❌ easytier-cli not found"
        press_key
        return
    fi

    clear
    colorize cyan "👥 Live Network Peers Monitor (Ctrl+C to return)"
    echo

    # Trap Ctrl+C to return to main menu instead of exiting
    trap 'return' INT

    # Use watch for real-time updates without full screen refresh
    watch -n 0.5 -t "$EASY_CLIENT peer 2>/dev/null || echo 'Service not running'"

    # Reset trap
    trap - INT
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
    colorize cyan "🛣️  Live Network Routes Monitor (Ctrl+C to return)"
    echo

    # Trap Ctrl+C to return to main menu instead of exiting
    trap 'return' INT

    # Use watch for real-time updates without full screen refresh with simplified columns
    watch -n 0.5 -t "$EASY_CLIENT route -o table 2>/dev/null | cut -c1-120 || echo 'Service not running'"

    # Reset trap
    trap - INT
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
    colorize cyan "🎯 Live Peer Center Monitor (Ctrl+C to return)"
    echo

    # Trap Ctrl+C to return to main menu instead of exiting
    trap 'return' INT

    # Use watch for real-time updates without full screen refresh
    watch -n 0.5 -t "$EASY_CLIENT peer-center 2>/dev/null || echo 'Service not running'"

    # Reset trap
    trap - INT
}

# =============================================================================
# 5. نمایش کلید شبکه
# =============================================================================

show_network_secret() {
    echo
    if [[ -f "/etc/systemd/system/easytier.service" ]]; then
        # Get all system IPs
        ALL_IPS=$(get_all_ips)

        # Get network secret
        NETWORK_SECRET=$(grep -oP '(?<=--network-secret )[^ ]+' /etc/systemd/system/easytier.service)

        if [[ -n $NETWORK_SECRET ]]; then
            if [[ -n "$ALL_IPS" ]]; then
                colorize cyan "📡 System IPs: $ALL_IPS"
            else
                colorize yellow "📡 System IPs: No public IPs found"
            fi
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

    # Trap Ctrl+C to return to main menu
    trap 'return' INT

    while true; do
        echo -e "${PURPLE}=== Watchdog Menu ===${NC}"
        echo -e "${GREEN}1) 🏓 Ping-based Watchdog (Interactive)${NC}"
        echo -e "${YELLOW}2) 🔄 Auto-restart Timer (Cron)${NC}"
        echo -e "${BLUE}3) 📝 View Live Watchdog Logs${NC}"
        echo -e "${CYAN}4) 📊 Service Health & Performance${NC}"
        echo -e "${RED}5) 🗑️  Remove Watchdog${NC}"
        echo -e "${WHITE}0) ⬅️  Back to Main Menu${NC}"
        echo
        read -p "Select [0-5]: " watchdog_choice

        case $watchdog_choice in
            1) setup_ping_watchdog ;;
            2) setup_auto_restart ;;
            3) view_watchdog_logs ;;
            4) service_health_and_performance ;;
            5) remove_watchdog ;;
            0) trap - INT; return ;;
            *) colorize red "❌ Invalid option" ;;
        esac

        echo
    done
}

service_health_and_performance() {
    clear
    colorize cyan "📊 Service Health & Performance Monitor"
    echo

    # Trap Ctrl+C to return to watchdog menu
    trap 'return' INT

    # Quick Health Check
    colorize blue "🔍 Quick Health Check:"
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
        PID=$(pgrep -f easytier-core)
        echo "   PID: $PID"
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

    # بررسی ping watchdog
    if systemctl is-active --quiet easytier-ping-watchdog 2>/dev/null; then
        colorize green "✅ Ping Watchdog: Active"
    else
        colorize yellow "⚠️  Ping Watchdog: Not configured"
    fi

    echo
    colorize blue "🌐 Network Status Check:"
    echo

    # Port listening check
    if command -v netstat &> /dev/null; then
        LISTENING_PORTS=$(netstat -tuln | grep :1377)
        if [[ -n "$LISTENING_PORTS" ]]; then
            colorize green "✅ Port 1377: Active"
        else
            colorize red "❌ Port 1377: Not listening"
        fi
    fi

    # Network connectivity
    echo "  Testing external connectivity..."
    if ping -c 1 -W 3 8.8.8.8 &> /dev/null; then
        colorize green "  ✅ Internet: Connected"
    else
        colorize red "  ❌ Internet: No connection"
    fi

    echo
    # Reset trap
    trap - INT
    press_key
}

setup_auto_restart() {
    colorize yellow "🔄 Setting up Auto-restart Timer"
    echo
    echo "Select restart interval:"
    echo "1) Every 30 minutes"
    echo "2) Every hour"
    echo "3) Every 2 hours"
    echo "4) Every 6 hours"
    echo "5) Every 12 hours"
    echo "6) Daily (3 AM)"
    echo "7) Weekly (Sunday 3 AM)"
    read -p "Select [1-7]: " interval_choice

    case $interval_choice in
        1) CRON_TIME="*/30 * * * *" ;;
        2) CRON_TIME="0 * * * *" ;;
        3) CRON_TIME="0 */2 * * *" ;;
        4) CRON_TIME="0 */6 * * *" ;;
        5) CRON_TIME="0 */12 * * *" ;;
        6) CRON_TIME="0 3 * * *" ;;
        7) CRON_TIME="0 3 * * 0" ;;
        *) colorize red "Invalid choice"; return ;;
    esac

    # حذف cron قدیمی
    crontab -l 2>/dev/null | grep -v "systemctl restart easytier" | crontab -

    # اضافه کردن cron جدید
    (crontab -l 2>/dev/null; echo "$CRON_TIME systemctl restart easytier") | crontab -

    colorize green "✅ Auto-restart scheduled successfully"
    press_key
}

setup_ping_watchdog() {
    clear
    colorize cyan "🏓 Interactive Ping-based Watchdog Setup"
    echo
    colorize yellow "This watchdog continuously pings the tunnel IP and restarts the service if disconnected"
    echo

    # Get IP from user with default
    read -p "🎯 Enter tunnel IP to ping [10.10.10.1]: " PING_IP
    PING_IP=${PING_IP:-10.10.10.1}

    # Validate IP format
    if [[ ! $PING_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        colorize red "❌ Invalid IP format. Using default: 10.10.10.1"
        PING_IP="10.10.10.1"
    fi

    # Get ping threshold
    echo
    colorize blue "🚨 Ping threshold (milliseconds):"
    echo "  • 300ms: Good for local network"
    echo "  • 500ms: Good for internet connections"
    echo "  • 1000ms: Tolerant for slow connections"
    read -p "Enter ping threshold in ms [300]: " PING_THRESHOLD
    PING_THRESHOLD=${PING_THRESHOLD:-300}

    # Validate threshold
    if ! [[ "$PING_THRESHOLD" =~ ^[0-9]+$ ]] || [ "$PING_THRESHOLD" -lt 50 ] || [ "$PING_THRESHOLD" -gt 5000 ]; then
        colorize yellow "⚠️  Invalid threshold, using default 300ms"
        PING_THRESHOLD=300
    fi

    # Get check interval
    echo
    colorize blue "⏰ Check interval (seconds):"
    echo "  • 8s: Frequent monitoring (recommended)"
    echo "  • 15s: Moderate monitoring"
    echo "  • 30s: Light monitoring"
    read -p "Enter check interval in seconds [8]: " CHECK_INTERVAL
    CHECK_INTERVAL=${CHECK_INTERVAL:-8}

    # Validate interval
    if ! [[ "$CHECK_INTERVAL" =~ ^[0-9]+$ ]] || [ "$CHECK_INTERVAL" -lt 5 ] || [ "$CHECK_INTERVAL" -gt 300 ]; then
        colorize yellow "⚠️  Invalid interval, using default 8 seconds"
        CHECK_INTERVAL=8
    fi

    # Confirm settings
    echo
    colorize cyan "📋 Ping Watchdog Configuration:"
    echo "  🎯 Target IP: $PING_IP"
    echo "  🚨 Ping threshold: ${PING_THRESHOLD}ms"
    echo "  ⏰ Check interval: ${CHECK_INTERVAL}s"
    echo "  🔄 Action: Restart EasyTier service on failure"
    echo

    read -p "Confirm setup? [Y/n]: " confirm_setup
    if [[ ! "$confirm_setup" =~ ^[Nn]$ ]]; then

        # Auto-configure log cleanup (3 days retention)
        clean_service_logs

        # Create ping watchdog script
        colorize yellow "🔧 Creating ping watchdog script..."

        cat > /usr/local/bin/easytier-ping-watchdog.sh << EOF
#!/bin/bash
# EasyTier Ping-based Watchdog Script
# Created by K4lantar4

PING_IP="$PING_IP"
PING_THRESHOLD="$PING_THRESHOLD"
CHECK_INTERVAL="$CHECK_INTERVAL"
SERVICE_NAME="easytier"
LOG_FILE="/var/log/easytier-ping-watchdog.log"
FAILURE_COUNT=0
MAX_FAILURES=3

log_message() {
    echo "[\$(date '+%Y-%m-%d %H:%M:%S')] \$1" >> "\$LOG_FILE"
}

check_ping() {
    # پینگ با timeout 3 ثانیه
    PING_RESULT=\$(ping -c 1 -W 3 "\$PING_IP" 2>/dev/null | grep 'time=' | sed -n 's/.*time=\([0-9.]*\).*/\1/p')

    if [[ -n "\$PING_RESULT" ]]; then
        # تبدیل به millisecond (اگر در second باشد)
        PING_MS=\$(echo "\$PING_RESULT" | awk '{print int(\$1 + 0.5)}')

        if [[ \$PING_MS -le \$PING_THRESHOLD ]]; then
            # پینگ موفق
            if [[ \$FAILURE_COUNT -gt 0 ]]; then
                log_message "Ping recovered: \${PING_MS}ms to \$PING_IP (was failing)"
                FAILURE_COUNT=0
            fi
            return 0
        else
            # پینگ بالا
            log_message "High ping: \${PING_MS}ms to \$PING_IP (threshold: \${PING_THRESHOLD}ms)"
            return 1
        fi
    else
        # پینگ ناموفق
        log_message "Ping failed to \$PING_IP"
        return 1
    fi
}

restart_service() {
    log_message "Restarting \$SERVICE_NAME service due to ping issues..."

    if systemctl restart "\$SERVICE_NAME"; then
        log_message "Service \$SERVICE_NAME restarted successfully"
        FAILURE_COUNT=0
        # انتظار برای stabilize شدن سرویس
        sleep 10
    else
        log_message "Failed to restart service \$SERVICE_NAME"
    fi
}

# حلقه اصلی
while true; do
    if ! check_ping; then
        ((FAILURE_COUNT++))
        log_message "Ping check failed (\$FAILURE_COUNT/\$MAX_FAILURES)"

        if [[ \$FAILURE_COUNT -ge \$MAX_FAILURES ]]; then
            restart_service
        fi
    fi

    sleep "\$CHECK_INTERVAL"
done
EOF

        chmod +x /usr/local/bin/easytier-ping-watchdog.sh

        # Create systemd service for ping watchdog
        colorize yellow "🔧 Creating systemd service..."

        cat > /etc/systemd/system/easytier-ping-watchdog.service << EOF
[Unit]
Description=EasyTier Ping-based Watchdog
After=network.target easytier.service
Wants=easytier.service

[Service]
Type=simple
ExecStart=/usr/local/bin/easytier-ping-watchdog.sh
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF

        # Enable and start service
        systemctl daemon-reload
        systemctl enable easytier-ping-watchdog.service
        systemctl start easytier-ping-watchdog.service

        # Check status
        sleep 2
        if systemctl is-active --quiet easytier-ping-watchdog.service; then
            colorize green "✅ Ping Watchdog setup completed successfully!"
            echo
            colorize cyan "📊 Watchdog Status:"
            echo "  🟢 Service: Active"
            echo "  🎯 Monitoring: $PING_IP"
            echo "  🚨 Threshold: ${PING_THRESHOLD}ms"
            echo "  ⏰ Interval: ${CHECK_INTERVAL}s"
            echo "  📝 Log: /var/log/easytier-ping-watchdog.log"
            echo
            colorize yellow "💡 Commands:"
            echo "  • View logs: tail -f /var/log/easytier-ping-watchdog.log"
            echo "  • Stop watchdog: systemctl stop easytier-ping-watchdog"
            echo "  • Status: systemctl status easytier-ping-watchdog"
        else
            colorize red "❌ Failed to start ping watchdog service"
        fi
    else
        colorize blue "ℹ️  Setup cancelled"
    fi

    press_key
}

clean_service_logs() {
    colorize yellow "🧹 Auto-cleaning service logs (3 days retention)..."

    # پاک کردن لاگ‌های قدیمی - 3 روز
    journalctl --vacuum-time=3d

    # پاک کردن لاگ watchdog قدیمی‌تر از 3 روز
    find /var/log/ -name "*easytier*" -type f -mtime +3 -delete 2>/dev/null || true

        # تنظیم cron برای پاک‌سازی خودکار
    CRON_JOB="0 2 * * * journalctl --vacuum-time=3d && find /var/log/ -name '*easytier*' -type f -mtime +3 -delete 2>/dev/null"

    # حذف cron قدیمی و اضافه کردن جدید
    (crontab -l 2>/dev/null | grep -v "vacuum-time" | grep -v "easytier.*delete"; echo "$CRON_JOB") | crontab -
}

view_watchdog_logs() {
    clear
    colorize cyan "📝 Live Watchdog Logs Monitor (Ctrl+C to return)"
    echo

    # Check if ping watchdog service is active
    if ! systemctl is-active --quiet easytier-ping-watchdog.service 2>/dev/null; then
        colorize yellow "⚠️  Ping watchdog service is not active"
        echo
        colorize blue "💡 Tips:"
        echo "  • Run 'Ping-based Watchdog' setup first"
        echo "  • Check if watchdog service is enabled"
        echo "  • Verify watchdog configuration"
        echo
        colorize cyan "📋 Available options:"
        echo "  • Press Enter to return to watchdog menu"
        echo "  • Check EasyTier service logs instead"
        
        read -p "Press Enter to continue..."
        return
    fi

    # Trap Ctrl+C to return to watchdog menu instead of exiting
    trap 'echo; colorize blue "🔙 Returning to watchdog menu..."; sleep 1; return' INT

    # Check if ping watchdog log exists
    if [[ -f "/var/log/easytier-ping-watchdog.log" ]]; then
        colorize green "📊 Monitoring ping watchdog logs..."
        echo
        # Show watchdog logs with timeout to handle Ctrl+C properly
        timeout 3600 tail -f /var/log/easytier-ping-watchdog.log 2>/dev/null | while read -r line; do
            # Filter relevant log entries
            if [[ "$line" =~ (Ping|Restart|recovered|failed|Starting|Stopping) ]]; then
                echo "$line"
            fi
        done
    else
        colorize yellow "⚠️  Ping watchdog log file not found"
        echo
        colorize blue "📋 Showing systemd logs instead:"
        echo
        # Show systemd logs with timeout
        timeout 3600 journalctl -u easytier-ping-watchdog -f --no-pager 2>/dev/null || {
            colorize red "❌ Unable to access watchdog logs"
            echo
            read -p "Press Enter to return to watchdog menu..."
        }
    fi

    # Reset trap
    trap - INT
}

remove_watchdog() {
    colorize yellow "🗑️  Removing All Watchdogs..."

    # متوقف کردن ping watchdog service
    if systemctl is-active --quiet easytier-ping-watchdog.service; then
        colorize yellow "🛑 Stopping ping watchdog service..."
        systemctl stop easytier-ping-watchdog.service
        systemctl disable easytier-ping-watchdog.service
    fi

    # حذف اسکریپت‌ها
    rm -f /usr/local/bin/easytier-watchdog.sh
    rm -f /usr/local/bin/easytier-alert.sh
    rm -f /usr/local/bin/easytier-ping-watchdog.sh

    # حذف systemd service files
    rm -f /etc/systemd/system/easytier-ping-watchdog.service

    # حذف cron jobs
    crontab -l 2>/dev/null | grep -v easytier-watchdog | grep -v easytier-alert | crontab -

    # حذف تنظیمات sysctl
    rm -f /etc/sysctl.d/99-easytier.conf

    # حذف override systemd
    rm -rf /etc/systemd/system/easytier.service.d

    # حذف لاگ فایل‌ها
    rm -f /var/log/easytier-ping-watchdog.log
    rm -f /var/log/easytier-watchdog.log
    rm -f /var/log/easytier-alerts.log

    systemctl daemon-reload

    colorize green "✅ All watchdogs removed successfully"
    echo
    colorize cyan "🧹 Removed components:"
    echo "  • Ping-based watchdog service"
    echo "  • Standard watchdog scripts"
    echo "  • Cron jobs"
    echo "  • System optimizations"
    echo "  • Log files"

    press_key
}

# =============================================================================
# 8. ری‌استارت سرویس
# =============================================================================

restart_service() {
    clear
    colorize cyan "🔄 EasyTier Service Restart"
    echo

    # بررسی وجود سرویس
    if [[ ! -f "/etc/systemd/system/easytier.service" ]]; then
        colorize red "❌ EasyTier service does not exist"
        echo
        colorize yellow "💡 Tip: Run 'Quick Connect' first to create the service"
        press_key
        return
    fi

    # نمایش وضعیت فعلی
    colorize blue "📊 Current Status:"
    if systemctl is-active --quiet easytier.service; then
        colorize green "  ✅ Service: Active"
    else
        colorize red "  ❌ Service: Inactive"
    fi
    echo

    # تایید ری‌استارت
    read -p "🔄 Restart EasyTier service? [Y/n]: " confirm_restart
    if [[ "$confirm_restart" =~ ^[Nn]$ ]]; then
        colorize blue "ℹ️  Restart cancelled"
        press_key
        return
    fi

    # ری‌استارت با مدیریت خطا
    colorize yellow "🔄 Restarting EasyTier service..."

    # متوقف کردن سرویس
    if systemctl stop easytier.service 2>/dev/null; then
        colorize green "  ✅ Service stopped"
    else
        colorize yellow "  ⚠️  Service was not running"
    fi

    # انتظار کوتاه
    sleep 2

    # شروع مجدد سرویس
    if systemctl start easytier.service 2>/dev/null; then
        colorize green "  ✅ Service started"

        # انتظار برای stabilize شدن
        sleep 3

        # بررسی وضعیت نهایی
        if systemctl is-active --quiet easytier.service; then
            colorize green "✅ EasyTier service restarted successfully"

            # نمایش اطلاعات اضافی
            echo
            colorize cyan "📋 Service Information:"

            # PID
            PID=$(pgrep -f easytier-core 2>/dev/null)
            if [[ -n "$PID" ]]; then
                echo "  🔢 PID: $PID"
            fi

            # Local IP
            LOCAL_IP=$(grep -oP '(?<=-i )[^ ]+' /etc/systemd/system/easytier.service 2>/dev/null)
            if [[ -n "$LOCAL_IP" ]]; then
                echo "  🏠 Local IP: $LOCAL_IP"
            fi

            # Port check
            if netstat -tuln 2>/dev/null | grep -q ":1377 "; then
                echo "  🔌 Port 1377: ✅ Listening"
            else
                echo "  🔌 Port 1377: ⚠️  Not listening"
            fi

        else
            colorize red "❌ Service failed to start properly"
            echo
            colorize yellow "🔍 Checking logs for errors..."
            journalctl -u easytier.service --no-pager -l -n 10
        fi
    else
        colorize red "❌ Failed to start EasyTier service"
        echo
        colorize yellow "🔍 Possible issues:"
        echo "  • Configuration error in service file"
        echo "  • Port 1377 already in use"
        echo "  • Network interface issues"
        echo "  • Missing easytier-core binary"
        echo
        colorize yellow "📝 Check logs:"
        echo "  journalctl -u easytier.service -f"
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

    colorize yellow "⚠️  Are you sure you want to remove EasyTier service? [Y/n]: "
    read -r confirm
0
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
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

# =============================================================================
# 11. HAProxy Load Balancer Management
# =============================================================================

# Install HAProxy if not present
install_haproxy() {
    if ! command -v haproxy &> /dev/null; then
        if command -v apt-get &> /dev/null; then
            colorize yellow "📦 Installing HAProxy..."
            apt-get update -qq
            apt-get install -y haproxy jq
            colorize green "✅ HAProxy installed successfully"
        else
            colorize red "❌ Unsupported package manager. Please install HAProxy manually."
            return 1
        fi
    fi
}

# Show HAProxy status
show_haproxy_status() {
    if ! command -v haproxy &>/dev/null; then
        echo -e "${RED}HAProxy not installed${NC}"
        return 1
    fi

    if systemctl is-active --quiet haproxy; then
        echo -e "${GREEN}HAProxy: Active${NC}"
    else
        echo -e "${RED}HAProxy: Inactive${NC}"
    fi
}

# HAProxy main menu
haproxy_menu() {
    clear
    colorize cyan "🔄 HAProxy Load Balancer Management"
    echo

    # Trap Ctrl+C to return to main menu
    trap 'return' INT

    # Install HAProxy if needed
    install_haproxy || return

    while true; do
        echo -e "${CYAN}=== HAProxy Load Balancer ===${NC}"
        show_haproxy_status
        echo "-------------------------------"
        echo -e "${GREEN}1) 🔧 Configure New Tunnel${NC}"
        echo -e "${BLUE}2) ➕ Add Server Configuration${NC}"
        echo -e "${YELLOW}3) ⚖️  Configure Load Balancer${NC}"
        echo -e "${CYAN}4) 🔄 Restart HAProxy Service${NC}"
        echo -e "${PURPLE}5) 📝 View Live HAProxy Logs${NC}"
        echo -e "${RED}6) 🗑️  Remove HAProxy Configuration${NC}"
        echo -e "${WHITE}0) ⬅️  Back to Main Menu${NC}"
        echo
        read -p "Select [0-6]: " haproxy_choice

        case $haproxy_choice in
            1) configure_haproxy_tunnel ;;
            2) add_haproxy_server ;;
            3) configure_haproxy_loadbalancer ;;
            4) restart_haproxy_service ;;
            5) view_haproxy_logs ;;
            6) remove_haproxy_config ;;
            0) trap - INT; return ;;
            *) colorize red "❌ Invalid option" ;;
        esac

        echo
    done
}

# Configure new HAProxy tunnel
configure_haproxy_tunnel() {
    clear
    colorize cyan "🔧 Configure New HAProxy Tunnel"
    echo

    read -p "⚠️  All previous configs will be deleted, continue? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        colorize blue "ℹ️  Operation cancelled"
        return
    fi

    # Create HAProxy config directory
    mkdir -p /etc/haproxy

    # Create basic HAProxy configuration
    cat > "$HAPROXY_CONFIG" << 'EOF'
# HAProxy configuration generated by moonmesh
global
    log /dev/log    local0
    log /dev/log    local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    tcp
    option  tcplog
    option  dontlognull
    timeout connect 5000ms
    timeout client  50000ms
    timeout server  50000ms

EOF

    # Multi-port support
    echo
    read -p "🔌 Enter HAProxy bind ports (comma separated, e.g., 443,8443,2096): " haproxy_bind_ports
    read -p "🎯 Enter destination ports (same order, e.g., 443,8443,2096): " destination_ports
    read -p "🌐 Enter destination IP address: " destination_ip

    # Validate inputs
    if [[ -z "$haproxy_bind_ports" ]] || [[ -z "$destination_ports" ]] || [[ -z "$destination_ip" ]]; then
        colorize red "❌ All fields are required"
        return
    fi

    # Split ports into arrays
    IFS=',' read -r -a haproxy_ports_array <<< "$haproxy_bind_ports"
    IFS=',' read -r -a destination_ports_array <<< "$destination_ports"

    # Validate port arrays
    if [ "${#haproxy_ports_array[@]}" -ne "${#destination_ports_array[@]}" ]; then
        colorize red "❌ Number of bind ports and destination ports must match"
        return
    fi

    # Add configurations for each port
    for i in "${!haproxy_ports_array[@]}"; do
        haproxy_bind_port=$(echo "${haproxy_ports_array[$i]}" | xargs)
        destination_port=$(echo "${destination_ports_array[$i]}" | xargs)

        # Check for port conflicts
        if netstat -tuln 2>/dev/null | grep -q ":$haproxy_bind_port "; then
            colorize yellow "⚠️  Port $haproxy_bind_port is already in use"
            read -p "Continue anyway? [y/N]: " continue_port
            if [[ ! "$continue_port" =~ ^[Yy]$ ]]; then
                continue
            fi
        fi

        cat >> "$HAPROXY_CONFIG" << EOF
frontend frontend_$haproxy_bind_port
    bind *:$haproxy_bind_port
    default_backend backend_$haproxy_bind_port

backend backend_$haproxy_bind_port
    server server_$haproxy_bind_port $destination_ip:$destination_port

EOF
    done

    # Restart HAProxy
    systemctl restart haproxy

    if systemctl is-active --quiet haproxy; then
        colorize green "✅ HAProxy tunnel configured successfully"
        echo
        colorize cyan "📋 Configuration summary:"
        echo "  • Bind ports: $haproxy_bind_ports"
        echo "  • Destination: $destination_ip"
        echo "  • Destination ports: $destination_ports"
    else
        colorize red "❌ Failed to start HAProxy"
        journalctl -u haproxy --no-pager -l -n 5
    fi

    press_key
}

# Add new server to existing configuration
add_haproxy_server() {
    clear
    colorize cyan "➕ Add New Server Configuration"
    echo

    if [[ ! -f "$HAPROXY_CONFIG" ]]; then
        colorize red "❌ No HAProxy configuration found"
        colorize yellow "💡 Please create a new tunnel configuration first"
        press_key
        return
    fi

    while true; do
        echo
        read -p "🔌 Enter HAProxy bind ports (comma separated): " haproxy_bind_ports
        read -p "🎯 Enter destination ports (same order): " destination_ports
        read -p "🌐 Enter destination IP address: " destination_ip

        # Validate inputs
        if [[ -z "$haproxy_bind_ports" ]] || [[ -z "$destination_ports" ]] || [[ -z "$destination_ip" ]]; then
            colorize red "❌ All fields are required"
            continue
        fi

        # Split ports into arrays
        IFS=',' read -r -a haproxy_ports_array <<< "$haproxy_bind_ports"
        IFS=',' read -r -a destination_ports_array <<< "$destination_ports"

        # Validate port arrays
        if [ "${#haproxy_ports_array[@]}" -ne "${#destination_ports_array[@]}" ]; then
            colorize red "❌ Number of bind ports and destination ports must match"
            continue
        fi

        # Check for existing port conflicts
        port_conflict=false
        for haproxy_bind_port in "${haproxy_ports_array[@]}"; do
            haproxy_bind_port=$(echo "$haproxy_bind_port" | xargs)
            if grep -q "bind \*:$haproxy_bind_port" "$HAPROXY_CONFIG"; then
                colorize red "❌ Port $haproxy_bind_port already configured in HAProxy"
                port_conflict=true
                break
            fi
        done

        if $port_conflict; then
            continue
        fi

        # Add configurations for each port
        for i in "${!haproxy_ports_array[@]}"; do
            haproxy_bind_port=$(echo "${haproxy_ports_array[$i]}" | xargs)
            destination_port=$(echo "${destination_ports_array[$i]}" | xargs)

            cat >> "$HAPROXY_CONFIG" << EOF
frontend frontend_$haproxy_bind_port
    bind *:$haproxy_bind_port
    default_backend backend_$haproxy_bind_port

backend backend_$haproxy_bind_port
    server server_$haproxy_bind_port $destination_ip:$destination_port

EOF
        done

        colorize green "✅ Server configuration added"
        echo
        read -p "➕ Add another server configuration? [y/N]: " add_another
        if [[ ! "$add_another" =~ ^[Yy]$ ]]; then
            break
        fi
    done

    # Restart HAProxy
    systemctl restart haproxy

    if systemctl is-active --quiet haproxy; then
        colorize green "✅ HAProxy configuration updated successfully"
    else
        colorize red "❌ Failed to restart HAProxy"
        journalctl -u haproxy --no-pager -l -n 5
    fi

    press_key
}

# Configure load balancer
configure_haproxy_loadbalancer() {
    clear
    colorize cyan "⚖️  Configure HAProxy Load Balancer"
    echo

    read -p "⚠️  All previous configs will be deleted, continue? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        colorize blue "ℹ️  Operation cancelled"
        return
    fi

    # Create basic HAProxy configuration
    cat > "$HAPROXY_CONFIG" << 'EOF'
# HAProxy Load Balancer configuration generated by moonmesh
global
    log /dev/log    local0
    log /dev/log    local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    tcp
    option  tcplog
    option  dontlognull
    timeout connect 5000ms
    timeout client  50000ms
    timeout server  50000ms

EOF

    # Load balancing algorithm selection
    echo
    colorize blue "⚖️  Load balancing algorithms:"
    echo "1) Round Robin (default)"
    echo "2) Least Connections"
    echo "3) Source IP Hash"
    echo "4) URI Hash"
    read -p "Select algorithm [1]: " lb_choice

    case ${lb_choice:-1} in
        1) lb_algorithm="roundrobin" ;;
        2) lb_algorithm="leastconn" ;;
        3) lb_algorithm="source" ;;
        4) lb_algorithm="uri" ;;
        *) lb_algorithm="roundrobin" ;;
    esac

    echo
    read -p "🔌 Enter HAProxy bind port for load balancing: " haproxy_bind_port

    # Add frontend and backend configuration
    cat >> "$HAPROXY_CONFIG" << EOF
frontend tcp_frontend
    bind *:$haproxy_bind_port
    mode tcp
    default_backend tcp_backend

backend tcp_backend
    mode tcp
    balance $lb_algorithm
EOF

    # Add servers
    server=1
    while true; do
        echo
        read -p "🌐 Enter destination IP address for server $server: " destination_ip
        read -p "🎯 Enter destination port for server $server: " destination_port

        if [[ -n "$destination_ip" ]] && [[ -n "$destination_port" ]]; then
            echo "    server server${server} ${destination_ip}:${destination_port} check" >> "$HAPROXY_CONFIG"
            colorize green "✅ Server $server added"
        fi

        echo
        read -p "➕ Add another server? [y/N]: " add_another
        if [[ ! "$add_another" =~ ^[Yy]$ ]]; then
            break
        fi
        server=$((server + 1))
    done

    # Restart HAProxy
    systemctl restart haproxy

    if systemctl is-active --quiet haproxy; then
        colorize green "✅ HAProxy load balancer configured successfully"
        echo
        colorize cyan "📋 Configuration summary:"
        echo "  • Bind port: $haproxy_bind_port"
        echo "  • Algorithm: $lb_algorithm"
        echo "  • Servers: $((server - 1))"
    else
        colorize red "❌ Failed to start HAProxy"
        journalctl -u haproxy --no-pager -l -n 5
    fi

    press_key
}

# Restart HAProxy service
restart_haproxy_service() {
    colorize yellow "🔄 Restarting HAProxy service..."

    if systemctl restart haproxy; then
        colorize green "✅ HAProxy restarted successfully"
    else
        colorize red "❌ Failed to restart HAProxy"
        journalctl -u haproxy --no-pager -l -n 5
    fi

    press_key
}

# View HAProxy logs
view_haproxy_logs() {
    clear
    colorize cyan "📝 Live HAProxy Logs Monitor (Ctrl+C to return)"
    echo

    # Check if HAProxy service is active
    if ! systemctl is-active --quiet haproxy.service 2>/dev/null; then
        colorize yellow "⚠️  HAProxy service is not active"
        echo
        colorize blue "💡 Tips:"
        echo "  • Start HAProxy service first"
        echo "  • Check HAProxy configuration"
        echo "  • Verify HAProxy installation"
        echo
        read -p "Press Enter to return to HAProxy menu..."
        return
    fi

    # Trap Ctrl+C to return to HAProxy menu instead of exiting
    trap 'echo; colorize blue "🔙 Returning to HAProxy menu..."; sleep 1; return' INT

    if [[ -f "/var/log/haproxy.log" ]]; then
        colorize green "📊 Monitoring HAProxy logs..."
        echo
        timeout 3600 tail -f /var/log/haproxy.log 2>/dev/null
    else
        colorize yellow "⚠️  HAProxy log file not found, showing systemd logs..."
        echo
        timeout 3600 journalctl -u haproxy -f --no-pager 2>/dev/null || {
            colorize red "❌ Unable to access HAProxy logs"
            echo
            read -p "Press Enter to return to HAProxy menu..."
        }
    fi

    # Reset trap
    trap - INT
}

# Remove HAProxy configuration
remove_haproxy_config() {
    colorize yellow "🗑️  Removing HAProxy configuration..."
    echo

    read -p "⚠️  This will stop HAProxy and remove all configurations. Continue? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        colorize blue "ℹ️  Operation cancelled"
        return
    fi

    # Stop HAProxy service
    if systemctl is-active --quiet haproxy; then
        systemctl stop haproxy
        colorize green "✅ HAProxy service stopped"
    fi

    # Remove configuration file
    if [[ -f "$HAPROXY_CONFIG" ]]; then
        rm -f "$HAPROXY_CONFIG"
        colorize green "✅ HAProxy configuration removed"
    fi

    colorize green "✅ HAProxy cleanup completed"
    press_key
}

# =============================================================================
# 12. Network Optimization
# =============================================================================

network_optimization() {
    clear
    colorize cyan "⚡ Network & Tunnel Optimization for Ubuntu"
    echo

    colorize yellow "🔧 Applying EasyTier optimizations..."
    echo

    # Stability optimizations first
    colorize blue "1. Applying stability optimizations..."

    # تنظیمات systemd برای بهبود reliability
    mkdir -p /etc/systemd/system/easytier.service.d
    cat > /etc/systemd/system/easytier.service.d/override.conf << 'EOF'
[Service]
Restart=always
RestartSec=10
StartLimitInterval=60
StartLimitBurst=3
EOF

    colorize green "   ✅ Service restart limits configured"

    # بهینه‌سازی kernel parameters
    colorize blue "2. Optimizing kernel parameters..."
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
    colorize blue "3. Configuring firewall for EasyTier..."

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
    colorize blue "4. Optimizing network interfaces..."

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
    colorize blue "5. Optimizing DNS resolution..."

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
    colorize blue "6. Optimizing CPU scheduling for EasyTier..."

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
    colorize blue "7. Setting optimal buffer sizes..."

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
    echo "  • Service restart limits configured"
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
    # Header زیبا و مرتب
    echo -e "   ${CYAN}╔════════════════════════════════════════╗"
    echo -e "   ║            ${WHITE}EasyTier Manager            ${CYAN}║"
    echo -e "   ║       ${WHITE}Simple Mesh Network Solution    ${CYAN}║"
    echo -e "   ╠════════════════════════════════════════╣"
    echo -e "   ║  ${WHITE}Version: 2.0 (K4lantar4)           ${CYAN}║"
    echo -e "   ║  ${WHITE}GitHub: k4lantar4/moonmesh          ${CYAN}║"
    echo -e "   ╠════════════════════════════════════════╣"
    echo -e "   ║        $(check_core_status)         ║"
    echo -e "   ╚════════════════════════════════════════╝${NC}"

    echo
    colorize green "   [1]  Quick Connect to Network"
    colorize cyan "   [2]  Live Peers Monitor"
    colorize yellow "   [3]  Display Routes"
    colorize blue "   [4]  Peer-Center"
    colorize purple "   [5]  Display Secret Key"
    colorize white "   [6]  View Service Status"
    colorize magenta "   [7]  Watchdog & Stability"
    colorize blue "   [8]  HAProxy Load Balancer"
    colorize yellow "   [9]  Restart Service"
    colorize red "   [10] Remove Service"
    colorize green "   [11] Network Optimization"
    echo -e "   [0]  Exit"
    echo
}

# =============================================================================
# خواندن گزینه کاربر
# =============================================================================

read_option() {
    echo -e "   -------------------------------"
    echo -en "   ${MAGENTA}Enter your choice: ${NC}"
    read -r choice
    case $choice in
        1) quick_connect ;;
        2) live_peers_monitor ;;
        3) display_routes ;;
        4) peer_center ;;
        5) show_network_secret ;;
        6) view_service_status ;;
        7) watchdog_menu ;;
        8) haproxy_menu ;;
        9) restart_service ;;
        10) remove_service ;;
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

# Trap Ctrl+C for main menu to exit
trap 'colorize green "👋 Goodbye!"; exit 0' INT

# حلقه اصلی
while true; do
    display_menu
    read_option
done
