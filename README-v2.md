# 🚀 EasyTier نصب آسان v2.0

**نصب سریع و مدیریت ساده EasyTier - الهام گرفته از Easy-Mesh**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/shell-bash-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/platform-linux-blue.svg)](https://www.linux.org/)

## ✨ ویژگی‌های جدید v2.0

- 🎯 **نصب فوری** - 30 ثانیه تا آماده!
- 🖥️ **منوی ساده** - فقط 9 گزینه ضروری
- ⚙️ **پیشفرض‌های هوشمند** - کمترین ورودی کاربر
- 🌐 **اتصال سریع** - یک کلیک تا شبکه
- 📊 **مانیتورینگ زنده** - نمایش real-time
- 🔧 **عیب‌یابی آسان** - تشخیص خودکار مشکلات

## 🚀 نصب یک‌کلیکه

```bash
curl -fsSL https://raw.githubusercontent.com/k4lantar4/moonmesh/main/easytier-installer/install.sh | sudo bash
```

## 🎮 استفاده فوری

```bash
sudo moonmesh
```

## 🎯 منوی اصلی

```
╔════════════════════════════════════════╗
║            🌐 EasyTier Manager         ║
║        Simple Mesh Network Solution    ║
╠════════════════════════════════════════╣
║  Version: 2.0 (BMad Master)           ║
║  GitHub: k4lantar4/moonmesh           ║
╠════════════════════════════════════════╣
║        EasyTier Core Installed        ║
╚════════════════════════════════════════╝

[1] 🚀 Quick Connect to Network
[2] 👥 Display Peers
[3] 🛣️  Display Routes
[4] 🎯 Peer-Center
[5] 🔐 Display Secret Key
[6] 📊 View Service Status
[7] 🏓 Ping Test
[8] 🔄 Restart Service
[9] 🗑️  Remove Service
[0] 🚪 Exit
```

## 🌟 اتصال سریع (گزینه 1)

### ورودی‌های پیشفرض:
- **Local IP:** `10.144.144.X` (خودکار)
- **Port:** `11011` (پیشفرض)
- **Protocol:** `UDP` (توصیه شده)
- **Hostname:** `hostname-XXXX` (خودکار)
- **Secret:** تولید خودکار

### مثال اتصال:
```bash
# سرور اول (مرکزی)
🌐 Peer Addresses: [ENTER for reverse mode]
🏠 Local IP [10.144.144.123]:
🏷️  Hostname [server1-2024]:
🔌 Port [11011]:
🔐 Network Secret [a1b2c3d4e5f6]: mynetwork123

# سرور دوم (اتصال)
🌐 Peer Addresses: 1.2.3.4
🏠 Local IP [10.144.144.124]:
🔐 Network Secret: mynetwork123
```

## 📋 مقایسه با نسخه قبلی

| ویژگی | v1.0 (قدیم) | v2.0 (جدید) |
|--------|-------------|-------------|
| تعداد گزینه‌های منو | 8 | 9 |
| زیرمنوها | ✅ پیچیده | ❌ حذف شد |
| پیشفرض‌ها | محدود | ✅ کامل |
| سرعت نصب | 2-3 دقیقه | 30 ثانیه |
| پیچیدگی | متوسط | ✅ ساده |
| UI Design | خوب | ✅ عالی |

## 🎯 دستورات سریع

```bash
# نصب
curl -fsSL https://raw.githubusercontent.com/k4lantar4/moonmesh/main/easytier-installer/install.sh | sudo bash

# مدیریت
sudo moonmesh

# اتصال سریع (دستوری)
sudo moonmesh quick-connect

# نمایش peers
sudo moonmesh peers

# وضعیت سرویس
sudo moonmesh status

# حذف کامل
sudo moonmesh remove
```

## 🔧 پیکربندی خودکار

### تنظیمات پیشفرض:
- **Encryption:** فعال
- **Multi-thread:** فعال
- **IPv6:** غیرفعال
- **Protocol:** UDP
- **Restart:** خودکار

### فایل سرویس تولید شده:
```ini
[Unit]
Description=EasyTier Mesh Network Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/easytier-core -i 10.144.144.123 --peers udp://1.2.3.4:11011 --hostname server1-2024 --network-secret mynetwork123 --default-protocol udp --listeners udp://[::]:11011 udp://0.0.0.0:11011 --multi-thread --disable-ipv6
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
```

## 🛠️ عیب‌یابی

### مشکلات رایج:

#### 1. اتصال نشدن peer ها
```bash
# بررسی فایروال
sudo ufw allow 11011
sudo firewall-cmd --add-port=11011/udp --permanent

# تست پورت
sudo moonmesh ping-test
```

#### 2. سرویس شروع نمی‌شود
```bash
# مشاهده لاگ
sudo journalctl -u easytier.service -f

# ری‌استارت
sudo moonmesh restart
```

## 📊 مانیتورینگ زنده

### نمایش peers (گزینه 2):
```
┌─────────────────────────────────────────┐
│ Peer ID: abc123                         │
│ Address: 1.2.3.4:11011                  │
│ Status: Connected                       │
│ Latency: 25ms                          │
│ Traffic: ↑ 1.2MB ↓ 0.8MB               │
└─────────────────────────────────────────┘
```

### نمایش routes (گزینه 3):
```
┌─────────────────────────────────────────┐
│ Network: 10.144.144.0/24               │
│ Gateway: 10.144.144.1                  │
│ Metric: 1                              │
│ Status: Active                         │
└─────────────────────────────────────────┘
```

## 🔄 مهاجرت از v1.0

```bash
# حذف نسخه قدیم
sudo moonmesh uninstall

# نصب نسخه جدید
curl -fsSL https://raw.githubusercontent.com/k4lantar4/moonmesh/main/easytier-installer/install.sh | sudo bash

# استفاده
sudo moonmesh
```

## 🤝 مشارکت

این پروژه الهام گرفته از [Easy-Mesh](https://github.com/Musixal/Easy-Mesh) است.

### تشکرات:
- [EasyTier](https://github.com/EasyTier/EasyTier) - پروژه اصلی
- [Musixal/Easy-Mesh](https://github.com/Musixal/Easy-Mesh) - الهام UX

## 📞 پشتیبانی

- 📖 [مستندات کامل](./docs/)
- 🐛 [گزارش مشکل](https://github.com/k4lantar4/moonmesh/issues)
- 💬 [بحث و گفتگو](https://github.com/k4lantar4/moonmesh/discussions)

---

**ساخته شده با ❤️ توسط BMad Master** 🧙

*الهام گرفته از سادگی و زیبایی Easy-Mesh*
