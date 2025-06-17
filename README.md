# 🚀 EasyTier نصب آسان

اسکریپت نصب حرفه‌ای و آسان برای [EasyTier](https://github.com/EasyTier/EasyTier) با قابلیت‌های کامل مدیریت

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/shell-bash-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/platform-linux-blue.svg)](https://www.linux.org/)

## ✨ ویژگی‌ها

- 🎯 **نصب یک‌کلیکه** - فقط یک دستور و تمام!
- 🖥️ **رابط کاربری تعاملی** - منوی زیبا و کاربرپسند
- ⚙️ **مدیریت systemd کامل** - auto-start و watchdog
- 🌐 **مدیریت peer و تانل** - ساده و قدرتمند
- 📊 **مانیتورینگ real-time** - نمایش وضعیت زنده
- 🔧 **ابزارهای troubleshooting** - حل مشکل آسان
- 🛡️ **امنیت بالا** - security hardening
- 📝 **لاگ‌گیری کامل** - قابلیت debug عالی

## 🚀 نصب سریع

```bash
curl -fsSL https://raw.githubusercontent.com/k4lantar4/moonmesh/main/easytier-installer/install.sh | sudo bash
```

## 🎮 استفاده

بعد از نصب:

```bash
sudo moonmesh
```

## 📋 پیش‌نیازها

- **سیستم عامل:** Ubuntu 18.04+, Debian 9+, CentOS 7+, Fedora 30+
- **دسترسی:** Root یا sudo
- **شبکه:** اتصال اینترنت پایدار
- **فضا:** حداقل 50MB

## 🏗️ آرکیتکچر

```
easytier-installer/
├── 📦 install.sh              # نصب اصلی
├── 🎛️  moonmesh.sh    # مدیریت سرویس
├── 📁 config/
│   ├── default.conf          # پیکربندی پیش‌فرض
│   └── templates/            # تمپلیت‌ها
├── 🔧 systemd/
│   ├── easytier.service      # سرویس systemd
│   └── easytier-watchdog.sh  # watchdog
├── 🛠️  utils/
│   ├── network-helper.sh     # ابزار شبکه
│   ├── peer-manager.sh       # مدیریت peer
│   └── tunnel-manager.sh     # مدیریت تانل
└── 📚 docs/
    ├── INSTALLATION.md       # راهنمای نصب
    └── USAGE.md              # راهنمای استفاده
```

## 🎯 دستورات سریع

| دستور | عملکرد |
|--------|---------|
| `sudo moonmesh` | منوی اصلی |
| `sudo moonmesh start` | شروع سرویس |
| `sudo moonmesh stop` | توقف سرویس |
| `sudo moonmesh status` | نمایش وضعیت |
| `sudo moonmesh peers` | لیست peer ها |
| `sudo moonmesh logs` | مشاهده لاگ‌ها |

## 🌟 مثال‌های استفاده

### ایجاد شبکه جدید
```bash
# شروع مدیریت
sudo moonmesh

# انتخاب گزینه 6 (مدیریت تانل‌ها)
# انتخاب گزینه 2 (ایجاد تانل جدید)
# ورود اطلاعات:
Network Name: my-office
IP Range: 10.144.0.0/24
Port: 11010
Password: (optional)
```

### اضافه کردن peer
```bash
# از منوی اصلی گزینه 5 (مدیریت peer ها)
# انتخاب گزینه 2 (اضافه کردن peer جدید)
# ورود IP یا hostname peer
Peer Address: 192.168.1.100:11010
```

### نمایش وضعیت
```bash
sudo moonmesh status --live
```

## 🛠️ تنظیمات پیشرفته

### پیکربندی Subnet Proxy
```bash
# اشتراک شبکه محلی
Local Subnet: 192.168.1.0/24

# دسترسی به شبکه راه دور  
Remote Subnet: 10.0.0.0/24
```

### Security Hardening
```bash
sudo moonmesh security --harden
```

### Performance Optimization
```bash
sudo moonmesh optimize
```

## 🔧 عیب‌یابی

### مشکلات رایج

#### خطا در اتصال peer ها
```bash
# بررسی فایروال
sudo moonmesh check-firewall

# تست پورت
sudo moonmesh test-port 11010
```

#### مشکل routing
```bash
# نمایش routes
sudo moonmesh show-routes

# ریست routing table
sudo moonmesh reset-routes
```

### تشخیص خودکار مشکلات
```bash
sudo moonmesh diagnose
```

## 📊 مانیتورینگ

### نمایش آمار
- CPU و Memory usage
- ترافیک شبکه (up/down)
- تعداد peer های فعال
- وضعیت اتصالات

### لاگ‌های سیستم
```bash
# لاگ زنده
sudo moonmesh logs --follow

# لاگ با فیلتر
sudo moonmesh logs --level error
```

## 🔄 بروزرسانی

```bash
# بررسی نسخه جدید
sudo moonmesh check-update

# بروزرسانی خودکار
sudo moonmesh update
```

## 🗑️ حذف نصب

```bash
sudo moonmesh uninstall
```

## 🤝 مشارکت

ما از مشارکت شما استقبال می‌کنیم! 

1. Fork کنید
2. Feature branch ایجاد کنید
3. تغییرات را commit کنید
4. Pull request ارسال کنید

## 📝 لایسنس

این پروژه تحت لایسنس MIT منتشر شده است - جزئیات در فایل [LICENSE](LICENSE) موجود است.

## 🙏 تشکر

- [EasyTier](https://github.com/EasyTier/EasyTier) - پروژه اصلی
- [Easy-Mesh](https://github.com/Musixal/Easy-Mesh) - الهام UX

## 📞 پشتیبانی

- 📖 [مستندات](./docs/)
- 🐛 [گزارش مشکل](https://github.com/YOUR_REPO/issues)
- 💬 [بحث](https://github.com/YOUR_REPO/discussions)

---

**ساخته شده با ❤️ توسط BMad Master** 🧙 