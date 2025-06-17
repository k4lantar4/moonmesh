#!/bin/bash

# ⚡ EasyTier Performance Optimizer
# تسک 8: بهینه‌سازی performance مینیمال
# هدف: تنظیم MTU + buffer + sysctl ضروری

set -e

# رنگ‌ها
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# متغیرهای کلی
OPTIMAL_MTU="1420"
BUFFER_SIZE="4096"
LOG_FILE="/var/log/easytier-performance.log"

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

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "نیاز به دسترسی root"
        exit 1
    fi
}

# تنظیم MTU مناسب
optimize_mtu() {
    print_info "بهینه‌سازی MTU..."
    
    # تشخیص interface اصلی
    main_interface=$(ip route | grep default | awk '{print $5}' | head -1)
    
    if [[ -z "$main_interface" ]]; then
        print_warning "نمی‌توان interface اصلی را تشخیص داد"
        return 0
    fi
    
    print_info "Interface اصلی: $main_interface"
    
    # دریافت MTU فعلی
    current_mtu=$(ip link show "$main_interface" | grep -o 'mtu [0-9]*' | awk '{print $2}')
    print_info "MTU فعلی: $current_mtu"
    
    # بررسی آیا نیاز به تغییر دارد
    if [[ "$current_mtu" -le 1500 ]] && [[ "$current_mtu" -ge 1420 ]]; then
        print_success "MTU مناسب است ($current_mtu)"
        return 0
    fi
    
    # تنظیم MTU بهینه برای VPN
    print_info "تنظیم MTU بهینه ($OPTIMAL_MTU) برای EasyTier..."
    
    # تنظیم موقت
    if ip link set dev "$main_interface" mtu "$OPTIMAL_MTU" 2>/dev/null; then
        print_success "MTU موقت تنظیم شد: $OPTIMAL_MTU"
    else
        print_warning "نمی‌توان MTU را تغییر داد (ممکن است نیاز به restart شبکه باشد)"
    fi
    
    # یادداشت برای تنظیم دائمی
    print_info "💡 برای تنظیم دائمی MTU، فایل network config را ویرایش کنید"
}

# بهینه‌سازی buffer size
optimize_buffers() {
    print_info "بهینه‌سازی buffer sizes..."
    
    # تنظیمات بهینه برای VPN
    declare -A buffer_settings=(
        ["net.core.rmem_max"]="16777216"
        ["net.core.wmem_max"]="16777216"
        ["net.core.rmem_default"]="262144"
        ["net.core.wmem_default"]="262144"
        ["net.ipv4.udp_mem"]="102400 873800 16777216"
        ["net.ipv4.udp_rmem_min"]="8192"
        ["net.ipv4.udp_wmem_min"]="8192"
    )
    
    # اعمال تنظیمات موقت
    for setting in "${!buffer_settings[@]}"; do
        current_value=$(sysctl -n "$setting" 2>/dev/null || echo "0")
        new_value="${buffer_settings[$setting]}"
        
        if [[ "$current_value" != "$new_value" ]]; then
            print_info "تنظیم $setting = $new_value"
            sysctl -w "$setting=$new_value" >/dev/null 2>&1 || print_warning "خطا در تنظیم $setting"
        else
            print_success "$setting قبلاً بهینه است"
        fi
    done
    
    print_success "Buffer sizes بهینه‌سازی شد"
}

# تنظیم sysctl های ضروری
optimize_sysctl() {
    print_info "تنظیم sysctl های ضروری برای VPN..."
    
    # تنظیمات اساسی برای بهبود performance
    declare -A sysctl_settings=(
        ["net.ipv4.ip_forward"]="1"
        ["net.ipv4.conf.all.forwarding"]="1"
        ["net.ipv4.conf.default.forwarding"]="1"
        ["net.ipv4.tcp_congestion_control"]="bbr"
        ["net.core.default_qdisc"]="fq"
        ["net.ipv4.tcp_fastopen"]="3"
        ["net.ipv4.tcp_low_latency"]="1"
        ["net.ipv4.tcp_no_metrics_save"]="1"
    )
    
    # اعمال تنظیمات
    for setting in "${!sysctl_settings[@]}"; do
        current_value=$(sysctl -n "$setting" 2>/dev/null || echo "")
        new_value="${sysctl_settings[$setting]}"
        
        # بررسی ویژگی‌های اختیاری
        if [[ "$setting" == "net.ipv4.tcp_congestion_control" ]] && ! lsmod | grep -q bbr; then
            print_warning "BBR congestion control در دسترس نیست - استفاده از پیشفرض"
            continue
        fi
        
        if [[ "$current_value" != "$new_value" ]]; then
            print_info "تنظیم $setting = $new_value"
            sysctl -w "$setting=$new_value" >/dev/null 2>&1 || print_warning "خطا در تنظیم $setting"
        else
            print_success "$setting قبلاً تنظیم شده"
        fi
    done
}

# ذخیره تنظیمات دائمی
save_permanent_settings() {
    print_info "ذخیره تنظیمات دائمی..."
    
    # فایل backup
    if [[ -f /etc/sysctl.conf ]]; then
        cp /etc/sysctl.conf /etc/sysctl.conf.backup.$(date +%s)
        print_info "Backup ایجاد شد: /etc/sysctl.conf.backup.*"
    fi
    
    # اضافه کردن تنظیمات EasyTier
    cat >> /etc/sysctl.conf << 'EOF'

# EasyTier Performance Optimizations
# تولید شده توسط performance-optimizer.sh

# IP Forwarding (ضروری برای VPN)
net.ipv4.ip_forward=1
net.ipv4.conf.all.forwarding=1
net.ipv4.conf.default.forwarding=1

# Buffer Optimizations
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.core.rmem_default=262144
net.core.wmem_default=262144
net.ipv4.udp_mem=102400 873800 16777216
net.ipv4.udp_rmem_min=8192
net.ipv4.udp_wmem_min=8192

# TCP Optimizations (اختیاری)
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_low_latency=1
net.ipv4.tcp_no_metrics_save=1

EOF
    
    # اعمال تنظیمات
    sysctl -p /etc/sysctl.conf >/dev/null 2>&1
    print_success "تنظیمات دائمی ذخیره شد"
}

# تست performance
test_performance() {
    print_info "تست کیفیت شبکه..."
    
    # تست latency
    if ping -c 3 8.8.8.8 >/dev/null 2>&1; then
        latency=$(ping -c 3 8.8.8.8 | tail -1 | awk -F'/' '{print $5}')
        print_success "Latency میانگین: ${latency}ms"
    else
        print_warning "تست latency ناموفق"
    fi
    
    # تست throughput ساده
    if command -v iperf3 &> /dev/null; then
        print_info "iperf3 موجود است - می‌توانید throughput test کنید"
    else
        print_info "برای تست throughput، iperf3 نصب کنید: apt install iperf3"
    fi
    
    # نمایش تنظیمات فعلی
    echo
    print_info "خلاصه تنظیمات:"
    echo "  🔧 MTU: $(ip link show $(ip route | grep default | awk '{print $5}' | head -1) | grep -o 'mtu [0-9]*' | awk '{print $2}' || echo 'نامشخص')"
    echo "  📡 IP Forward: $(sysctl -n net.ipv4.ip_forward)"
    echo "  💾 Buffer Max: $(sysctl -n net.core.rmem_max)"
    echo "  ⚡ TCP FastOpen: $(sysctl -n net.ipv4.tcp_fastopen 2>/dev/null || echo 'غیرفعال')"
}

# حذف تنظیمات (cleanup)
cleanup_settings() {
    print_info "حذف تنظیمات performance..."
    
    # حذف از sysctl.conf
    if [[ -f /etc/sysctl.conf ]]; then
        sed -i '/# EasyTier Performance Optimizations/,/^$/d' /etc/sysctl.conf
        print_success "تنظیمات از sysctl.conf حذف شد"
    fi
    
    print_info "برای اعمال کامل تغییرات، سیستم را restart کنید"
}

# نمایش راهنما
show_help() {
    echo -e "${CYAN}⚡ EasyTier Performance Optimizer${NC}"
    echo
    echo "استفاده:"
    echo "  $0 <command>"
    echo
    echo "دستورات:"
    echo "  optimize    بهینه‌سازی کامل performance"
    echo "  mtu         تنظیم MTU مناسب"
    echo "  buffers     بهینه‌سازی buffer sizes"
    echo "  sysctl      تنظیم kernel parameters"
    echo "  test        تست performance"
    echo "  save        ذخیره تنظیمات دائمی"
    echo "  cleanup     حذف تنظیمات"
    echo "  status      نمایش وضعیت فعلی"
    echo "  help        نمایش این راهنما"
    echo
}

# تابع اصلی
main() {
    check_root
    
    case "${1:-help}" in
        optimize)
            print_info "شروع بهینه‌سازی کامل EasyTier..."
            optimize_mtu
            optimize_buffers
            optimize_sysctl
            save_permanent_settings
            test_performance
            print_success "بهینه‌سازی کامل شد! 🚀"
            ;;
        mtu)
            optimize_mtu
            ;;
        buffers)
            optimize_buffers
            ;;
        sysctl)
            optimize_sysctl
            ;;
        test)
            test_performance
            ;;
        save)
            save_permanent_settings
            ;;
        cleanup)
            cleanup_settings
            ;;
        status)
            test_performance
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