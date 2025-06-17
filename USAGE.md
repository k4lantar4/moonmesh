# 📚 راهنمای استفاده از EasyTier مدیریت

## شروع سریع

بعد از نصب، برای دسترسی به منوی مدیریت:

```bash
sudo moonmesh
```

## دستورات سریع

```bash
# شروع سرویس
sudo moonmesh start

# توقف سرویس  
sudo moonmesh stop

# ری‌استارت سرویس
sudo moonmesh restart

# نمایش وضعیت
sudo moonmesh status

# نمایش لاگ‌ها
sudo moonmesh logs

# نمایش peer ها
sudo moonmesh peers

# اضافه کردن peer جدید
sudo moonmesh add-peer

# حذف peer
sudo moonmesh remove-peer

# ایجاد تانل جدید
sudo moonmesh create-tunnel

# نمایش تانل‌های فعال
sudo moonmesh list-tunnels

# تست اتصال
sudo moonmesh test-connection

# پشتیبان‌گیری از config
sudo moonmesh backup

# بازیابی config
sudo moonmesh restore

# بروزرسانی
sudo moonmesh update

# حذف کامل
sudo moonmesh uninstall
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
sudo moonmesh status --live
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
sudo moonmesh logs --follow
```

## Troubleshooting

### بررسی مشکلات رایج

```bash
# خودکار troubleshooting
sudo moonmesh diagnose

# تست اتصال
sudo moonmesh test --full

# مشاهده diagnostic info
sudo moonmesh info --detailed
```

### مشکلات شایع

#### 1. عدم اتصال peer ها
```bash
# بررسی فایروال
sudo moonmesh check-firewall

# تست دسترسی پورت
sudo moonmesh test-port 11010
```

#### 2. مشکل routing
```bash
# بررسی routing table
sudo moonmesh show-routes

# ریست routing
sudo moonmesh reset-routes
```

#### 3. مشکل performance
```bash
# بررسی network stats
sudo moonmesh network-stats

# بهینه‌سازی تنظیمات
sudo moonmesh optimize
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
sudo moonmesh security --harden

# تنظیم iptables rules
sudo moonmesh firewall --strict
```

---

💡 **نکته:** برای اطلاعات بیشتر هر دستور، از `--help` استفاده کنید:
```bash
sudo moonmesh COMMAND --help
``` 