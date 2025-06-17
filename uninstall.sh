#!/bin/bash

# =============================================================================
# 🗑️ EasyTier حذف آسان 
# Redirect to actual uninstaller in easytier-installer directory
# =============================================================================

set -e

# رنگ‌ها برای output زیبا
RED='\033[0;31m'
GREEN='\033[0;32m'  
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🗑️ شروع حذف EasyTier...${NC}"

# تعین مسیر اسکریپت اصلی
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNINSTALLER_PATH="$SCRIPT_DIR/easytier-installer/uninstall.sh"

# بررسی وجود اسکریپت حذف
if [[ -f "$UNINSTALLER_PATH" ]]; then
    echo -e "${GREEN}✅ اسکریپت حذف پیدا شد، انتقال به حذف اصلی...${NC}"
    exec bash "$UNINSTALLER_PATH" "$@"
else
    echo -e "${RED}❌ خطا: اسکریپت حذف اصلی پیدا نشد در: $UNINSTALLER_PATH${NC}"
    echo "شروع حذف دستی..."
    
    # حذف دستی اجزای اصلی
    echo -e "${BLUE}🔧 حذف فایل‌های اصلی...${NC}"
    
    # توقف سرویس
    if systemctl is-active easytier >/dev/null 2>&1; then
        echo -e "${YELLOW}⏹️ توقف سرویس EasyTier...${NC}"
        systemctl stop easytier
        systemctl disable easytier
    fi
    
    # حذف فایل‌ها
    rm -f /usr/local/bin/easytier-core
    rm -f /usr/local/bin/easytier-cli
    rm -f /usr/local/bin/moonmesh
    rm -f /etc/systemd/system/easytier.service
    rm -rf /etc/easytier
    
    # بروزرسانی systemd
    systemctl daemon-reload
    
    echo -e "${GREEN}✅ حذف با موفقیت انجام شد!${NC}"
fi 