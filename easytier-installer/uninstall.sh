#!/bin/bash

# =============================================================================
# 🗑️ EasyTier Complete Removal
# Complete uninstallation script for EasyTier and all its components  
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
        print_error "This script requires root access"
        print_info "Please run with sudo: sudo $0"
        exit 1
    fi
}

# تایید حذف از کاربر
confirm_uninstall() {
    echo -e "${YELLOW}"
    echo "⚠️  Warning: This action will remove all EasyTier components:"
    echo "   • systemd service"
    echo "   • binaries"
    echo "   • configuration files"
    echo "   • management scripts"
    echo -e "${NC}"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Operation cancelled"
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
    print_step "Removing binaries..."
    local binaries=(
        "/usr/local/bin/easytier-core"
        "/usr/local/bin/easytier-cli" 
        "/usr/local/bin/moonmesh"
    )
    for binary in "${binaries[@]}"; do
        if [[ -f "$binary" ]]; then
            rm -f "$binary"
            print_success "Removed: $binary"
        else
            print_warning "Not found: $binary"
        fi
    done
}

# حذف فایل سرویس
remove_service() {
    print_step "Removing systemd service file..."
    local service_file="/etc/systemd/system/easytier.service"
    if [[ -f "$service_file" ]]; then
        rm -f "$service_file"
        systemctl daemon-reload
        print_success "Service file removed"
    else
        print_warning "Service file not found"
    fi
}

# حذف فایل‌های پیکربندی
remove_configs() {
    print_step "Removing configuration files..."
    local config_dir="/etc/easytier"
    if [[ -d "$config_dir" ]]; then
        rm -rf "$config_dir"
        print_success "Configuration directory removed: $config_dir"
    else
        print_warning "Configuration directory not found"
    fi
}

# حذف لاگ‌ها (اختیاری)
remove_logs() {
    print_step "Removing log files..."
    read -p "Do you also want to remove log files? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -f /var/log/easytier*.log
        print_success "Log files removed"
    else
        print_info "Log files kept"
    fi
}

# تمیز کردن فایروال
cleanup_firewall() {
    print_step "Checking firewall rules..."
    # UFW cleanup
    if command -v ufw &> /dev/null; then
        if ufw status | grep -q "11010\|11011"; then
            read -p "Do you want to remove EasyTier firewall rules? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                ufw delete allow 11010 2>/dev/null || true
                ufw delete allow 11011 2>/dev/null || true
                print_success "Firewall rules removed"
            fi
        fi
    fi
    # Firewalld cleanup
    if command -v firewall-cmd &> /dev/null; then
        if firewall-cmd --list-ports | grep -q "11010\|11011"; then
            read -p "Do you want to remove EasyTier firewalld rules? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                firewall-cmd --permanent --remove-port=11010/tcp 2>/dev/null || true
                firewall-cmd --permanent --remove-port=11011/udp 2>/dev/null || true
                firewall-cmd --reload 2>/dev/null || true
                print_success "Firewalld rules removed"
            fi
        fi
    fi
}

# تایید نهایی حذف
final_verification() {
    print_step "Final removal verification..."
    local remaining_files=()
    # Check for remaining files
    [[ -f "/usr/local/bin/easytier-core" ]] && remaining_files+=("easytier-core")
    [[ -f "/usr/local/bin/easytier-cli" ]] && remaining_files+=("easytier-cli")
    [[ -f "/usr/local/bin/moonmesh" ]] && remaining_files+=("moonmesh")
    [[ -f "/etc/systemd/system/easytier.service" ]] && remaining_files+=("easytier.service")
    [[ -d "/etc/easytier" ]] && remaining_files+=("/etc/easytier/")
    if [[ ${#remaining_files[@]} -eq 0 ]]; then
        print_success "Full removal completed successfully! 🎉"
        print_info "EasyTier has been completely removed from the system"
    else
        print_warning "Some files still remain:"
        printf '%s\n' "${remaining_files[@]}"
        print_info "Please remove them manually"
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