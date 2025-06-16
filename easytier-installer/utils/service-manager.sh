#!/bin/bash

# =============================================================================
# 🛠️ EasyTier SystemD Service Manager
# مدیریت ساده سرویس EasyTier
# =============================================================================

set -e

# متغیرهای کلی
SERVICE_NAME="easytier"
SERVICE_FILE="easytier.service"
CONFIG_DIR="/etc/easytier"
SERVICE_DIR="/etc/systemd/system"
LOG_FILE="/var/log/easytier-service.log"

# رنگ‌ها
RED='\033[0;31m'
GREEN='\033[0;32m'  
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# تابع‌های کمکی
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# بررسی دسترسی root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "نیاز به دسترسی root"
        exit 1
    fi
}

# نصب سرویس
install_service() {
    print_info "نصب EasyTier systemd service..."
    
    # کپی فایل service
    if [[ -f "systemd/$SERVICE_FILE" ]]; then
        cp "systemd/$SERVICE_FILE" "$SERVICE_DIR/"
        print_success "فایل service کپی شد"
    else
        print_error "فایل service یافت نشد"
        exit 1
    fi
    
    # کپی config پیش‌فرض
    if [[ -f "config/default.toml" ]]; then
        cp "config/default.toml" "$CONFIG_DIR/config.toml"
        print_success "فایل config کپی شد"
    fi
    
    # reload systemd
    systemctl daemon-reload
    print_success "systemd daemon reload شد"
    
    print_success "سرویس EasyTier نصب شد"
}

# فعال‌سازی auto-start
enable_service() {
    print_info "فعال‌سازی auto-start..."
    
    systemctl enable $SERVICE_NAME
    print_success "auto-start فعال شد"
}

# غیرفعال‌سازی auto-start  
disable_service() {
    print_info "غیرفعال‌سازی auto-start..."
    
    systemctl disable $SERVICE_NAME
    print_success "auto-start غیرفعال شد"
}

# شروع سرویس
start_service() {
    print_info "شروع سرویس EasyTier..."
    
    systemctl start $SERVICE_NAME
    print_success "سرویس شروع شد"
}

# توقف سرویس
stop_service() {
    print_info "توقف سرویس EasyTier..."
    
    systemctl stop $SERVICE_NAME
    print_success "سرویس متوقف شد"
}

# ری‌استارت سرویس
restart_service() {
    print_info "ری‌استارت سرویس EasyTier..."
    
    systemctl restart $SERVICE_NAME
    print_success "سرویس ری‌استارت شد"
}

# نمایش وضعیت
show_status() {
    print_info "وضعیت سرویس EasyTier:"
    echo
    
    # نمایش وضعیت کلی
    if systemctl is-active --quiet $SERVICE_NAME; then
        print_success "سرویس: فعال و در حال اجرا"
    else
        print_warning "سرویس: غیرفعال"
    fi
    
    if systemctl is-enabled --quiet $SERVICE_NAME; then
        print_success "Auto-start: فعال"
    else
        print_warning "Auto-start: غیرفعال"
    fi
    
    echo
    echo "📊 جزئیات وضعیت:"
    systemctl status $SERVICE_NAME --no-pager -l
}

# نمایش لاگ‌ها
show_logs() {
    local lines="${1:-50}"
    print_info "آخرین $lines خط از لاگ‌ها:"
    echo
    
    journalctl -u $SERVICE_NAME -n $lines --no-pager
}

# نمایش لاگ‌های زنده
follow_logs() {
    print_info "نمایش لاگ‌های زنده (Ctrl+C برای خروج):"
    echo
    
    journalctl -u $SERVICE_NAME -f
}

# حذف سرویس
uninstall_service() {
    print_info "حذف سرویس EasyTier..."
    
    # توقف سرویس
    if systemctl is-active --quiet $SERVICE_NAME; then
        systemctl stop $SERVICE_NAME
        print_success "سرویس متوقف شد"
    fi
    
    # غیرفعال‌سازی
    if systemctl is-enabled --quiet $SERVICE_NAME; then
        systemctl disable $SERVICE_NAME
        print_success "auto-start غیرفعال شد"
    fi
    
    # حذف فایل service
    if [[ -f "$SERVICE_DIR/$SERVICE_FILE" ]]; then
        rm -f "$SERVICE_DIR/$SERVICE_FILE"
        print_success "فایل service حذف شد"
    fi
    
    # reload systemd
    systemctl daemon-reload
    systemctl reset-failed
    
    print_success "سرویس EasyTier حذف شد"
}

# نمایش راهنما
show_help() {
    echo -e "${BLUE}🛠️ EasyTier Service Manager${NC}"
    echo
    echo "استفاده:"
    echo "  $0 <command>"
    echo
    echo "دستورات:"
    echo "  install     نصب سرویس systemd"
    echo "  enable      فعال‌سازی auto-start"
    echo "  disable     غیرفعال‌سازی auto-start"
    echo "  start       شروع سرویس"
    echo "  stop        توقف سرویس"
    echo "  restart     ری‌استارت سرویس"
    echo "  status      نمایش وضعیت"
    echo "  logs        نمایش لاگ‌ها"
    echo "  follow      نمایش لاگ‌های زنده"
    echo "  uninstall   حذف سرویس"
    echo "  help        نمایش این راهنما"
    echo
}

# تابع اصلی
main() {
    check_root
    
    case "${1:-help}" in
        install)
            install_service
            ;;
        enable)
            enable_service
            ;;
        disable)
            disable_service
            ;;
        start)
            start_service
            ;;
        stop)
            stop_service
            ;;
        restart)
            restart_service
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs "${2:-50}"
            ;;
        follow)
            follow_logs
            ;;
        uninstall)
            uninstall_service
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