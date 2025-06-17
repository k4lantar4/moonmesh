#!/bin/bash

# =============================================================================
# 🚀 EasyTier Easy Installation 
# One-click installation script for EasyTier
# =============================================================================

set -e  # Stop on error

# Colors for beautiful output
RED='\033[0;31m'
GREEN='\033[0;32m'  
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Project information
SCRIPT_VERSION="1.0.0"
EASYTIER_REPO="EasyTier/EasyTier"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/easytier"
SERVICE_DIR="/etc/systemd/system"
LOG_FILE="/var/log/easytier-install.log"

# =============================================================================
# Helper functions
# =============================================================================

print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════╗"
    echo "║               🚀 EasyTier Easy Install           ║"
    echo "║          Professional & Fast Installation        ║"
    echo "║                  Version: $SCRIPT_VERSION                  ║"
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

# Check root access
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script requires root access"
        print_info "Please run with sudo: sudo $0"
        exit 1
    fi
}

# Detect operating system
detect_os() {
    print_step "Detecting operating system..."
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        OS_VERSION=$VERSION_ID
    else
        print_error "Cannot detect operating system"
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
            print_warning "Unknown operating system: $OS"
            print_info "Continuing with generic settings..."
            DISTRO="generic"
            PACKAGE_MANAGER="unknown"
            ;;
    esac
    
    print_success "Operating system: $OS"
    print_info "Distribution: $DISTRO"
}

# Detect system architecture
detect_architecture() {
    print_step "Detecting system architecture..."
    
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
            print_error "Unsupported architecture: $arch"
            print_info "Supported architectures: x86_64, aarch64, armv7l"
            exit 1
            ;;
    esac
    
    print_success "Architecture: $ARCH"
    print_info "EasyTier target: $EASYTIER_ARCH"
}

# بررسی پیش‌نیازها
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    local missing_tools=()
    
    # بررسی ابزارهای ضروری
    for tool in curl wget unzip systemctl; do
        if ! command -v $tool &> /dev/null; then
            missing_tools+=($tool)
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        print_warning "Required tools not found: ${missing_tools[*]}"
        install_prerequisites "${missing_tools[@]}"
    else
        print_success "All prerequisites are available"
    fi
    
    # بررسی فضای دیسک
    local available_space=$(df /usr/local 2>/dev/null | tail -1 | awk '{print $4}' || echo "0")
    if [[ $available_space -lt 51200 ]]; then  # 50MB
        print_warning "Low disk space (less than 50MB)"
    fi
    
    # بررسی اتصال اینترنت
    if ! curl -s --max-time 5 https://api.github.com &> /dev/null; then
        print_error "No internet access"
        print_info "Please check your internet connection"
        exit 1
    fi
    
    print_success "Internet connection is active"
}

# نصب پیش‌نیازها
install_prerequisites() {
    local tools=("$@")
    print_step "Installing prerequisites..."
    
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
    print_step "Getting latest version information..."
    
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

# توقف سرویس‌های موجود
stop_existing_services() {
    print_step "Checking and stopping existing services..."
    
    # توقف سرویس systemd (در صورت وجود)
    if systemctl is-active easytier >/dev/null 2>&1; then
        print_warning "سرویس easytier در حال اجرا است - متوقف می‌شود..."
        systemctl stop easytier || print_warning "خطا در توقف سرویس"
        sleep 2
    fi
    
    # غیرفعال کردن سرویس اگر فعال باشد
    if systemctl is-enabled easytier >/dev/null 2>&1; then
        print_info "غیرفعال کردن سرویس قدیمی..."
        systemctl disable easytier >/dev/null 2>&1 || true
    fi
    
    # kill کردن فرآیندهای easytier
    local easytier_pids=$(pgrep -f "easytier" 2>/dev/null || true)
    if [[ -n "$easytier_pids" ]]; then
        print_warning "فرآیندهای easytier یافت شد - متوقف می‌شوند..."
        echo "$easytier_pids" | xargs -r kill -TERM 2>/dev/null || true
        sleep 3
        
        # اگر هنوز در حال اجرا بودند، force kill
        easytier_pids=$(pgrep -f "easytier" 2>/dev/null || true)
        if [[ -n "$easytier_pids" ]]; then
            print_warning "فرآیندها هنوز فعال هستند - force kill..."
            echo "$easytier_pids" | xargs -r kill -KILL 2>/dev/null || true
            sleep 1
        fi
    fi
    
    print_success "بررسی سرویس‌های موجود تکمیل شد"
}

# تمیز کردن فایل‌های backup
cleanup_backups() {
    print_info "تمیز کردن فایل‌های backup..."
    
    # حذف فایل‌های backup (در صورت وجود)
    rm -f "$INSTALL_DIR/easytier-core.backup" 2>/dev/null || true
    rm -f "$INSTALL_DIR/easytier-cli.backup" 2>/dev/null || true
    rm -f "$INSTALL_DIR/moonmesh.backup" 2>/dev/null || true
    
    print_success "فایل‌های backup تمیز شدند"
}

# دانلود و نصب EasyTier
download_and_install() {
    print_step "Downloading EasyTier..."
    
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
    print_step "Extracting files..."
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
    print_step "Installing files..."
    
    # توقف سرویس‌های در حال اجرا (در صورت وجود)
    stop_existing_services
    
    chmod +x "$easytier_core" "$easytier_cli"
    
    # تلاش برای copy با مدیریت خطا
    if ! cp "$easytier_core" "$INSTALL_DIR/" 2>/dev/null; then
        print_warning "فایل easytier-core در حال استفاده است - تلاش برای بروزرسانی..."
        
        # backup فایل قدیمی
        if [[ -f "$INSTALL_DIR/easytier-core" ]]; then
            mv "$INSTALL_DIR/easytier-core" "$INSTALL_DIR/easytier-core.backup" || {
                print_error "نمی‌توان فایل قدیمی را جابجا کرد"
                exit 1
            }
        fi
        
        # دوباره تلاش کنیم
        cp "$easytier_core" "$INSTALL_DIR/" || {
            print_error "خطا در کپی فایل easytier-core"
            exit 1
        }
    fi
    
    if ! cp "$easytier_cli" "$INSTALL_DIR/" 2>/dev/null; then
        print_warning "فایل easytier-cli در حال استفاده است - تلاش برای بروزرسانی..."
        
        # backup فایل قدیمی
        if [[ -f "$INSTALL_DIR/easytier-cli" ]]; then
            mv "$INSTALL_DIR/easytier-cli" "$INSTALL_DIR/easytier-cli.backup" || {
                print_error "نمی‌توان فایل قدیمی را جابجا کرد"
                exit 1
            }
        fi
        
        # دوباره تلاش کنیم
        cp "$easytier_cli" "$INSTALL_DIR/" || {
            print_error "خطا در کپی فایل easytier-cli"
            exit 1
        }
    fi
    
    # دانلود moonmesh script
    print_info "دانلود اسکریپت moonmesh..."
    local moonmesh_url="https://raw.githubusercontent.com/k4lantar4/moonmesh/main/easytier-installer/moonmesh"
    curl -fsSL "$moonmesh_url" -o "$INSTALL_DIR/moonmesh" || {
        print_warning "خطا در دانلود moonmesh - ادامه بدون منوی مدیریت"
    }
    
    if [[ -f "$INSTALL_DIR/moonmesh" ]]; then
        chmod +x "$INSTALL_DIR/moonmesh"
        print_success "moonmesh نصب شد"
    fi
    
    # تمیز کردن فایل‌های موقت و backup
    rm -rf "$temp_dir"
    cleanup_backups
    
    print_success "EasyTier نصب شد در: $INSTALL_DIR"
}

# تست نصب
test_installation() {
    print_step "Testing installation..."
    
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
    print_step "Creating configuration directory..."
    
    mkdir -p "$CONFIG_DIR"
    chmod 755 "$CONFIG_DIR"
    
    print_success "دایرکتوری پیکربندی: $CONFIG_DIR"
}

# ایجاد فایل پیکربندی اساسی
setup_basic_config() {
    print_step "Creating basic configuration file..."
    
    # ایجاد فایل config ساده مستقیماً
    local config_file="$CONFIG_DIR/config.yml"
    
    cat > "$config_file" << 'EOF'
# پیکربندی اساسی EasyTier
# برای اتصال به شبکه، موارد زیر را تنظیم کنید:

network_name: "my-network"
network_secret: "my-secret-password"
hostname: ""
instance_name: ""

# آدرس IP در شبکه مجازی
ipv4: "10.145.0.2"

# پیرها (peers) برای اتصال
peers:
  - "tcp://peer1.example.com:11010"
  # - "tcp://peer2.example.com:11010"

# پورت listening
listeners:
  - "tcp://0.0.0.0:11010"
  - "udp://0.0.0.0:11011"

# تنظیمات اضافی
flags:
  - "--enable-encryption"
  - "--relay-all-peer-rpc"

# لاگ
log_level: "info"
log_file: "/var/log/easytier.log"
EOF

    chmod 644 "$config_file"
    
    print_success "فایل پیکربندی اساسی ایجاد شد: $config_file"
    print_warning "⚠️  برای اتصال به peers، فایل $config_file را ویرایش کنید"
}

# ایجاد سرویس systemd
create_systemd_service() {
    print_step "Creating systemd service..."
    
    local service_file="$SERVICE_DIR/easytier.service"
    
    cat > "$service_file" << 'EOF'
[Unit]
Description=EasyTier P2P VPN Service
Documentation=https://github.com/EasyTier/EasyTier
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/easytier
ExecStart=/usr/local/bin/easytier-core --config-file /etc/easytier/config.yml
ExecReload=/bin/kill -USR1 $MAINPID
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=easytier

# Security settings
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/etc/easytier /var/log

[Install]
WantedBy=multi-user.target
EOF

    # فعالسازی سرویس
    systemctl daemon-reload
    systemctl enable easytier
    
    print_success "سرویس systemd ایجاد و فعال شد"
    print_info "استفاده: systemctl start easytier"
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
    create_systemd_service
    
    # نمایش خلاصه
    show_summary
    
    print_success "نصب EasyTier تکمیل شد! 🎉"
}

# اجرای تابع اصلی
main "$@" 