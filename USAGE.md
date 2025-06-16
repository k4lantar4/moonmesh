# 📚 راهنمای استفاده از EasyTier مدیریت

## شروع سریع

بعد از نصب، برای دسترسی به منوی مدیریت:

```bash
sudo easytier-manager
```

## دستورات سریع

```bash
# شروع سرویس
sudo easytier-manager start

# توقف سرویس  
sudo easytier-manager stop

# ری‌استارت سرویس
sudo easytier-manager restart

# نمایش وضعیت
sudo easytier-manager status

# نمایش لاگ‌ها
sudo easytier-manager logs

# نمایش peer ها
sudo easytier-manager peers

# اضافه کردن peer جدید
sudo easytier-manager add-peer

# حذف peer
sudo easytier-manager remove-peer

# ایجاد تانل جدید
sudo easytier-manager create-tunnel

# نمایش تانل‌های فعال
sudo easytier-manager list-tunnels

# تست اتصال
sudo easytier-manager test-connection

# پشتیبان‌گیری از config
sudo easytier-manager backup

# بازیابی config
sudo easytier-manager restore

# بروزرسانی
sudo easytier-manager update

# حذف کامل
sudo easytier-manager uninstall
```

## منوی تعاملی

### منوی اصلی
```
╔══════════════════════════════════════════════════╗
║               🚀 EasyTier مدیریت                ║
╠══════════════════════════════════════════════════╣
║  1) 🟢 شروع سرویس                              ║
║  2) 🔴 توقف سرویس                              ║
║  3) 🔄 ری‌استارت سرویس                         ║
║  4) 📊 نمایش وضعیت                             ║
║  5) 👥 مدیریت peer ها                          ║
║  6) 🌐 مدیریت تانل‌ها                           ║
║  7) ⚙️  تنظیمات                                 ║
║  8) 📝 لاگ‌ها                                   ║
║  9) 🔧 ابزارها                                  ║
║  0) ❌ خروج                                     ║
╚══════════════════════════════════════════════════╝
```

### مدیریت Peer ها
```
╔══════════════════════════════════════════════════╗
║                👥 مدیریت Peer ها                ║
╠══════════════════════════════════════════════════╣
║  1) 📋 نمایش peer های فعال                     ║
║  2) ➕ اضافه کردن peer جدید                      ║
║  3) ✏️  ویرایش peer موجود                       ║
║  4) 🗑️  حذف peer                                ║
║  5) 📊 آمار اتصال peer ها                       ║
║  6) 🔄 رفرش لیست                               ║
║  0) ⬅️  بازگشت                                  ║
╚══════════════════════════════════════════════════╝
```

### مدیریت تانل‌ها
```
╔══════════════════════════════════════════════════╗
║               🌐 مدیریت تانل‌ها                  ║
╠══════════════════════════════════════════════════╣
║  1) 📋 نمایش تانل‌های فعال                      ║
║  2) ➕ ایجاد تانل جدید                          ║
║  3) ✏️  ویرایش تانل موجود                       ║
║  4) 🗑️  حذف تانل                               ║
║  5) 🔧 پیکربندی subnet proxy                    ║
║  6) 🧪 تست connectivity                         ║
║  7) 📊 آمار ترافیک                             ║
║  0) ⬅️  بازگشت                                  ║
╚══════════════════════════════════════════════════╝
```

## پیکربندی‌های پیشرفته

### ایجاد Network جدید

1. انتخاب "مدیریت تانل‌ها" از منوی اصلی
2. انتخاب "ایجاد تانل جدید"
3. ورود اطلاعات:
   - **نام شبکه:** `my-network`
   - **IP Range:** `10.144.0.0/24` (پیش‌فرض)
   - **پورت:** `11010` (پیش‌فرض)
   - **رمز عبور:** (اختیاری)

### اضافه کردن Peer

```bash
# IP و پورت peer
IP: 192.168.1.100
Port: 11010

# یا hostname
Hostname: peer1.example.com
Port: 11010
```

### پیکربندی Subnet Proxy

```bash
# اشتراک subnet محلی
Local Subnet: 192.168.1.0/24

# دسترسی به subnet راه دور
Remote Subnet: 10.0.0.0/24
```

## مانیتورینگ و لاگ‌ها

### نمایش وضعیت Real-time

```bash
sudo easytier-manager status --live
```

خروجی نمونه:
```
🟢 EasyTier Status - زنده | 2024-01-15 14:30:25

┌─ سرویس ──────────────────────────────────────┐
│ وضعیت: 🟢 فعال                               │
│ مدت زمان: 2h 15m 30s                        │
│ PID: 1234                                    │
│ Memory: 45.2 MB                              │
│ CPU: 2.1%                                    │
└──────────────────────────────────────────────┘

┌─ شبکه ───────────────────────────────────────┐
│ Network ID: my-network                       │
│ IP Address: 10.144.0.1/24                   │
│ Listen Port: 11010                           │
│ Active Peers: 3                              │
└──────────────────────────────────────────────┘

┌─ ترافیک ─────────────────────────────────────┐
│ بارگذاری: 125.3 KB/s                        │
│ دانلود: 89.7 KB/s                           │
│ کل داده ارسالی: 2.4 GB                       │
│ کل داده دریافتی: 1.8 GB                      │
└──────────────────────────────────────────────┘
```

### مشاهده لاگ‌های Live

```bash
sudo easytier-manager logs --follow
```

## Troubleshooting

### بررسی مشکلات رایج

```bash
# خودکار troubleshooting
sudo easytier-manager diagnose

# تست اتصال
sudo easytier-manager test --full

# مشاهده diagnostic info
sudo easytier-manager info --detailed
```

### مشکلات شایع

#### 1. عدم اتصال peer ها
```bash
# بررسی فایروال
sudo easytier-manager check-firewall

# تست دسترسی پورت
sudo easytier-manager test-port 11010
```

#### 2. مشکل routing
```bash
# بررسی routing table
sudo easytier-manager show-routes

# ریست routing
sudo easytier-manager reset-routes
```

#### 3. مشکل performance
```bash
# بررسی network stats
sudo easytier-manager network-stats

# بهینه‌سازی تنظیمات
sudo easytier-manager optimize
```

## کدهای خروج

| کد | توضیحات |
|----|---------|
| 0 | موفق |
| 1 | خطای عمومی |
| 2 | پارامتر نامعتبر |
| 3 | دسترسی مناسب ندارید |
| 4 | سرویس در حال اجرا نیست |
| 5 | خطای پیکربندی |
| 6 | خطای شبکه |

## نکات بهینه‌سازی

### Performance Tuning

```bash
# تنظیم buffer sizes
echo 'net.core.rmem_max = 26214400' >> /etc/sysctl.conf
echo 'net.core.rmem_default = 26214400' >> /etc/sysctl.conf

# اعمال تغییرات
sysctl -p
```

### Security Hardening

```bash
# محدود کردن دسترسی
sudo easytier-manager security --harden

# تنظیم iptables rules
sudo easytier-manager firewall --strict
```

---

💡 **نکته:** برای اطلاعات بیشتر هر دستور، از `--help` استفاده کنید:
```bash
sudo easytier-manager COMMAND --help
``` 