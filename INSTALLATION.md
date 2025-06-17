# 🚀 راهنمای نصب EasyTier آسان

## نصب یک‌کلیکه

برای نصب سریع EasyTier به همراه تمام ابزارهای مدیریتی:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_REPO/easytier-installer/main/install.sh | sudo bash
```

یا برای نصب دستی:

```bash
wget https://raw.githubusercontent.com/YOUR_REPO/easytier-installer/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

## سیستم‌های پشتیبانی‌شده

- ✅ Ubuntu 18.04+ 
- ✅ Debian 9+
- ✅ CentOS 7+
- ✅ Rocky Linux 8+
- ✅ Fedora 30+
- ✅ Arch Linux

## پیش‌نیازها

- ✅ دسترسی root (sudo)
- ✅ اتصال اینترنت پایدار
- ✅ حداقل 50MB فضای آزاد
- ✅ پورت‌های شبکه قابل دسترس

## فرآیند نصب

### 1. بررسی سیستم
اسکریپت خودکار موارد زیر را بررسی می‌کند:
- سیستم عامل و معماری
- وجود ابزارهای مورد نیاز
- دسترسی‌های لازم
- فضای دیسک

### 2. دانلود و نصب
- دانلود آخرین نسخه EasyTier
- تایید checksum
- نصب در `/usr/local/bin/`
- پیکربندی PATH

### 3. پیکربندی سرویس
- ایجاد systemd service
- تنظیم auto-start
- پیکربندی فایروال
- ایجاد config های پیش‌فرض

### 4. تست نصب
- بررسی عملکرد binary
- تست اتصال شبکه
- تایید سرویس systemd

## استفاده اولیه

بعد از نصب موفق، برای شروع:

```bash
# شروع مدیریت EasyTier
sudo moonmesh

# یا استفاده مستقیم
sudo easytier-core --help
```

## گزینه‌های نصب

### نصب سایلنت (بدون تعامل)
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_REPO/easytier-installer/main/install.sh | sudo bash -s -- --silent
```

### نصب با پیکربندی سفارشی
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_REPO/easytier-installer/main/install.sh | sudo bash -s -- --config custom.conf
```

### نصب فقط binary (بدون سرویس)
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_REPO/easytier-installer/main/install.sh | sudo bash -s -- --binary-only
```

## حذف نصب

برای حذف کامل EasyTier:

```bash
sudo moonmesh --uninstall
```

یا:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_REPO/easytier-installer/main/uninstall.sh | sudo bash
```

## عیب‌یابی

### مشکلات رایج

#### ۱. خطا در دانلود
```bash
# بررسی اتصال اینترنت
ping -c 4 github.com

# استفاده از پروکسی
export https_proxy=your_proxy:port
```

#### ۲. مشکل دسترسی
```bash
# اطمینان از دسترسی root
sudo -v

# بررسی SELinux (CentOS/RHEL)
sestatus
```

#### ۳. مشکل فایروال
```bash
# بررسی وضعیت فایروال
sudo ufw status
sudo firewall-cmd --state

# باز کردن پورت پیش‌فرض
sudo ufw allow 11010
```

### لاگ‌های سیستم

```bash
# مشاهده لاگ نصب
tail -f /var/log/easytier-install.log

# لاگ سرویس
journalctl -u easytier -f
```

## دریافت کمک

- 📖 [مستندات کامل](./USAGE.md)
- 🐛 [گزارش مشکل](https://github.com/YOUR_REPO/issues)
- 💬 [بحث و گفتگو](https://github.com/YOUR_REPO/discussions)
- 📧 [تماس مستقیم](mailto:support@easytier.local)

---

> 💡 **نکته:** در صورت بروز هر مشکلی، لطفاً فایل `/var/log/easytier-install.log` را همراه گزارش خود ارسال کنید. 