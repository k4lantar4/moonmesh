#!/bin/bash

# 🚀 EasyTier Quick Installer v3.0 - Fast & Simple
# K4lantar4 - Optimized for speed and reliability

set -e

# رنگ‌ها (ساده‌شده)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# متغیرها
DEST_DIR="/usr/local/bin"
CONFIG_DIR="/etc/easytier"
AUTO_MODE=false

# =============================================================================
# توابع کمکی
# =============================================================================

log() {
    local color="$1"
    local text="$2"
    case $color in
        red) echo -e "${RED}❌ $text${NC}" ;;
        green) echo -e "${GREEN}✅ $text${NC}" ;;
        yellow) echo -e "${YELLOW}⚠️  $text${NC}" ;;
        cyan) echo -e "${CYAN}🔧 $text${NC}" ;;
        white) echo -e "${WHITE}$text${NC}" ;;
        *) echo -e "$text" ;;
    esac
}

print_header() {
    clear
    echo -e "${CYAN}🚀 EasyTier Quick Installer v3.0 - Fast Setup${NC}"
    echo "=================================================="
}

# =============================================================================
# بررسی و آماده‌سازی سیستم
# =============================================================================

prepare_system() {
    log cyan "Preparing system..."
    
    # بررسی root
    if [[ $EUID -ne 0 ]]; then
        log red "Root access required. Usage: sudo $0 [--auto]"
        exit 1
    fi
    
    # توقف سرویس‌های در حال اجرا (سریع و بدون تعامل)
    if systemctl is-active --quiet easytier 2>/dev/null; then
        systemctl stop easytier 2>/dev/null || true
    fi
    pkill -f "easytier-core" 2>/dev/null || true
    sleep 1
    
    # نصب پیش‌نیازها (فقط در صورت عدم وجود)
    local missing_deps=""
    command -v curl >/dev/null || missing_deps="$missing_deps curl"
    command -v unzip >/dev/null || missing_deps="$missing_deps unzip"
    
    if [[ -n "$missing_deps" ]]; then
        log yellow "Installing dependencies:$missing_deps"
        if command -v apt-get >/dev/null; then
            apt-get update -qq && apt-get install -y $missing_deps >/dev/null 2>&1
        elif command -v yum >/dev/null; then
            yum install -y $missing_deps >/dev/null 2>&1
        elif command -v dnf >/dev/null; then
            dnf install -y $missing_deps >/dev/null 2>&1
        elif command -v pacman >/dev/null; then
            pacman -S --noconfirm $missing_deps >/dev/null 2>&1
        else
            log red "Unsupported package manager. Install manually: $missing_deps"
            exit 1
        fi
    fi
    
    log green "System prepared"
}

# =============================================================================
# دانلود و نصب (بهینه‌شده)
# =============================================================================

install_easytier() {
    log cyan "Getting latest version and downloading..."
    
    # تشخیص معماری
    local arch=$(uname -m)
    case $arch in
        x86_64) arch_suffix="x86_64" ;;
        armv7l) arch_suffix="armv7" ;;
        aarch64) arch_suffix="aarch64" ;;
        *) log red "Unsupported architecture: $arch"; exit 1 ;;
    esac
    
    # دریافت آخرین نسخه
    local latest_version=$(curl -s https://api.github.com/repos/EasyTier/EasyTier/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    if [[ -z "$latest_version" ]]; then
        log red "Failed to get latest version"
        exit 1
    fi
    
    # URLs
    local download_file="easytier-linux-${arch_suffix}-${latest_version}.zip"
    local download_url="https://github.com/EasyTier/EasyTier/releases/latest/download/$download_file"
    local moonmesh_url="https://raw.githubusercontent.com/k4lantar4/moonmesh/main/moonmesh.sh"
    
    log cyan "Downloading EasyTier $latest_version ($arch_suffix)..."
    
    # دانلود در دایرکتوری موقت
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # دانلود EasyTier
    if ! curl -fsSL "$download_url" -o "$download_file"; then
        log red "Download failed: $download_url"
        exit 1
    fi
    
    # استخراج
    if ! unzip -q "$download_file"; then
        log red "Failed to extract files"
        exit 1
    fi
    
    # یافتن و نصب فایل‌ها
    local easytier_core=$(find . -name "easytier-core" -type f | head -1)
    local easytier_cli=$(find . -name "easytier-cli" -type f | head -1)
    
    if [[ -z "$easytier_core" ]] || [[ -z "$easytier_cli" ]]; then
        log red "Binary files not found in archive"
        exit 1
    fi
    
    # نصب
    chmod +x "$easytier_core" "$easytier_cli"
    cp "$easytier_core" "$DEST_DIR/" || { log red "Failed to install easytier-core"; exit 1; }
    cp "$easytier_cli" "$DEST_DIR/" || { log red "Failed to install easytier-cli"; exit 1; }
    
    log green "EasyTier $latest_version installed"
    
    # دانلود moonmesh
    log cyan "Installing moonmesh manager..."
    if curl -fsSL "$moonmesh_url" -o "$DEST_DIR/moonmesh"; then
        chmod +x "$DEST_DIR/moonmesh"
        log green "Moonmesh manager installed"
    else
        log yellow "Moonmesh manager download failed (optional)"
    fi
    
    # پاک‌سازی
    cd / && rm -rf "$temp_dir"
}

# =============================================================================
# تنظیمات نهایی
# =============================================================================

finalize_setup() {
    log cyan "Finalizing setup..."
    
    # ایجاد config directory
    mkdir -p "$CONFIG_DIR" || true
    
    # تست سریع
    if [[ ! -x "$DEST_DIR/easytier-core" ]] || [[ ! -x "$DEST_DIR/easytier-cli" ]]; then
        log red "Installation verification failed"
        exit 1
    fi
    
    log green "Setup completed successfully!"
}

# =============================================================================
# نمایش خلاصه (ساده‌شده)
# =============================================================================

show_summary() {
    echo
    log green "🎉 EasyTier installed successfully!"
    echo
    echo "Quick Start:"
    if [[ -f "$DEST_DIR/moonmesh" ]]; then
        echo "  sudo moonmesh"
    else
        echo "  sudo easytier-core --help"
    fi
    echo
    echo "Manual Usage:"
    echo "  sudo $DEST_DIR/easytier-core --help"
    echo "  sudo $DEST_DIR/easytier-cli --help"
    echo
    log cyan "Ready to create your mesh network! 🚀"
}

# =============================================================================
# تابع اصلی
# =============================================================================

main() {
    # بررسی حالت auto
    if [[ "$1" == "--auto" ]] || [[ "$1" == "-y" ]] || [[ "$1" == "--yes" ]]; then
        AUTO_MODE=true
    fi
    
    print_header
    
    # مراحل نصب (بهینه‌شده)
    prepare_system
    install_easytier
    finalize_setup
    show_summary
    
    log green "Installation completed in record time! ⚡"
}

# اجرای تابع اصلی
main "$@"
