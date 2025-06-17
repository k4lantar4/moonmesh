#!/bin/bash

# 🔧 EasyTier Troubleshooter
# تسک 10: ابزار troubleshooting مینیمال
# هدف: تست اتصال خودکار + بررسی سرویس + لاگ + restart در صورت خرابی

set -e

# رنگ‌ها
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# متغیرهای کلی
SERVICE_NAME="easytier"
CONFIG_DIR="/etc/easytier"
LOG_FILE="/var/log/easytier-troubleshoot.log"

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

print_critical() {
    echo -e "${RED}💥 $1${NC}"
    echo "$(date): CRITICAL: $1" >> "$LOG_FILE"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "نیاز به دسترسی root"
        exit 1
    fi
}

# تست اتصال خودکار (ping peers)
test_connectivity() {
    print_info "🔍 تست اتصال خودکار..."
    echo
    
    local issues_found=0
    
    # بررسی اتصال اینترنت
    echo -e "${CYAN}1. تست اتصال اینترنت:${NC}"
    if ping -c 2 -W 3 8.8.8.8 >/dev/null 2>&1; then
        print_success "اتصال اینترنت: OK"
    else
        print_error "اتصال اینترنت: ناموفق"
        ((issues_found++))
    fi
    
    # بررسی DNS
    echo -e "${CYAN}2. تست DNS:${NC}"
    if nslookup google.com >/dev/null 2>&1; then
        print_success "DNS Resolution: OK"
    else
        print_warning "DNS Resolution: مشکل"
        ((issues_found++))
    fi
    
    # تست پورت محلی
    echo -e "${CYAN}3. تست پورت EasyTier:${NC}"
    if netstat -tuln 2>/dev/null | grep ":11011 " >/dev/null; then
        print_success "پورت 11011: در حال استفاده"
    else
        print_warning "پورت 11011: آزاد (ممکن است سرویس فعال نباشد)"
        ((issues_found++))
    fi
    
    # تست peers از config
    echo -e "${CYAN}4. تست peers:${NC}"
    if [[ -f "$CONFIG_DIR/config.yml" ]]; then
        local peers=($(grep -o '"[^"]*:[0-9]*"' "$CONFIG_DIR/config.yml" | tr -d '"'))
        
        if [[ ${#peers[@]} -eq 0 ]]; then
            print_warning "هیچ peer در config یافت نشد"
            ((issues_found++))
        else
            for peer in "${peers[@]}"; do
                local peer_ip=$(echo "$peer" | cut -d':' -f1)
                local peer_port=$(echo "$peer" | cut -d':' -f2)
                
                if ping -c 1 -W 2 "$peer_ip" >/dev/null 2>&1; then
                    print_success "Peer $peer_ip: قابل دسترسی"
                else
                    print_error "Peer $peer_ip: غیرقابل دسترسی"
                    ((issues_found++))
                fi
            done
        fi
    else
        print_error "فایل config یافت نشد"
        ((issues_found++))
    fi
    
    # تست تانل داخلی
    echo -e "${CYAN}5. تست تانل داخلی:${NC}"
    if [[ -f "$CONFIG_DIR/config.yml" ]]; then
        local tunnel_ip=$(grep "ipv4:" "$CONFIG_DIR/config.yml" | sed 's/.*"\(.*\)".*/\1/' | head -1)
        
        if [[ -n "$tunnel_ip" ]]; then
            if ping -c 2 -W 2 "$tunnel_ip" >/dev/null 2>&1; then
                print_success "تانل IP $tunnel_ip: قابل دسترسی"
            else
                print_error "تانل IP $tunnel_ip: غیرقابل دسترسی"
                ((issues_found++))
            fi
            
            # تست gateway تانل
            if ping -c 2 -W 2 "10.145.0.1" >/dev/null 2>&1; then
                print_success "Gateway تانل: قابل دسترسی"
            else
                print_warning "Gateway تانل: غیرقابل دسترسی"
                ((issues_found++))
            fi
        fi
    fi
    
    echo
    if [[ $issues_found -eq 0 ]]; then
        print_success "🎉 همه تست‌های اتصال موفق بود!"
        return 0
    else
        print_error "🚨 $issues_found مشکل در اتصال یافت شد"
        return $issues_found
    fi
}

# بررسی وضعیت سرویس
check_service_status() {
    print_info "🔍 بررسی وضعیت سرویس..."
    echo
    
    local service_issues=0
    
    # وضعیت کلی سرویس
    echo -e "${CYAN}1. وضعیت SystemD:${NC}"
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        print_success "سرویس فعال است"
        
        # زمان اجرا
        local uptime=$(systemctl show "$SERVICE_NAME" --property=ActiveEnterTimestamp --value)
        print_info "زمان شروع: $uptime"
        
        # استفاده از Memory
        local memory=$(systemctl show "$SERVICE_NAME" --property=MemoryCurrent --value)
        if [[ "$memory" != "[not set]" && -n "$memory" ]]; then
            local memory_mb=$((memory / 1024 / 1024))
            print_info "استفاده از RAM: ${memory_mb}MB"
        fi
        
    else
        print_error "سرویس غیرفعال است"
        ((service_issues++))
    fi
    
    # وضعیت auto-start
    echo -e "${CYAN}2. Auto-start:${NC}"
    if systemctl is-enabled --quiet "$SERVICE_NAME"; then
        print_success "Auto-start فعال است"
    else
        print_warning "Auto-start غیرفعال است"
        ((service_issues++))
    fi
    
    # بررسی فایل‌های ضروری
    echo -e "${CYAN}3. فایل‌های ضروری:${NC}"
    
    if command -v easytier-core &> /dev/null; then
        print_success "easytier-core موجود است"
    else
        print_error "easytier-core یافت نشد"
        ((service_issues++))
    fi
    
    if command -v easytier-cli &> /dev/null; then
        print_success "easytier-cli موجود است"
    else
        print_error "easytier-cli یافت نشد"
        ((service_issues++))
    fi
    
    if [[ -f "$CONFIG_DIR/config.yml" ]]; then
        print_success "فایل config موجود است"
    else
        print_error "فایل config یافت نشد"
        ((service_issues++))
    fi
    
    # بررسی فایروال
    echo -e "${CYAN}4. فایروال:${NC}"
    if command -v ufw &> /dev/null; then
        if ufw status | grep -q "11011"; then
            print_success "پورت 11011 در فایروال باز است"
        else
            print_warning "پورت 11011 در فایروال یافت نشد"
            ((service_issues++))
        fi
    else
        print_info "ufw نصب نیست"
    fi
    
    echo
    if [[ $service_issues -eq 0 ]]; then
        print_success "🎉 وضعیت سرویس سالم است!"
        return 0
    else
        print_error "🚨 $service_issues مشکل در سرویس یافت شد"
        return $service_issues
    fi
}

# نمایش لاگ آخر (tail)
show_recent_logs() {
    local lines="${1:-20}"
    print_info "📝 آخرین $lines خط لاگ..."
    echo
    
    echo -e "${CYAN}SystemD Logs:${NC}"
    if journalctl -u "$SERVICE_NAME" --no-pager -n "$lines" 2>/dev/null; then
        print_success "لاگ‌های سیستم نمایش داده شد"
    else
        print_warning "خطا در دریافت لاگ‌های سیستم"
    fi
    
    echo
    echo -e "${CYAN}Error Logs (اگر وجود دارد):${NC}"
    journalctl -u "$SERVICE_NAME" --no-pager -p err -n 10 2>/dev/null || print_info "هیچ error log یافت نشد"
    
    echo
    echo -e "${CYAN}Application Logs:${NC}"
    if [[ -f "/var/log/easytier.log" ]]; then
        tail -n "$lines" "/var/log/easytier.log" 2>/dev/null || print_warning "خطا در خواندن فایل لاگ"
    else
        print_info "فایل لاگ application یافت نشد"
    fi
}

# restart در صورت خرابی
auto_fix() {
    print_info "🔧 تلاش برای تعمیر خودکار..."
    echo
    
    local fixed_issues=0
    
    # بررسی وضعیت سرویس
    if ! systemctl is-active --quiet "$SERVICE_NAME"; then
        print_warning "سرویس غیرفعال است - تلاش برای راه‌اندازی..."
        
        if systemctl start "$SERVICE_NAME"; then
            print_success "سرویس با موفقیت راه‌اندازی شد"
            ((fixed_issues++))
            sleep 3
        else
            print_error "خطا در راه‌اندازی سرویس"
        fi
    fi
    
    # فعال‌سازی auto-start
    if ! systemctl is-enabled --quiet "$SERVICE_NAME"; then
        print_warning "Auto-start غیرفعال است - فعال‌سازی..."
        
        if systemctl enable "$SERVICE_NAME"; then
            print_success "Auto-start فعال شد"
            ((fixed_issues++))
        else
            print_error "خطا در فعال‌سازی auto-start"
        fi
    fi
    
    # بررسی فایروال
    if command -v ufw &> /dev/null; then
        if ! ufw status | grep -q "11011"; then
            print_warning "پورت 11011 بسته است - باز کردن..."
            
            if ufw allow 11011/udp comment "EasyTier VPN"; then
                print_success "پورت 11011 باز شد"
                ((fixed_issues++))
            else
                print_error "خطا در باز کردن پورت"
            fi
        fi
    fi
    
    # بررسی IP forwarding
    if [[ "$(sysctl -n net.ipv4.ip_forward)" != "1" ]]; then
        print_warning "IP forwarding غیرفعال است - فعال‌سازی..."
        
        if sysctl -w net.ipv4.ip_forward=1; then
            print_success "IP forwarding فعال شد"
            ((fixed_issues++))
        else
            print_error "خطا در فعال‌سازی IP forwarding"
        fi
    fi
    
    echo
    if [[ $fixed_issues -gt 0 ]]; then
        print_success "🎉 $fixed_issues مشکل تعمیر شد!"
        print_info "در حال تست مجدد..."
        sleep 2
        return 0
    else
        print_info "هیچ مشکل قابل تعمیری یافت نشد"
        return 1
    fi
}

# تشخیص مشکلات کامل
full_diagnosis() {
    print_info "🩺 تشخیص کامل مشکلات EasyTier..."
    echo
    
    local total_issues=0
    
    echo -e "${PURPLE}═══ مرحله 1: بررسی سرویس ═══${NC}"
    check_service_status
    ((total_issues+=$?))
    
    echo
    echo -e "${PURPLE}═══ مرحله 2: تست اتصال ═══${NC}"
    test_connectivity
    ((total_issues+=$?))
    
    echo
    echo -e "${PURPLE}═══ مرحله 3: بررسی لاگ‌ها ═══${NC}"
    show_recent_logs 10
    
    echo
    echo -e "${PURPLE}═══ خلاصه تشخیص ═══${NC}"
    
    if [[ $total_issues -eq 0 ]]; then
        print_success "🎉 هیچ مشکلی یافت نشد! EasyTier سالم است"
    else
        print_error "🚨 مجموعاً $total_issues مشکل یافت شد"
        echo
        print_info "💡 برای تعمیر خودکار: $0 fix"
        print_info "💡 برای restart کامل: sudo systemctl restart easytier"
        print_info "💡 برای مشاهده لاگ زنده: sudo journalctl -u easytier -f"
    fi
    
    return $total_issues
}

# نمایش وضعیت سریع
quick_status() {
    echo -e "${CYAN}⚡ وضعیت سریع EasyTier${NC}"
    echo
    
    # وضعیت سرویس
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo -e "  🟢 سرویس: ${GREEN}فعال${NC}"
    else
        echo -e "  🔴 سرویس: ${RED}غیرفعال${NC}"
    fi
    
    # تعداد peers
    if command -v easytier-cli &> /dev/null && systemctl is-active --quiet "$SERVICE_NAME"; then
        local peer_count=$(easytier-cli peer 2>/dev/null | grep -c "peer_id" || echo "0")
        echo -e "  🔗 Peers: ${BLUE}$peer_count${NC}"
    else
        echo -e "  🔗 Peers: ${YELLOW}نامشخص${NC}"
    fi
    
    # IP تانل
    if [[ -f "$CONFIG_DIR/config.yml" ]]; then
        local tunnel_ip=$(grep "ipv4:" "$CONFIG_DIR/config.yml" | sed 's/.*"\(.*\)".*/\1/' | head -1)
        echo -e "  🌐 IP تانل: ${BLUE}${tunnel_ip:-نامشخص}${NC}"
    fi
    
    # آخرین خطا
    local last_error=$(journalctl -u "$SERVICE_NAME" --no-pager -p err -n 1 --since "1 hour ago" 2>/dev/null | tail -1)
    if [[ -n "$last_error" ]]; then
        echo -e "  ⚠️  آخرین خطا: ${YELLOW}$(echo "$last_error" | cut -c1-50)...${NC}"
    else
        echo -e "  ✅ وضعیت: ${GREEN}سالم${NC}"
    fi
}

# نمایش راهنما
show_help() {
    echo -e "${CYAN}🔧 EasyTier Troubleshooter${NC}"
    echo
    echo "استفاده:"
    echo "  $0 <command>"
    echo
    echo "دستورات:"
    echo "  diagnose    تشخیص کامل مشکلات"
    echo "  connectivity تست اتصال خودکار"
    echo "  service     بررسی وضعیت سرویس"
    echo "  logs [N]    نمایش آخرین N خط لاگ"
    echo "  fix         تعمیر خودکار مشکلات"
    echo "  status      وضعیت سریع"
    echo "  restart     restart سرویس"
    echo "  help        نمایش این راهنما"
    echo
    echo "مثال‌ها:"
    echo "  $0 diagnose      # تشخیص کامل"
    echo "  $0 logs 50       # نمایش 50 خط لاگ"
    echo "  $0 fix           # تعمیر خودکار"
}

# تابع اصلی
main() {
    check_root
    
    case "${1:-help}" in
        diagnose|diagnosis)
            full_diagnosis
            ;;
        connectivity|ping)
            test_connectivity
            ;;
        service|check)
            check_service_status
            ;;
        logs)
            show_recent_logs "${2:-20}"
            ;;
        fix|repair)
            auto_fix
            echo
            print_info "تست مجدد پس از تعمیر..."
            sleep 2
            full_diagnosis
            ;;
        status)
            quick_status
            ;;
        restart)
            print_info "راه‌اندازی مجدد سرویس..."
            systemctl restart "$SERVICE_NAME" && print_success "سرویس راه‌اندازی شد" || print_error "خطا در راه‌اندازی"
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