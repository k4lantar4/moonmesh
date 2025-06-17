#!/bin/bash

# =============================================================================
# 🗑️ EasyTier حذف کامل
# اسکریپت حذف کامل برای EasyTier و تمام اجزای آن
# =============================================================================

set -e

# رنگ‌ها برای output زیبا
RED='\033[0;31m'
GREEN='\033[0;32m'  
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# اطلاعات پروژه
SCRIPT_VERSION="1.0.0"
LOG_FILE="/var/log/easytier-uninstall.log"

# =============================================================================
# تابع‌های کمکی
# =============================================================================

print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════╗"
    echo "║               🗑️ EasyTier حذف کامل              ║"
    echo "║         اسکریپت حذف ایمن و کامل               ║"
    echo "║                  نسخه: $SCRIPT_VERSION                  ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
    log_message "INFO" "$1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    log_message "SUCCESS" "$1"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    log_message "WARNING" "$1"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    log_message "ERROR" "$1"
}

print_step() {
    echo -e "\n${PURPLE}🔧 $1${NC}"
    log_message "STEP" "$1"
}

# بررسی دسترسی root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "این اسکریپت نیاز به دسترسی root دارد"
        print_info "لطفاً با sudo اجرا کنید: sudo $0"
        exit 1
    fi
}

# تایید حذف از کاربر
confirm_uninstall() {
    echo -e "${YELLOW}"
    echo "⚠️  هشدار: این عمل تمام اجزای EasyTier را حذف خواهد کرد:"
    echo "   • سرویس systemd"
    echo "   • فایل‌های اجرایی"
    echo "   • فایل‌های پیکربندی"
    echo "   • اسکریپت‌های مدیریتی"
    echo -e "${NC}"
    
    read -p "آیا مطمئن هستید که می‌خواهید ادامه دهید؟ (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "عملیات لغو شد"
        exit 0
    fi
}

# توقف سرویس
stop_service() {
    print_step "توقف سرویس EasyTier..."
    
    if systemctl is-active easytier >/dev/null 2>&1; then
        print_info "توقف سرویس easytier..."
        systemctl stop easytier
        print_success "سرویس متوقف شد"
    else
        print_warning "سرویس در حال اجرا نبود"
    fi
    
    if systemctl is-enabled easytier >/dev/null 2>&1; then
        print_info "غیرفعال کردن auto-start..."
        systemctl disable easytier
        print_success "Auto-start غیرفعال شد"
    fi
}

# حذف فایل‌های اجرایی
remove_binaries() {
    print_step "حذف فایل‌های اجرایی..."
    
    local binaries=(
        "/usr/local/bin/easytier-core"
        "/usr/local/bin/easytier-cli" 
        "/usr/local/bin/moonmesh"
    )
    
    for binary in "${binaries[@]}"; do
        if [[ -f "$binary" ]]; then
            rm -f "$binary"
            print_success "حذف شد: $binary"
        else
            print_warning "یافت نشد: $binary"
        fi
    done
}

# حذف فایل سرویس
remove_service() {
    print_step "حذف فایل سرویس systemd..."
    
    local service_file="/etc/systemd/system/easytier.service"
    
    if [[ -f "$service_file" ]]; then
        rm -f "$service_file"
        systemctl daemon-reload
        print_success "فایل سرویس حذف شد"
    else
        print_warning "فایل سرویس یافت نشد"
    fi
}

# حذف فایل‌های پیکربندی
remove_configs() {
    print_step "حذف فایل‌های پیکربندی..."
    
    local config_dir="/etc/easytier"
    
    if [[ -d "$config_dir" ]]; then
        rm -rf "$config_dir"
        print_success "دایرکتوری پیکربندی حذف شد: $config_dir"
    else
        print_warning "دایرکتوری پیکربندی یافت نشد"
    fi
}

# حذف لاگ‌ها (اختیاری)
remove_logs() {
    print_step "حذف فایل‌های لاگ..."
    
    read -p "آیا می‌خواهید فایل‌های لاگ را نیز حذف کنید؟ (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -f /var/log/easytier*.log
        print_success "فایل‌های لاگ حذف شدند"
    else
        print_info "فایل‌های لاگ نگهداری شدند"
    fi
}

# تمیز کردن فایروال
cleanup_firewall() {
    print_step "بررسی قوانین فایروال..."
    
    # UFW cleanup
    if command -v ufw &> /dev/null; then
        if ufw status | grep -q "11010\|11011"; then
            read -p "آیا می‌خواهید قوانین فایروال EasyTier را حذف کنید؟ (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                ufw delete allow 11010 2>/dev/null || true
                ufw delete allow 11011 2>/dev/null || true
                print_success "قوانین فایروال حذف شدند"
            fi
        fi
    fi
    
    # Firewalld cleanup
    if command -v firewall-cmd &> /dev/null; then
        if firewall-cmd --list-ports | grep -q "11010\|11011"; then
            read -p "آیا می‌خواهید قوانین firewalld EasyTier را حذف کنید؟ (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                firewall-cmd --permanent --remove-port=11010/tcp 2>/dev/null || true
                firewall-cmd --permanent --remove-port=11011/udp 2>/dev/null || true
                firewall-cmd --reload 2>/dev/null || true
                print_success "قوانین firewalld حذف شدند"
            fi
        fi
    fi
}

# تایید نهایی حذف
final_verification() {
    print_step "تایید نهایی حذف..."
    
    local remaining_files=()
    
    # بررسی فایل‌های باقی‌مانده
    [[ -f "/usr/local/bin/easytier-core" ]] && remaining_files+=("easytier-core")
    [[ -f "/usr/local/bin/easytier-cli" ]] && remaining_files+=("easytier-cli")
    [[ -f "/usr/local/bin/moonmesh" ]] && remaining_files+=("moonmesh")
    [[ -f "/etc/systemd/system/easytier.service" ]] && remaining_files+=("easytier.service")
    [[ -d "/etc/easytier" ]] && remaining_files+=("/etc/easytier/")
    
    if [[ ${#remaining_files[@]} -eq 0 ]]; then
        print_success "حذف کامل با موفقیت انجام شد! 🎉"
        print_info "EasyTier به‌طور کامل از سیستم حذف شد"
    else
        print_warning "برخی فایل‌ها همچنان باقی مانده‌اند:"
        printf '%s\n' "${remaining_files[@]}"
        print_info "لطفاً به‌صورت دستی حذف کنید"
    fi
}

# =============================================================================
# اجرای اصلی
# =============================================================================

main() {
    print_banner
    
    check_root
    confirm_uninstall
    
    stop_service
    remove_binaries  
    remove_service
    remove_configs
    remove_logs
    cleanup_firewall
    final_verification
    
    print_success "فرآیند حذف با موفقیت تکمیل شد!"
    echo -e "${CYAN}📋 لاگ کامل در: $LOG_FILE${NC}"
}

# اجرای اصلی
main "$@" 