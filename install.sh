#!/bin/bash

# =============================================================================
# 🚀 EasyTier مسیردهی نصب 
# Redirect to actual installer in easytier-installer directory
# =============================================================================

set -e

# رنگ‌ها برای output زیبا
RED='\033[0;31m'
GREEN='\033[0;32m'  
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 شروع نصب EasyTier...${NC}"

# تعین مسیر اسکریپت اصلی
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER_PATH="$SCRIPT_DIR/easytier-installer/install.sh"

# بررسی وجود اسکریپت اصلی
if [[ -f "$INSTALLER_PATH" ]]; then
    echo -e "${GREEN}✅ اسکریپت نصب پیدا شد، انتقال به نصب اصلی...${NC}"
    exec bash "$INSTALLER_PATH" "$@"
else
    echo -e "${RED}❌ خطا: اسکریپت نصب اصلی پیدا نشد در: $INSTALLER_PATH${NC}"
    echo "لطفاً از کامل بودن repository اطمینان حاصل کنید"
    exit 1
fi 