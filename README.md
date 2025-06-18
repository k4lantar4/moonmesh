# 🚀 EasyTier نصب آسان v2.0

**نصب سریع و مدیریت ساده EasyTier - الهام گرفته از Easy-Mesh**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/shell-bash-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/platform-linux-blue.svg)](https://www.linux.org/)

## ✨ ویژگی‌های جدید v2.0

- 🎯 **نصب فوری** - 30 ثانیه تا آماده!
- 🖥️ **منوی ساده** - 11 گزینه کاربردی
- ⚙️ **پیشفرض‌های هوشمند** - کمترین ورودی کاربر
- 🌐 **اتصال سریع** - یک کلیک تا شبکه
- 📊 **مانیتورینگ زنده** - نمایش real-time
- 🔧 **عیب‌یابی آسان** - تشخیص خودکار مشکلات
- 🐕 **واچ داگ پیشرفته** - پایداری و عملکرد هوشمند
- ⚡ **بهینه‌سازی شبکه** - تنظیمات مخصوص Ubuntu

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
║  Version: 2.0 (K4lantar4)           ║
║  GitHub: k4lantar4/moonmesh           ║
╠════════════════════════════════════════╣
║        EasyTier Core Installed        ║
╚════════════════════════════════════════╝

[1] 🚀 Quick Connect to Network
[2] 👥 Network Peers (Enhanced)
[3] 🛣️  Network Routes & Status
[4] 🎯 Peer-Center
[5] 🔐 Display Secret Key
[6] 📊 View Service Status
[7] 🐕 Watchdog & Stability
[8] 🔄 Restart Service (Enhanced)
[9] 🗑️  Remove Service
[10] 🏓 Ping Test
[11] ⚡ Network Optimization
[0] 🚪 Exit
```

### 📋 **تغییرات گزینه‌ها:**

**گزینه 2 - Network Peers (بهبود یافته):**
```
[1] 📋 Show Current Peers
[2] 📊 Live Peers Monitor
[3] 🔍 Peer Details
[4] ⬅️  Back to Main Menu
```

**گزینه 3 - Network Routes (بهبود یافته):**
- نمایش routes بدون watch
- وضعیت سرویس
- IP configuration
- اطلاعات جامع شبکه

**گزینه 8 - Restart Service (بهبود یافته):**
- مدیریت خطای پیشرفته
- نمایش وضعیت قبل و بعد
- تایید کاربر
- اطلاعات تشخیصی کامل

## 🌟 اتصال سریع (گزینه 1)

### ورودی‌های پیشفرض جدید:
- **Local IP:** `10.10.10.1` (پیشفرض جدید)
- **Port:** `1377` (پیشفرض جدید)
- **Protocol:** `UDP` (توصیه شده)
- **Hostname:** `hostname-XXXX` (خودکار)
- **Secret:** تولید خودکار
- **IPv6:** غیرفعال (پیشفرض)
- **Multi-thread:** فعال (پیشفرض)

### مثال اتصال:
```bash
# سرور اول (مرکزی)
🌐 Peer Addresses: [ENTER for reverse mode]
🏠 Local IP [10.10.10.1]:
🏷️  Hostname [server1-2024]:
🔌 Port [1377]:
🔐 Network Secret [a1b2c3d4e5f6]: mynetwork123
🌐 Enable IPv6? [1]: 1 (No)
⚡ Enable Multi-thread? [1]: 1 (Yes)

# سرور دوم (اتصال)
🌐 Peer Addresses: 1.2.3.4
🏠 Local IP [10.10.10.2]:
🔐 Network Secret: mynetwork123
```

## 🐕 واچ داگ و پایداری (گزینه 7)

### زیرمنوی واچ داگ:
```
[1] 🏓 Ping-based Watchdog (Interactive)
[2] 📊 Service Health & Performance Monitor
[3] 🔄 Auto-restart Timer (Cron)
[4] 🧹 Clean Service Logs
[5] 🛡️  Stability Optimization
[6] 🗑️  Remove Watchdog
[7] ⬅️  Back to Main Menu
```

### ویژگی‌های واچ داگ:
- **🏓 Ping Watchdog:** مانیتورینگ اتصال تانل با IP مشخص (گزینه اصلی)
- **📊 Health & Performance:** مانیتورینگ جامع سرویس و عملکرد
- **🔄 Auto-restart Timer:** از 30 دقیقه تا هفتگی
- **🧹 Log Management:** پاکسازی لاگ‌های قدیمی
- **🛡️ Stability Optimization:** بهینه‌سازی kernel (بدون واچ داگ خودکار)
- **🗑️ Complete Removal:** حذف کامل تمام واچ داگ‌ها

### 🏓 Ping-based Watchdog (گزینه 1):
```
🎯 Enter tunnel IP to ping (e.g., 10.10.10.2): 10.10.10.2
🚨 Enter ping threshold in ms [300]: 300
⏰ Enter check interval in seconds [8]: 8

📋 Ping Watchdog Configuration:
  🎯 Target IP: 10.10.10.2
  🚨 Ping threshold: 300ms
  ⏰ Check interval: 8s
  🔄 Action: Restart EasyTier service on failure
```

**ویژگی‌های Ping Watchdog:**
- **تست اتصال مداوم:** هر 8 ثانیه (قابل تنظیم)
- **آستانه پینگ:** 300ms پیشفرض (قابل تنظیم)
- **ری‌استارت هوشمند:** پس از 3 بار شکست متوالی
- **لاگ کامل:** /var/log/easytier-ping-watchdog.log
- **سرویس systemd:** اجرای پایدار در پس‌زمینه
- **تست اولیه:** بررسی اتصال قبل از راه‌اندازی

## ⚡ بهینه‌سازی شبکه (گزینه 11)

### بهینه‌سازی‌های اعمال شده:
- **Kernel Parameters:** TCP/UDP buffer sizes
- **BBR Congestion Control:** برای عملکرد بهتر
- **TCP FastOpen:** کاهش latency
- **Firewall Rules:** پورت 1377 UDP/TCP
- **MTU Optimization:** 1420 برای tunnel
- **DNS Optimization:** 8.8.8.8, 1.1.1.1
- **CPU Scheduling:** اولویت بالا برای EasyTier
- **Network Buffers:** افزایش اندازه buffer

## 📋 مقایسه با نسخه قبلی

| ویژگی | v1.0 (قدیم) | v2.0 (جدید) |
|--------|-------------|-------------|
| تعداد گزینه‌های منو | 8 | 11 |
| واچ داگ | ❌ | ✅ کامل |
| بهینه‌سازی شبکه | ❌ | ✅ Ubuntu مخصوص |
| پیشفرض IP | 10.144.144.X | 10.10.10.1 |
| پیشفرض Port | 11011 | 1377 |
| IPv6 Control | ❌ | ✅ قابل انتخاب |
| Multi-thread Control | ❌ | ✅ قابل انتخاب |
| IP Detection | ساده | ✅ پیشرفته با fallback |

## 🎯 دستورات سریع

```bash
# نصب و اجرا
curl -fsSL https://raw.githubusercontent.com/k4lantar4/moonmesh/main/easytier-installer/install.sh | sudo bash

# مدیریت
sudo moonmesh

# اتصال سریع
sudo moonmesh  # سپس گزینه 1

# نمایش peers
sudo moonmesh  # سپس گزینه 2

# واچ داگ
sudo moonmesh  # سپس گزینه 7

# بهینه‌سازی
sudo moonmesh  # سپس گزینه 11

# Ping Watchdog
sudo moonmesh  # سپس گزینه 7 → گزینه 1
```

## 🔧 پیکربندی خودکار

### تنظیمات پیشفرض:
- **Encryption:** فعال
- **Multi-thread:** فعال (قابل تغییر)
- **IPv6:** غیرفعال (قابل تغییر)
- **Protocol:** UDP
- **Restart:** خودکار
- **Watchdog:** اختیاری

### فایل سرویس تولید شده:
```ini
[Unit]
Description=EasyTier Mesh Network Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/easytier-core -i 10.10.10.1 --peers udp://1.2.3.4:1377 --hostname server1-2024 --network-secret mynetwork123 --default-protocol udp --listeners udp://[::]:1377 udp://0.0.0.0:1377 --multi-thread --disable-ipv6
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
sudo ufw allow 1377
sudo firewall-cmd --add-port=1377/udp --permanent

# تست پورت
sudo moonmesh  # گزینه 10 (Ping Test)
```

#### 2. سرویس شروع نمی‌شود
```bash
# مشاهده لاگ
sudo journalctl -u easytier.service -f

# ری‌استارت
sudo moonmesh  # گزینه 8 (Restart Service)

# بررسی سلامت
sudo moonmesh  # گزینه 7 → گزینه 2 (Check Health)
```

#### 3. عملکرد پایین
```bash
# بهینه‌سازی شبکه
sudo moonmesh  # گزینه 11 (Network Optimization)

# مانیتورینگ عملکرد
sudo moonmesh  # گزینه 7 → گزینه 2 (Service Health & Performance)
```

#### 4. مشکلات اتصال تانل
```bash
# راه‌اندازی Ping Watchdog
sudo moonmesh  # گزینه 7 → گزینه 1

# مشاهده لاگ Ping Watchdog
tail -f /var/log/easytier-ping-watchdog.log

# بررسی وضعیت Ping Watchdog
systemctl status easytier-ping-watchdog
```

## 📊 مانیتورینگ پیشرفته

### واچ داگ Dashboard:
```
📊 EasyTier Service Status
🟢 Service Status: Active
✅ Process: Running (PID: 1234)
✅ Port 1377: Listening
📊 Memory Usage: 2.1%
⏰ Service Uptime: 2h 15m 30s
🌐 Active Connections: 3
```

### Performance Monitor:
```
📈 EasyTier Performance Monitor
Time: 2024-01-15 14:30:25

🔥 CPU Usage: 1.2%
💾 Memory: 2.1% 45.2MB
🌐 Active Connections: 3
⏰ Service Uptime: 2024-01-15 12:15:00
```

## 🔄 مهاجرت از v1.0

```bash
# حذف نسخه قدیم
sudo systemctl stop easytier
sudo systemctl disable easytier

# نصب نسخه جدید
curl -fsSL https://raw.githubusercontent.com/k4lantar4/moonmesh/main/easytier-installer/install.sh | sudo bash

# استفاده
sudo moonmesh
```

## 🤝 مشارکت

این پروژه الهام گرفته از [Easy-Mesh](https://github.com/K4lantar4/MoonMesh) است.

### تشکرات:
- [EasyTier](https://github.com/EasyTier/EasyTier) - پروژه اصلی
- [K4lantar4/MoonMesh](https://github.com/K4lantar4/MoonMesh) - الهام UX

## 📞 پشتیبانی

- 📖 [مستندات کامل](./docs/)
- 🐛 [گزارش مشکل](https://github.com/k4lantar4/moonmesh/issues)
- 💬 [بحث و گفتگو](https://github.com/k4lantar4/moonmesh/discussions)

---

**ساخته شده با ❤️ توسط K4lantar4** 🧙

*الهام گرفته از سادگی و زیبایی Easy-Mesh*
