#!/bin/bash

# 🚀 EasyTier Quick Installer v2.0
# BMad Master - Inspired by Musixal/Easy-Mesh
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
    echo -e "║                   ${WHITE}BMad Master - v2.0${CYAN}                     ║"
    echo -e "╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

# =============================================================================
# بررسی وضعیت نصب
# =============================================================================

check_installation() {
    if [[ -f "$DEST_DIR/easytier-core" ]] && [[ -f "$DEST_DIR/easytier-cli" ]]; then
        colorize green "✅ EasyTier is already installed!"
        echo
        colorize cyan "📋 Installed files:"
        echo "  • $DEST_DIR/easytier-core"
        echo "  • $DEST_DIR/easytier-cli"
        echo "  • $DEST_DIR/moonmesh-v2"
        echo
        colorize yellow "🎯 To manage: sudo moonmesh-v2"
        exit 0
    fi
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

    # کپی فایل‌ها
    colorize yellow "📁 Installing to $DEST_DIR..."
    chmod +x "$EASYTIER_CORE" "$EASYTIER_CLI"
    cp "$EASYTIER_CORE" "$DEST_DIR/"
    cp "$EASYTIER_CLI" "$DEST_DIR/"

    # پاک کردن فایل‌های موقت
    cd /
    rm -rf "$TEMP_DIR"

    colorize green "✅ EasyTier binaries installed successfully!"
}

# =============================================================================
# دانلود moonmesh-v2
# =============================================================================

install_manager() {
    colorize yellow "🎛️  Installing moonmesh-v2 manager..."

    MOONMESH_URL="https://raw.githubusercontent.com/k4lantar4/moonmesh/main/easytier-installer/moonmesh-v2.sh"

    if curl -fsSL "$MOONMESH_URL" -o "$DEST_DIR/moonmesh-v2"; then
        chmod +x "$DEST_DIR/moonmesh-v2"
        colorize green "✅ moonmesh-v2 manager installed!"
    else
        colorize yellow "⚠️  Failed to download manager, continuing without it"
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
1. Run: sudo moonmesh-v2
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

    if ! command -v easytier-core &> /dev/null; then
        colorize red "❌ easytier-core not found in PATH"
        exit 1
    fi

    if ! command -v easytier-cli &> /dev/null; then
        colorize red "❌ easytier-cli not found in PATH"
        exit 1
    fi

    # تست اجرای binary
    if ! easytier-core --help &> /dev/null; then
        colorize red "❌ easytier-core is not executable"
        exit 1
    fi

    colorize green "✅ Installation test passed!"
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
    colorize white "  sudo moonmesh-v2"
    echo
    colorize yellow "📖 Manual Usage:"
    colorize white "  sudo easytier-core --help"
    colorize white "  sudo easytier-cli --help"
    echo
    colorize cyan "💡 Next Steps:"
    echo "  1. Run 'sudo moonmesh-v2' to start"
    echo "  2. Select 'Quick Connect to Network'"
    echo "  3. Follow the simple setup wizard"
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
        apt-get install -y curl unzip &> /dev/null
    elif command -v yum &> /dev/null; then
        colorize yellow "📦 Installing prerequisites..."
        yum install -y curl unzip &> /dev/null
    fi

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
