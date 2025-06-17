#!/bin/bash

# 🔗 مدیر Peers EasyTier
# هدف: مدیریت ساده peers بدون پیچیدگی

set -e

# رنگ‌ها
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# مسیرها
CONFIG_DIR="/etc/easytier"
CONFIG_FILE="$CONFIG_DIR/config.yml"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# =============================================================================
# نمایش peers متصل
# =============================================================================

show_connected_peers() {
    echo -e "${CYAN}=== Connected Peers ===${NC}"
    echo
    
    if ! command -v easytier-cli &> /dev/null; then
        log_error "easytier-cli not found"
        return 1
    fi
    
    if ! systemctl is-active --quiet easytier; then
        log_error "EasyTier service is not running"
        log_info "To start: sudo systemctl start easytier"
        return 1
    fi
    
    log_info "Fetching peers information..."
    
    # نمایش peers
    if easytier-cli peer 2>/dev/null; then
        log_success "Peers information fetched successfully"
    else
        log_warning "Error fetching peers information"
        log_info "Maybe no peer is connected yet"
    fi
    
    echo
    
    # نمایش routes
    log_info "Active routes:"
    if easytier-cli route 2>/dev/null; then
        log_success "Routes information fetched"
    else
        log_warning "Error fetching routes"
    fi
}

# =============================================================================
# نمایش peers در config
# =============================================================================

show_config_peers() {
    echo -e "${CYAN}=== Peers تعریف شده در Config ===${NC}"
    echo
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "فایل config یافت نشد: $CONFIG_FILE"
        return 1
    fi
    
    log_info "peers موجود در config:"
    echo "─────────────────────────"
    
    # استخراج peers از config
    local peers_found=false
    while IFS= read -r line; do
        if [[ $line =~ ^[[:space:]]*-[[:space:]]*\"([^\"]+)\" ]]; then
            local peer="${BASH_REMATCH[1]}"
            if [[ $peer =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]] || [[ $peer =~ :[0-9]+$ ]]; then
                echo "  🔗 $peer"
                peers_found=true
            fi
        fi
    done < "$CONFIG_FILE"
    
    if [[ $peers_found == false ]]; then
        log_warning "هیچ peer معتبری در config یافت نشد"
        log_info "برای اضافه کردن peer از گزینه 'add' استفاده کنید"
    fi
    
    echo "─────────────────────────"
}

# =============================================================================
# اضافه کردن peer جدید
# =============================================================================

add_peer() {
    local new_peer="$1"
    
    echo -e "${GREEN}=== اضافه کردن Peer جدید ===${NC}"
    echo
    
    # دریافت IP:Port اگر داده نشده
    if [[ -z "$new_peer" ]]; then
        echo "مثال‌های معتبر:"
        echo "  - 1.2.3.4:11011"
        echo "  - example.com:11011"
        echo "  - [2001:db8::1]:11011"
        echo
        read -p "IP:Port peer جدید: " new_peer
    fi
    
    # اعتبارسنجی ساده
    if [[ -z "$new_peer" ]]; then
        log_error "IP:Port نمی‌تواند خالی باشد"
        return 1
    fi
    
    if [[ ! "$new_peer" =~ :[0-9]+$ ]]; then
        log_error "فرمت نامعتبر. باید شامل :PORT باشد"
        return 1
    fi
    
    # بررسی فایل config
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "فایل config یافت نشد: $CONFIG_FILE"
        return 1
    fi
    
    # بررسی تکراری بودن
    if grep -q "\"$new_peer\"" "$CONFIG_FILE"; then
        log_warning "این peer قبلاً در config موجود است"
        return 1
    fi
    
    log_info "اضافه کردن peer: $new_peer"
    
    # بک‌آپ فایل config
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%s)"
    
    # اضافه کردن peer (روش ساده)
    if grep -q "peers:" "$CONFIG_FILE"; then
        # اگر بخش peers موجود است
        sed -i "/peers:/a\\  - \"$new_peer\"" "$CONFIG_FILE"
    else
        # اگر بخش peers موجود نیست، اضافه کن
        echo "" >> "$CONFIG_FILE"
        echo "peers:" >> "$CONFIG_FILE"
        echo "  - \"$new_peer\"" >> "$CONFIG_FILE"
    fi
    
    log_success "Peer با موفقیت اضافه شد"
    log_info "برای اعمال تغییرات: sudo systemctl restart easytier"
    
    # نمایش peers فعلی
    echo
    show_config_peers
}

# =============================================================================
# حذف peer
# =============================================================================

remove_peer() {
    local peer_to_remove="$1"
    
    echo -e "${RED}=== حذف Peer ===${NC}"
    echo
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "فایل config یافت نشد"
        return 1
    fi
    
    # نمایش peers موجود
    show_config_peers
    echo
    
    # دریافت peer برای حذف
    if [[ -z "$peer_to_remove" ]]; then
        read -p "IP:Port peer برای حذف: " peer_to_remove
    fi
    
    if [[ -z "$peer_to_remove" ]]; then
        log_error "IP:Port نمی‌تواند خالی باشد"
        return 1
    fi
    
    # بررسی وجود peer
    if ! grep -q "\"$peer_to_remove\"" "$CONFIG_FILE"; then
        log_error "Peer یافت نشد: $peer_to_remove"
        return 1
    fi
    
    # بک‌آپ فایل config
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%s)"
    
    # حذف peer
    sed -i "/\"$peer_to_remove\"/d" "$CONFIG_FILE"
    
    log_success "Peer حذف شد: $peer_to_remove"
    log_info "برای اعمال تغییرات: sudo systemctl restart easytier"
    
    # نمایش peers به‌روزرسانی شده
    echo
    show_config_peers
}

# =============================================================================
# تست ping
# =============================================================================

test_ping() {
    local target_ip="$1"
    
    echo -e "${BLUE}=== تست Ping ===${NC}"
    echo
    
    if [[ -z "$target_ip" ]]; then
        echo "مثال‌های IP تانل:"
        echo "  - 10.145.0.1 (gateway)"
        echo "  - 10.145.0.2 (peer دیگر)"
        echo
        read -p "IP مقصد برای ping: " target_ip
    fi
    
    if [[ -z "$target_ip" ]]; then
        log_error "IP نمی‌تواند خالی باشد"
        return 1
    fi
    
    log_info "تست ping به $target_ip..."
    echo
    
    if ping -c 3 -W 3 "$target_ip"; then
        echo
        log_success "✅ Ping موفق! اتصال برقرار است"
    else
        echo
        log_error "❌ Ping ناموفق"
        echo
        log_info "دلایل احتمالی:"
        echo "  • سرویس EasyTier فعال نیست"
        echo "  • Peer متصل نیست"
        echo "  • IP اشتباه است"
        echo "  • فایروال مسدود کرده"
    fi
}

# =============================================================================
# نمایش آمار سریع
# =============================================================================

show_quick_stats() {
    echo -e "${CYAN}=== آمار سریع ===${NC}"
    echo
    
    # وضعیت سرویس
    if systemctl is-active --quiet easytier; then
        log_success "سرویس EasyTier: 🟢 فعال"
    else
        log_error "سرویس EasyTier: 🔴 غیرفعال"
    fi
    
    # تعداد peers در config
    local config_peers=0
    if [[ -f "$CONFIG_FILE" ]]; then
        config_peers=$(grep -c "\".*:.*\"" "$CONFIG_FILE" 2>/dev/null || echo "0")
    fi
    echo -e "${BLUE}[INFO]${NC} Peers در config: $config_peers"
    
    # IP تانل فعلی
    local tunnel_ip=$(grep "ipv4:" "$CONFIG_FILE" 2>/dev/null | sed 's/.*"\(.*\)".*/\1/' | head -1)
    if [[ -n "$tunnel_ip" ]]; then
        echo -e "${BLUE}[INFO]${NC} IP تانل: $tunnel_ip"
    fi
    
    # آخرین لاگ
    echo
    echo -e "${CYAN}آخرین لاگ:${NC}"
    journalctl -u easytier --no-pager -l | tail -3 2>/dev/null || echo "  لاگ در دسترس نیست"
}

# =============================================================================
# منوی کمکی
# =============================================================================

show_help() {
    echo -e "${CYAN}🔗 مدیر Peers EasyTier${NC}"
    echo
    echo "استفاده:"
    echo "  $0 [command] [options]"
    echo
    echo "دستورات:"
    echo "  show           نمایش peers متصل"
    echo "  list           نمایش peers در config"
    echo "  add [IP:PORT]  اضافه کردن peer جدید"
    echo "  remove [IP:PORT] حذف peer"
    echo "  ping [IP]      تست ping"
    echo "  stats          نمایش آمار سریع"
    echo "  help           نمایش این راهنما"
    echo
    echo "مثال‌ها:"
    echo "  $0 add 1.2.3.4:11011"
    echo "  $0 ping 10.145.0.1"
    echo "  $0 remove 1.2.3.4:11011"
}

# =============================================================================
# اجرای دستور
# =============================================================================

case "${1:-help}" in
    "show"|"connected")
        show_connected_peers
        ;;
    "list"|"config")
        show_config_peers
        ;;
    "add")
        add_peer "$2"
        ;;
    "remove"|"delete")
        remove_peer "$2"
        ;;
    "ping"|"test")
        test_ping "$2"
        ;;
    "stats"|"status")
        show_quick_stats
        ;;
    "help"|"--help"|"-h")
        show_help
        ;;
    *)
        log_error "دستور نامعتبر: $1"
        echo
        show_help
        exit 1
        ;;
esac 