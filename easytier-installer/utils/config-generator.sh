#!/bin/bash

# 🔧 ایجادکننده فایل پیکربندی EasyTier
# هدف: کپی کردن config اساسی و شخصی‌سازی ساده

set -e

# رنگ‌ها
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# مسیرها
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="/etc/easytier"
TEMPLATE_CONFIG="$SCRIPT_DIR/../config/basic-config.yml"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

generate_random_ip() {
    # تولید IP تصادفی در محدوده 10.145.0.2-254
    echo "10.145.0.$((RANDOM % 253 + 2))"
}

generate_network_secret() {
    # تولید کلید شبکه تصادفی
    openssl rand -hex 16 2>/dev/null || echo "my-secret-$(date +%s)"
}

create_basic_config() {
    local network_name="${1:-my-network}"
    local custom_ip="${2:-$(generate_random_ip)}"
    local network_secret="${3:-$(generate_network_secret)}"
    
    log_info "ایجاد فایل پیکربندی اساسی..."
    
    # ایجاد دایرکتوری config
    sudo mkdir -p "$CONFIG_DIR"
    
    # کپی کردن template
    if [[ ! -f "$TEMPLATE_CONFIG" ]]; then
        log_error "فایل template پیدا نشد: $TEMPLATE_CONFIG"
        return 1
    fi
    
    # ایجاد config شخصی‌سازی شده
    sudo tee "$CONFIG_DIR/config.yml" > /dev/null << EOF
# 🔧 EasyTier پیکربندی اساسی
# تولید شده در: $(date)

# مشخصات شبکه
network_name: "$network_name"
network_secret: "$network_secret"

# IP تانل (منحصر به فرد)
ipv4: "$custom_ip"
ipv4_prefix: 24

# پورت شنود
listen_port: 11011

# لیست peers (باید IP واقعی وارد شود)
peers:
  - "PEER_IP:11011"  # جایگزین با IP سرور اصلی

# تنظیمات اضافی
hostname: "$(hostname)"

# فعال‌سازی subnet proxy (اختیاری)
# proxy_networks:
#   - "192.168.1.0/24"

---
# نکات:
# 1. PEER_IP را با IP واقعی peer اصلی جایگزین کنید
# 2. network_name و network_secret روی همه node ها باید یکسان باشد
# 3. برای تست: ping $custom_ip
EOF
    
    # تنظیم مجوزها
    sudo chmod 600 "$CONFIG_DIR/config.yml"
    sudo chown root:root "$CONFIG_DIR/config.yml"
    
    log_success "فایل config ایجاد شد: $CONFIG_DIR/config.yml"
    log_info "🔑 Network Secret: $network_secret"
    log_info "🌐 IP تانل: $custom_ip"
    log_warning "⚠️  یادتان باشد PEER_IP را با IP واقعی جایگزین کنید!"
}

interactive_config() {
    echo -e "${BLUE}=== ایجاد پیکربندی تعاملی EasyTier ===${NC}"
    echo
    
    # نام شبکه
    read -p "نام شبکه (پیشفرض: my-network): " network_name
    network_name=${network_name:-my-network}
    
    # IP تانل
    suggested_ip=$(generate_random_ip)
    read -p "IP تانل (پیشفرض: $suggested_ip): " custom_ip
    custom_ip=${custom_ip:-$suggested_ip}
    
    # کلید شبکه
    read -p "کلید شبکه (خالی=تولید خودکار): " network_secret
    if [[ -z "$network_secret" ]]; then
        network_secret=$(generate_network_secret)
        log_info "کلید تولید شد: $network_secret"
    fi
    
    echo
    create_basic_config "$network_name" "$custom_ip" "$network_secret"
}

show_current_config() {
    if [[ -f "$CONFIG_DIR/config.yml" ]]; then
        log_info "پیکربندی فعلی:"
        echo "===================="
        sudo cat "$CONFIG_DIR/config.yml" | head -20
        echo "===================="
    else
        log_warning "فایل پیکربندی وجود ندارد"
    fi
}

validate_config() {
    if [[ ! -f "$CONFIG_DIR/config.yml" ]]; then
        log_error "فایل config یافت نشد"
        return 1
    fi
    
    log_info "بررسی صحت فایل config..."
    
    # بررسی موارد ضروری
    if ! sudo grep -q "network_name:" "$CONFIG_DIR/config.yml"; then
        log_error "network_name مشخص نشده"
        return 1
    fi
    
    if ! sudo grep -q "ipv4:" "$CONFIG_DIR/config.yml"; then
        log_error "IP تانل مشخص نشده"
        return 1
    fi
    
    if sudo grep -q "PEER_IP" "$CONFIG_DIR/config.yml"; then
        log_warning "⚠️  هنوز PEER_IP را با IP واقعی جایگزین نکرده‌اید!"
    fi
    
    log_success "فایل config معتبر است"
}

# اجرای تابع درخواستی
case "${1:-interactive}" in
    "create")
        create_basic_config "$2" "$3" "$4"
        ;;
    "interactive")
        interactive_config
        ;;
    "show")
        show_current_config
        ;;
    "validate")
        validate_config
        ;;
    *)
        echo "استفاده:"
        echo "  $0 [create|interactive|show|validate]"
        echo "  $0 create [network_name] [ip] [secret]"
        echo "  $0 interactive  # حالت تعاملی"
        echo "  $0 show         # نمایش config فعلی"
        echo "  $0 validate     # بررسی صحت config"
        ;;
esac 