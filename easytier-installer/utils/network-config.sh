#!/bin/bash

# =============================================================================
# 🌐 EasyTier Network Configuration
# پیکربندی ساده شبکه برای EasyTier
# =============================================================================

set -e

# متغیرهای کلی
EASYTIER_PORT="11011"
VPN_NETWORK="10.144.0.0/24"
LOG_FILE="/var/log/easytier-network.log"

# رنگ‌ها
RED='\033[0;31m'
GREEN='\033[0;32m'  
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# تابع‌های کمکی
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
    echo "$(date): INFO: $1" >> "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    echo "$(date): SUCCESS: $1" >> "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    echo "$(date): WARNING: $1" >> "$LOG_FILE"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    echo "$(date): ERROR: $1" >> "$LOG_FILE"
}

# بررسی دسترسی root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "نیاز به دسترسی root"
        exit 1
    fi
}

# تشخیص IP range آزاد
detect_free_ip_range() {
    print_info "تشخیص IP range آزاد..."
    
    # بررسی آیا 10.144.0.0/24 در حال استفاده است
    if ip route show | grep -q "10.144.0"; then
        print_warning "10.144.0.0/24 احتمالاً در حال استفاده است"
        
        # جستجوی range آزاد در 10.x.x.0/24
        for i in {145..200}; do
            if ! ip route show | grep -q "10.$i.0"; then
                VPN_NETWORK="10.$i.0.0/24"
                print_success "IP range آزاد یافت شد: $VPN_NETWORK"
                return 0
            fi
        done
        
        print_warning "از 10.144.0.0/24 استفاده می‌شود (ممکن است conflict داشته باشد)"
    else
        print_success "10.144.0.0/24 آزاد است و استفاده می‌شود"
    fi
}

# نصب و تنظیم ufw
setup_firewall() {
    print_info "تنظیم firewall (ufw)..."
    
    # نصب ufw اگر موجود نباشد
    if ! command -v ufw &> /dev/null; then
        print_info "نصب ufw..."
        
        if command -v apt &> /dev/null; then
            apt update && apt install -y ufw
        elif command -v yum &> /dev/null; then
            yum install -y ufw
        elif command -v dnf &> /dev/null; then
            dnf install -y ufw
        else
            print_warning "نمی‌توان ufw را نصب کرد - ادامه بدون firewall"
            return 0
        fi
    fi
    
    # فعال‌سازی ufw اگر غیرفعال است
    if ! ufw status | grep -q "Status: active"; then
        print_info "فعال‌سازی ufw..."
        echo "y" | ufw enable
    fi
    
    # اضافه کردن rule برای EasyTier
    print_info "اضافه کردن rule برای پورت $EASYTIER_PORT..."
    
    ufw allow $EASYTIER_PORT/udp comment "EasyTier VPN"
    ufw allow $EASYTIER_PORT/tcp comment "EasyTier VPN TCP"
    
    print_success "Firewall تنظیم شد"
}

# فعال‌سازی IP forwarding
enable_ip_forwarding() {
    print_info "فعال‌سازی IP forwarding..."
    
    # بررسی وضعیت فعلی
    current_ipv4=$(sysctl -n net.ipv4.ip_forward)
    
    if [[ "$current_ipv4" == "1" ]]; then
        print_success "IP forwarding قبلاً فعال است"
        return 0
    fi
    
    # فعال‌سازی موقت
    print_info "فعال‌سازی موقت IP forwarding..."
    sysctl -w net.ipv4.ip_forward=1
    
    # فعال‌سازی دائمی
    print_info "تنظیم دائمی IP forwarding..."
    
    if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
        print_success "IP forwarding دائمی فعال شد"
    else
        # اگر خط موجود است ولی commented است
        sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
        print_success "IP forwarding دائمی فعال شد"
    fi
    
    # reload sysctl
    sysctl -p /etc/sysctl.conf
}

# تنظیم مسیریابی ساده
setup_basic_routing() {
    print_info "تنظیم مسیریابی پایه..."
    
    # بررسی interface های شبکه
    main_interface=$(ip route | grep default | awk '{print $5}' | head -1)
    
    if [[ -z "$main_interface" ]]; then
        print_warning "نمی‌توان interface اصلی را تشخیص داد"
        return 0
    fi
    
    print_success "Interface اصلی: $main_interface"
    
    # اضافه کردن masquerade rule (اگر iptables موجود باشد)
    if command -v iptables &> /dev/null; then
        print_info "تنظیم NAT masquerading..."
        
        # حذف rule قدیمی (اگر وجود دارد)
        iptables -t nat -D POSTROUTING -s ${VPN_NETWORK} -o $main_interface -j MASQUERADE 2>/dev/null || true
        
        # اضافه کردن rule جدید
        iptables -t nat -A POSTROUTING -s ${VPN_NETWORK} -o $main_interface -j MASQUERADE
        
        print_success "NAT masquerading تنظیم شد"
        
        # ذخیره rules (اگر امکان دارد)
        if command -v iptables-save &> /dev/null; then
            iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
        fi
    else
        print_warning "iptables موجود نیست - NAT تنظیم نشد"
    fi
}

# بررسی اتصال شبکه
test_network_connectivity() {
    print_info "تست اتصال شبکه..."
    
    # تست DNS
    if ping -c 1 8.8.8.8 &> /dev/null; then
        print_success "اتصال اینترنت: OK"
    else
        print_warning "مشکل در اتصال اینترنت"
    fi
    
    # تست پورت EasyTier
    if netstat -tuln 2>/dev/null | grep ":$EASYTIER_PORT " &> /dev/null; then
        print_success "پورت $EASYTIER_PORT: در حال استفاده (احتمالاً EasyTier)"
    else
        print_info "پورت $EASYTIER_PORT: آزاد"
    fi
}

# نمایش خلاصه تنظیمات
show_network_summary() {
    print_info "خلاصه تنظیمات شبکه:"
    echo
    echo "🌐 شبکه VPN: $VPN_NETWORK"
    echo "🔌 پورت: $EASYTIER_PORT"
    echo "🔥 Firewall: $(ufw status | head -1)"
    echo "📡 IP Forwarding: $(sysctl -n net.ipv4.ip_forward)"
    echo "🖧 Interface اصلی: $(ip route | grep default | awk '{print $5}' | head -1)"
    echo
}

# تمیزکاری (در صورت نیاز)
cleanup_network() {
    print_info "تمیزکاری تنظیمات شبکه..."
    
    # حذف firewall rules
    if command -v ufw &> /dev/null; then
        ufw delete allow $EASYTIER_PORT/udp 2>/dev/null || true
        ufw delete allow $EASYTIER_PORT/tcp 2>/dev/null || true
        print_success "Firewall rules حذف شد"
    fi
    
    # حذف iptables rules
    if command -v iptables &> /dev/null; then
        main_interface=$(ip route | grep default | awk '{print $5}' | head -1)
        if [[ -n "$main_interface" ]]; then
            iptables -t nat -D POSTROUTING -s ${VPN_NETWORK} -o $main_interface -j MASQUERADE 2>/dev/null || true
            print_success "NAT rules حذف شد"
        fi
    fi
    
    print_success "تمیزکاری کامل شد"
}

# نمایش راهنما
show_help() {
    echo -e "${BLUE}🌐 EasyTier Network Configuration${NC}"
    echo
    echo "استفاده:"
    echo "  $0 <command>"
    echo
    echo "دستورات:"
    echo "  setup       تنظیم کامل شبکه"
    echo "  test        تست اتصال شبکه"
    echo "  status      نمایش وضعیت شبکه"
    echo "  cleanup     تمیزکاری تنظیمات"
    echo "  help        نمایش این راهنما"
    echo
}

# تابع اصلی
main() {
    check_root
    
    case "${1:-help}" in
        setup)
            print_info "شروع تنظیم شبکه EasyTier..."
            detect_free_ip_range
            setup_firewall
            enable_ip_forwarding
            setup_basic_routing
            test_network_connectivity
            show_network_summary
            print_success "تنظیم شبکه تکمیل شد!"
            ;;
        test)
            test_network_connectivity
            ;;
        status)
            show_network_summary
            ;;
        cleanup)
            cleanup_network
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "دستور نامعتبر: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# اجرای تابع اصلی
main "$@" 