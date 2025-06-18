#!/bin/bash

# 🚀 EasyTier Quick Installer v2.0
# K4lantar4 - Inspired by K4lantar4/MoonMesh
# نصب سریع، ساده، بدون پیچیدگی

set -e

# رنگ‌ها
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# متغیرها
DEST_DIR="/usr/local/bin"
CONFIG_DIR="/etc/easytier"
LOG_FILE="/var/log/easytier-install.log"

# =============================================================================
# توابع کمکی
# =============================================================================

colorize() {
    local color="$1"
    local text="$2"

    case $color in
        red) echo -e "${RED}$text${NC}" ;;
        green) echo -e "${GREEN}$text${NC}" ;;
        yellow) echo -e "${YELLOW}$text${NC}" ;;
        blue) echo -e "${BLUE}$text${NC}" ;;
        cyan) echo -e "${CYAN}$text${NC}" ;;
        white) echo -e "${WHITE}$text${NC}" ;;
        *) echo -e "$text" ;;
    esac
}

print_banner() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗"
    echo -e "║                    🚀 ${WHITE}EasyTier Quick Installer${CYAN}              ║"
    echo -e "║                     ${WHITE}Fast & Simple Setup${CYAN}                   ║"
    echo -e "║                   ${WHITE}K4lantar4 - v2.0${CYAN}                     ║"
    echo -e "╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

# =============================================================================
# بررسی وضعیت نصب
# =============================================================================

check_installation() {
    local files_exist=false
    
    if [[ -f "$DEST_DIR/easytier-core" ]] || [[ -f "$DEST_DIR/easytier-cli" ]] || [[ -f "$DEST_DIR/moonmesh" ]]; then
        files_exist=true
        colorize yellow "⚠️  Previous installation detected!"
        echo
        colorize cyan "📋 Existing files found:"
        [[ -f "$DEST_DIR/easytier-core" ]] && echo "  • $DEST_DIR/easytier-core"
        [[ -f "$DEST_DIR/easytier-cli" ]] && echo "  • $DEST_DIR/easytier-cli"
        [[ -f "$DEST_DIR/moonmesh" ]] && echo "  • $DEST_DIR/moonmesh"
        echo
        colorize green "🔄 Proceeding with update/reinstallation..."
    fi
    
    return 0  # همیشه ادامه می‌دهیم
}

# =============================================================================
# تشخیص معماری
# =============================================================================

detect_architecture() {
    ARCH=$(uname -m)

    case $ARCH in
        x86_64)
            URL_BASE="https://github.com/EasyTier/EasyTier/releases/latest/download"
            DOWNLOAD_FILE="easytier-linux-x86_64-${LATEST_VERSION}.zip"
            ;;
        armv7l)
            URL_BASE="https://github.com/EasyTier/EasyTier/releases/latest/download"
            DOWNLOAD_FILE="easytier-linux-armv7-${LATEST_VERSION}.zip"
            ;;
        aarch64)
            URL_BASE="https://github.com/EasyTier/EasyTier/releases/latest/download"
            DOWNLOAD_FILE="easytier-linux-aarch64-${LATEST_VERSION}.zip"
            ;;
        *)
            colorize red "❌ Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac

    colorize green "✅ Detected architecture: $ARCH"
}

# =============================================================================
# دریافت آخرین نسخه
# =============================================================================

get_latest_version() {
    colorize yellow "🔍 Getting latest version..."

    LATEST_VERSION=$(curl -s https://api.github.com/repos/EasyTier/EasyTier/releases/latest | grep '"tag_name"' | cut -d'"' -f4)

    if [[ -z "$LATEST_VERSION" ]]; then
        colorize red "❌ Failed to get latest version"
        exit 1
    fi

    colorize green "✅ Latest version: $LATEST_VERSION"
}

# =============================================================================
# مدیریت سرویس‌های در حال اجرا
# =============================================================================

manage_running_services() {
    colorize yellow "🔍 Checking for running EasyTier services..."
    
    local services_found=false
    local running_processes=""
    
    # بررسی سرویس systemd
    if systemctl is-active --quiet easytier 2>/dev/null || systemctl is-active --quiet easytier.service 2>/dev/null; then
        services_found=true
        running_processes="systemd service (easytier)"
        colorize yellow "⚠️  EasyTier systemd service is running"
    fi
    
    # بررسی پروسه‌های در حال اجرا
    if pgrep -f "easytier-core" >/dev/null 2>&1; then
        services_found=true
        if [[ -n "$running_processes" ]]; then
            running_processes="$running_processes, easytier-core process"
        else
            running_processes="easytier-core process"
        fi
        colorize yellow "⚠️  EasyTier core process is running"
    fi
    
    if [[ "$services_found" == true ]]; then
        echo
        colorize cyan "🛑 Running services detected: $running_processes"
        colorize white "   To install new version, these services need to be stopped."
        echo
        
        # درخواست تأیید با پیشفرض Y
        echo -n "$(colorize yellow "❓ Stop services and continue installation? [Y/n]: ")"
        read -t 10 -r response || response="y"  # 10 ثانیه timeout با پیشفرض y
        
        case ${response,,} in
            n|no)
                colorize red "❌ Installation cancelled by user"
                exit 0
                ;;
            *|y|yes)
                colorize green "✅ Proceeding with service management..."
                
                # توقف سرویس systemd
                if systemctl is-active --quiet easytier 2>/dev/null; then
                    colorize yellow "🛑 Stopping easytier service..."
                    systemctl stop easytier 2>/dev/null || true
                fi
                
                if systemctl is-active --quiet easytier.service 2>/dev/null; then
                    colorize yellow "🛑 Stopping easytier.service..."
                    systemctl stop easytier.service 2>/dev/null || true
                fi
                
                # کشتن پروسه‌های باقی‌مانده
                if pgrep -f "easytier-core" >/dev/null 2>&1; then
                    colorize yellow "🛑 Stopping easytier-core processes..."
                    pkill -f "easytier-core" 2>/dev/null || true
                    sleep 2
                    
                    # اگر هنوز در حال اجرا بود، force kill
                    if pgrep -f "easytier-core" >/dev/null 2>&1; then
                        colorize yellow "🔥 Force stopping remaining processes..."
                        pkill -9 -f "easytier-core" 2>/dev/null || true
                        sleep 1
                    fi
                fi
                
                colorize green "✅ Services stopped successfully"
                ;;
        esac
    fi
}

# =============================================================================
# دانلود و نصب
# =============================================================================

download_and_install() {
    colorize yellow "📥 Downloading EasyTier $LATEST_VERSION..."

    # ایجاد دایرکتوری موقت
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    # دانلود فایل
    DOWNLOAD_URL="$URL_BASE/$DOWNLOAD_FILE"
    if ! curl -fsSL "$DOWNLOAD_URL" -o "$DOWNLOAD_FILE"; then
        colorize red "❌ Download failed: $DOWNLOAD_URL"
        exit 1
    fi

    # استخراج
    colorize yellow "📦 Extracting files..."
    if ! unzip -q "$DOWNLOAD_FILE"; then
        colorize red "❌ Failed to extract files"
        exit 1
    fi

    # یافتن فایل‌های binary
    EASYTIER_CORE=$(find . -name "easytier-core" -type f | head -1)
    EASYTIER_CLI=$(find . -name "easytier-cli" -type f | head -1)

    if [[ -z "$EASYTIER_CORE" ]] || [[ -z "$EASYTIER_CLI" ]]; then
        colorize red "❌ Binary files not found in archive"
        exit 1
    fi

    # کپی فایل‌ها با backup اگر موجود باشند
    colorize yellow "📁 Installing to $DEST_DIR..."
    
    # backup فایل‌های موجود
    if [[ -f "$DEST_DIR/easytier-core" ]]; then
        colorize cyan "💾 Backing up existing easytier-core..."
        cp "$DEST_DIR/easytier-core" "$DEST_DIR/easytier-core.backup.$(date +%s)" 2>/dev/null || true
    fi
    
    if [[ -f "$DEST_DIR/easytier-cli" ]]; then
        colorize cyan "💾 Backing up existing easytier-cli..."
        cp "$DEST_DIR/easytier-cli" "$DEST_DIR/easytier-cli.backup.$(date +%s)" 2>/dev/null || true
    fi
    
    # نصب فایل‌های جدید
    chmod +x "$EASYTIER_CORE" "$EASYTIER_CLI"
    
    if ! cp "$EASYTIER_CORE" "$DEST_DIR/" 2>/dev/null; then
        colorize red "❌ Failed to install easytier-core"
        colorize yellow "💡 This might be because the file is currently in use."
        colorize cyan "🔄 Attempting to resolve..."
        
        # اجرای مدیریت سرویس‌ها
        manage_running_services
        
        # تلاش مجدد
        colorize yellow "🔄 Retrying installation..."
        if ! cp "$EASYTIER_CORE" "$DEST_DIR/" 2>/dev/null; then
            colorize red "❌ Still failed to install easytier-core"
            colorize yellow "💡 Possible solutions:"
            echo "  • Check file permissions: ls -la $DEST_DIR/"
            echo "  • Check disk space: df -h"
            echo "  • Manual stop: sudo pkill -9 easytier-core"
            exit 1
        else
            colorize green "✅ easytier-core installed successfully after retry!"
        fi
    fi
    
    if ! cp "$EASYTIER_CLI" "$DEST_DIR/" 2>/dev/null; then
        colorize red "❌ Failed to install easytier-cli"
        colorize yellow "💡 Possible solutions:"
        echo "  • Check file permissions: ls -la $DEST_DIR/"
        echo "  • Check disk space: df -h"
        exit 1
    fi

    # پاک کردن فایل‌های موقت
    cd /
    rm -rf "$TEMP_DIR"

    colorize green "✅ EasyTier binaries installed successfully!"
}

# =============================================================================
# دانلود moonmesh
# =============================================================================

install_manager() {
    colorize yellow "🎛️  Installing moonmesh manager..."

    MOONMESH_URL="https://raw.githubusercontent.com/k4lantar4/moonmesh/main/moonmesh.sh"
    
    # backup فایل moonmesh موجود
    if [[ -f "$DEST_DIR/moonmesh" ]]; then
        colorize cyan "💾 Backing up existing moonmesh..."
        cp "$DEST_DIR/moonmesh" "$DEST_DIR/moonmesh.backup.$(date +%s)" 2>/dev/null || true
    fi

    # دانلود moonmesh جدید
    if curl -fsSL "$MOONMESH_URL" -o "$DEST_DIR/moonmesh.tmp"; then
        mv "$DEST_DIR/moonmesh.tmp" "$DEST_DIR/moonmesh"
        chmod +x "$DEST_DIR/moonmesh"
        colorize green "✅ moonmesh manager installed!"
    else
        colorize yellow "⚠️  Failed to download manager"
        # اگر فایل قبلی موجود بود، آن را نگه می‌داریم
        if [[ -f "$DEST_DIR/moonmesh.backup.$(date +%s)" ]]; then
            colorize cyan "🔄 Keeping existing moonmesh version"
        else
            colorize red "❌ No moonmesh manager available"
        fi
        # پاک کردن فایل موقت در صورت وجود
        rm -f "$DEST_DIR/moonmesh.tmp" 2>/dev/null || true
    fi
}

# =============================================================================
# ایجاد config directory
# =============================================================================

create_config_dir() {
    colorize yellow "📁 Creating config directory..."

    mkdir -p "$CONFIG_DIR"

    # ایجاد فایل README
    cat > "$CONFIG_DIR/README" << 'EOF'
# EasyTier Configuration Directory

This directory contains EasyTier configuration files.

## Quick Start:
1. Run: sudo moonmesh
2. Select option 1: Quick Connect
3. Follow the prompts

## Manual Configuration:
- Edit service: sudo systemctl edit easytier.service
- View logs: sudo journalctl -u easytier.service -f

## Support:
- GitHub: https://github.com/k4lantar4/moonmesh
- EasyTier: https://github.com/EasyTier/EasyTier
EOF

    colorize green "✅ Config directory created: $CONFIG_DIR"
}

# =============================================================================
# تست نصب
# =============================================================================

test_installation() {
    colorize yellow "🧪 Testing installation..."
    local test_failed=false

    # تست وجود فایل‌ها
    if [[ ! -f "$DEST_DIR/easytier-core" ]]; then
        colorize red "❌ easytier-core not found at $DEST_DIR"
        test_failed=true
    elif [[ ! -x "$DEST_DIR/easytier-core" ]]; then
        colorize yellow "⚠️  easytier-core is not executable, fixing..."
        chmod +x "$DEST_DIR/easytier-core" || test_failed=true
    fi

    if [[ ! -f "$DEST_DIR/easytier-cli" ]]; then
        colorize red "❌ easytier-cli not found at $DEST_DIR"
        test_failed=true
    elif [[ ! -x "$DEST_DIR/easytier-cli" ]]; then
        colorize yellow "⚠️  easytier-cli is not executable, fixing..."
        chmod +x "$DEST_DIR/easytier-cli" || test_failed=true
    fi

    # تست PATH
    if ! command -v easytier-core &> /dev/null; then
        colorize yellow "⚠️  easytier-core not in PATH, but installed at $DEST_DIR"
    fi

    if ! command -v easytier-cli &> /dev/null; then
        colorize yellow "⚠️  easytier-cli not in PATH, but installed at $DEST_DIR"
    fi

    # تست اجرای binary
    if [[ -x "$DEST_DIR/easytier-core" ]]; then
        if ! "$DEST_DIR/easytier-core" --help &> /dev/null; then
            colorize yellow "⚠️  easytier-core might have compatibility issues"
        fi
    fi

    # تست moonmesh
    if [[ -f "$DEST_DIR/moonmesh" ]]; then
        if [[ ! -x "$DEST_DIR/moonmesh" ]]; then
            colorize yellow "⚠️  moonmesh is not executable, fixing..."
            chmod +x "$DEST_DIR/moonmesh" || true
        fi
        colorize green "✅ moonmesh manager available"
    else
        colorize yellow "⚠️  moonmesh manager not available"
    fi

    if [[ "$test_failed" == true ]]; then
        colorize red "❌ Installation test failed!"
        exit 1
    else
        colorize green "✅ Installation test passed!"
    fi
}

# =============================================================================
# نمایش خلاصه
# =============================================================================

show_summary() {
    echo
    colorize green "╔══════════════════════════════════════════════════════════════╗"
    colorize green "║                    🎉 Installation Complete!                ║"
    colorize green "╚══════════════════════════════════════════════════════════════╝"
    echo
    colorize cyan "📋 Installation Summary:"
    echo "  • Version: $LATEST_VERSION"
    echo "  • Architecture: $ARCH"
    echo "  • Install Path: $DEST_DIR"
    echo "  • Config Path: $CONFIG_DIR"
    echo
    colorize yellow "🚀 Quick Start:"
    if [[ -f "$DEST_DIR/moonmesh" ]]; then
        colorize white "  sudo moonmesh"
    else
        colorize white "  sudo $DEST_DIR/easytier-core --help"
    fi
    echo
    colorize yellow "📖 Manual Usage:"
    colorize white "  sudo $DEST_DIR/easytier-core --help"
    colorize white "  sudo $DEST_DIR/easytier-cli --help"
    echo
    colorize cyan "💡 Next Steps:"
    echo "  1. Run 'sudo moonmesh' to start"
    echo "  2. Select 'Quick Connect to Network'"
    echo "  3. Follow the simple setup wizard"
    echo
    colorize cyan "🎯 New Features in v2.0:"
    echo "  • Default IP: 10.10.10.1"
    echo "  • Default Port: 1377"
    echo "  • Watchdog & Stability features"
    echo "  • Network optimization tools"
    echo "  • IPv6 & Multi-thread options"
    echo
    colorize green "✨ Ready to create your mesh network!"
}

# =============================================================================
# تابع اصلی
# =============================================================================

main() {
    # بررسی root
    if [[ $EUID -ne 0 ]]; then
        colorize red "❌ This script must be run as root"
        echo "Usage: sudo $0"
        exit 1
    fi

    print_banner

    # بررسی نصب قبلی
    check_installation

    # شروع لاگ
    echo "=== EasyTier Installation Started at $(date) ===" > "$LOG_FILE"

    # مراحل نصب
    colorize cyan "🔧 Starting EasyTier installation..."
    echo

    get_latest_version
    detect_architecture

    # نصب پیش‌نیازها
    if command -v apt-get &> /dev/null; then
        colorize yellow "📦 Installing prerequisites..."
        apt-get update -qq
        apt-get install -y curl unzip bc &> /dev/null
    elif command -v yum &> /dev/null; then
        colorize yellow "📦 Installing prerequisites..."
        yum install -y curl unzip bc &> /dev/null
    fi

    # بررسی و مدیریت سرویس‌های در حال اجرا
    manage_running_services

    download_and_install
    install_manager
    create_config_dir
    test_installation

    # نمایش خلاصه
    show_summary

    # لاگ پایان
    echo "=== EasyTier Installation Completed at $(date) ===" >> "$LOG_FILE"
}

# اجرای تابع اصلی
main "$@"
