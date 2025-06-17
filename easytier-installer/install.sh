#!/bin/bash

# =============================================================================
# 🚀 EasyTier نصب آسان 
# اسکریپت نصب یک‌کلیکه برای EasyTier
# =============================================================================

set -e  # توقف در صورت خطا

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
EASYTIER_REPO="EasyTier/EasyTier"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/easytier"
SERVICE_DIR="/etc/systemd/system"
LOG_FILE="/var/log/easytier-install.log"

# =============================================================================
# تابع‌های کمکی
# =============================================================================

print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════╗"
    echo "║               🚀 EasyTier نصب آسان              ║"
    echo "║          اسکریپت نصب حرفه‌ای و سریع            ║"
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

# تشخیص سیستم عامل
detect_os() {
    print_step "تشخیص سیستم عامل..."
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        OS_VERSION=$VERSION_ID
    else
        print_error "نمی‌توان سیستم عامل را تشخیص داد"
        exit 1
    fi
    
    case $OS in
        *"Ubuntu"*)
            DISTRO="ubuntu"
            PACKAGE_MANAGER="apt"
            ;;
        *"Debian"*)
            DISTRO="debian"
            PACKAGE_MANAGER="apt"
            ;;
        *"CentOS"*|*"Red Hat"*|*"Rocky"*)
            DISTRO="rhel"
            PACKAGE_MANAGER="yum"
            ;;
        *"Fedora"*)
            DISTRO="fedora"
            PACKAGE_MANAGER="dnf"
            ;;
        *)
            print_warning "سیستم عامل شناسایی نشد: $OS"
            print_info "ادامه با تنظیمات عمومی..."
            DISTRO="generic"
            PACKAGE_MANAGER="unknown"
            ;;
    esac
    
    print_success "سیستم عامل: $OS"
    print_info "Distribution: $DISTRO"
}

# تشخیص معماری سیستم
detect_architecture() {
    print_step "تشخیص معماری سیستم..."
    
    local arch=$(uname -m)
    case $arch in
        x86_64|amd64)
            ARCH="x86_64"
            EASYTIER_ARCH="x86_64-unknown-linux-gnu"
            ;;
        aarch64|arm64)
            ARCH="aarch64"
            EASYTIER_ARCH="aarch64-unknown-linux-gnu"
            ;;
        armv7l)
            ARCH="armv7"
            EASYTIER_ARCH="armv7-unknown-linux-gnueabihf"
            ;;
        *)
            print_error "معماری پشتیبانی نشده: $arch"
            print_info "معماری‌های پشتیبانی شده: x86_64, aarch64, armv7l"
            exit 1
            ;;
    esac
    
    print_success "معماری: $ARCH"
    print_info "EasyTier target: $EASYTIER_ARCH"
}

# بررسی پیش‌نیازها
check_prerequisites() {
    print_step "بررسی پیش‌نیازها..."
    
    local missing_tools=()
    
    # بررسی ابزارهای ضروری
    for tool in curl wget unzip systemctl; do
        if ! command -v $tool &> /dev/null; then
            missing_tools+=($tool)
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        print_warning "ابزارهای مورد نیاز یافت نشد: ${missing_tools[*]}"
        install_prerequisites "${missing_tools[@]}"
    else
        print_success "تمام پیش‌نیازها موجود است"
    fi
    
    # بررسی فضای دیسک
    local available_space=$(df /usr/local 2>/dev/null | tail -1 | awk '{print $4}' || echo "0")
    if [[ $available_space -lt 51200 ]]; then  # 50MB
        print_warning "فضای دیسک کم است (کمتر از 50MB)"
    fi
    
    # بررسی اتصال اینترنت
    if ! curl -s --max-time 5 https://api.github.com &> /dev/null; then
        print_error "عدم دسترسی به اینترنت"
        print_info "لطفاً اتصال اینترنت را بررسی کنید"
        exit 1
    fi
    
    print_success "اتصال اینترنت فعال است"
}

# نصب پیش‌نیازها
install_prerequisites() {
    local tools=("$@")
    print_step "نصب پیش‌نیازها..."
    
    case $PACKAGE_MANAGER in
        "apt")
            apt update -qq
            for tool in "${tools[@]}"; do
                if [[ $tool == "systemctl" ]]; then
                    apt install -y systemd
                else
                    apt install -y $tool
                fi
            done
            ;;
        "yum"|"dnf")
            for tool in "${tools[@]}"; do
                if [[ $tool == "systemctl" ]]; then
                    $PACKAGE_MANAGER install -y systemd
                else
                    $PACKAGE_MANAGER install -y $tool
                fi
            done
            ;;
        *)
            print_error "نصب خودکار پیش‌نیازها برای این سیستم پشتیبانی نمی‌شود"
            print_info "لطفاً این ابزارها را دستی نصب کنید: ${tools[*]}"
            exit 1
            ;;
    esac
    
    print_success "پیش‌نیازها نصب شد"
}

# دریافت آخرین نسخه
get_latest_version() {
    print_step "دریافت اطلاعات آخرین نسخه..."
    
    local api_url="https://api.github.com/repos/$EASYTIER_REPO/releases/latest"
    
    if command -v curl &> /dev/null; then
        LATEST_VERSION=$(curl -s "$api_url" | grep '"tag_name"' | cut -d'"' -f4)
    elif command -v wget &> /dev/null; then
        LATEST_VERSION=$(wget -qO- "$api_url" | grep '"tag_name"' | cut -d'"' -f4)
    else
        print_error "نیاز به curl یا wget"
        exit 1
    fi
    
    if [[ -z "$LATEST_VERSION" ]]; then
        print_error "نتوانست آخرین نسخه را دریافت کند"
        exit 1
    fi
    
    print_success "آخرین نسخه: $LATEST_VERSION"
}

# دانلود و نصب EasyTier
download_and_install() {
    print_step "دانلود EasyTier..."
    
    # فرمت اسم فایل صحیح از GitHub releases
    local archive_name="easytier-linux-$ARCH-$LATEST_VERSION.zip"
    local download_url="https://github.com/$EASYTIER_REPO/releases/download/$LATEST_VERSION/$archive_name"
    local temp_dir=$(mktemp -d)
    local archive_file="$temp_dir/easytier.zip"
    
    print_info "URL دانلود: $download_url"
    
    # دانلود فایل
    if command -v curl &> /dev/null; then
        curl -L -o "$archive_file" "$download_url" || {
            print_error "خطا در دانلود فایل"
            exit 1
        }
    else
        wget -O "$archive_file" "$download_url" || {
            print_error "خطا در دانلود فایل"
            exit 1
        }
    fi
    
    print_success "دانلود کامل شد"
    
    # استخراج فایل‌ها
    print_step "استخراج فایل‌ها..."
    cd "$temp_dir"
    unzip -q "$archive_file" || {
        print_error "خطا در استخراج فایل"
        exit 1
    }
    
    # یافتن فایل‌های binary
    local easytier_core=$(find . -name "easytier-core" -type f | head -1)
    local easytier_cli=$(find . -name "easytier-cli" -type f | head -1)
    
    if [[ -z "$easytier_core" ]] || [[ -z "$easytier_cli" ]]; then
        print_error "فایل‌های binary یافت نشد"
        exit 1
    fi
    
    # نصب فایل‌ها
    print_step "نصب فایل‌ها..."
    chmod +x "$easytier_core" "$easytier_cli"
    cp "$easytier_core" "$INSTALL_DIR/"
    cp "$easytier_cli" "$INSTALL_DIR/"
    
    # تمیز کردن فایل‌های موقت
    rm -rf "$temp_dir"
    
    print_success "EasyTier نصب شد در: $INSTALL_DIR"
}

# تست نصب
test_installation() {
    print_step "تست نصب..."
    
    if ! command -v easytier-core &> /dev/null; then
        print_error "easytier-core در PATH یافت نشد"
        exit 1
    fi
    
    if ! command -v easytier-cli &> /dev/null; then
        print_error "easytier-cli در PATH یافت نشد"
        exit 1
    fi
    
    # تست version
    local core_version=$(easytier-core --version 2>/dev/null | head -1 || echo "unknown")
    local cli_version=$(easytier-cli --version 2>/dev/null | head -1 || echo "unknown")
    
    print_success "easytier-core: $core_version"
    print_success "easytier-cli: $cli_version"
}

# ایجاد دایرکتوری config
create_config_directory() {
    print_step "ایجاد دایرکتوری پیکربندی..."
    
    mkdir -p "$CONFIG_DIR"
    chmod 755 "$CONFIG_DIR"
    
    print_success "دایرکتوری پیکربندی: $CONFIG_DIR"
}

# ایجاد فایل پیکربندی اساسی
setup_basic_config() {
    print_step "ایجاد فایل پیکربندی اساسی..."
    
    # مسیر config generator
    local config_generator="$SCRIPT_DIR/utils/config-generator.sh"
    
    if [[ -f "$config_generator" ]]; then
        chmod +x "$config_generator"
        "$config_generator" create
        print_success "فایل پیکربندی اساسی ایجاد شد"
        print_warning "⚠️  برای اتصال به peers، فایل /etc/easytier/config.yml را ویرایش کنید"
    else
        print_warning "config generator یافت نشد - فایل config دستی ایجاد کنید"
    fi
}

# نمایش خلاصه نصب
show_summary() {
    echo -e "\n${GREEN}╔══════════════════════════════════════════════════╗"
    echo "║            🎉 نصب با موفقیت تکمیل شد            ║"
    echo "╚══════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${CYAN}📋 خلاصه نصب:${NC}"
    echo -e "  • نسخه EasyTier: ${GREEN}$LATEST_VERSION${NC}"
    echo -e "  • مسیر نصب: ${GREEN}$INSTALL_DIR${NC}"
    echo -e "  • دایرکتوری config: ${GREEN}$CONFIG_DIR${NC}"
    echo -e "  • لاگ نصب: ${GREEN}$LOG_FILE${NC}"
    echo
    echo -e "${YELLOW}🚀 گام‌های بعدی:${NC}"
    echo -e "  1. برای مدیریت: ${GREEN}sudo moonmesh${NC}"
    echo -e "  2. برای استفاده مستقیم: ${GREEN}sudo easytier-core --help${NC}"
    echo -e "  3. مشاهده راهنما: ${GREEN}cat /etc/easytier/README${NC}"
    echo
}

# =============================================================================
# تابع اصلی
# =============================================================================

main() {
    print_banner
    
    # بررسی‌های اولیه
    check_root
    
    # شروع لاگ
    echo "=== EasyTier Installation Started at $(date) ===" > "$LOG_FILE"
    
    # مراحل نصب
    detect_os
    detect_architecture  
    check_prerequisites
    get_latest_version
    download_and_install
    test_installation
    create_config_directory
    setup_basic_config
    
    # نمایش خلاصه
    show_summary
    
    print_success "نصب EasyTier تکمیل شد! 🎉"
}

# اجرای تابع اصلی
main "$@" 