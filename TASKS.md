# 📋 تسک‌های EasyTier نصب آسان (مینیمال و بهینه)

## 🎯 هدف: نصب آسان + منوی تعاملی + مدیریت سرویس بهینه

**تعداد کل تسک‌ها:** 10 تسک اصلی (بدون اضافه‌کاری)

---

## Phase 1: هسته نصب (4 تسک) ⚡

### 1. اسکریپت نصب اصلی (install.sh) ✅ **تکمیل شد**
- [x] تحلیل مستندات EasyTier 
- [x] تشخیص سیستم عامل (Ubuntu/Debian/CentOS)
- [x] دانلود binary مناسب معماری سیستم
- [x] نصب در `/usr/local/bin/`
- [x] بررسی پیش‌نیازهای ضروری فقط

### 2. SystemD سرویس (ساده) ✅
- [x] ایجاد `easytier.service` مینیمال
- [x] تنظیم auto-start
- [x] فقط start/stop/restart/status
- [x] بدون پیچیدگی اضافی

### 3. پیکربندی شبکه ساده ✅
- [x] تشخیص IP range آزاد (`10.145.0.0/24`)
- [x] تنظیم ساده ufw فقط پورت 11011
- [x] IP forwarding basic
- [x] بدون NAT detection پیچیده

### 4. فایل config اساسی
- [ ] تمپلیت ساده `/etc/easytier/config.yml`
- [ ] فقط موارد ضروری (IP, peers, network-name)
- [ ] بدون encryption پیچیده

---

## Phase 2: منوی تعاملی (3 تسک) 🎛️

### 5. اسکریپت مدیریت (`easytier-manager`)
- [ ] منوی اصلی ساده با 6 گزینه اصلی
- [ ] start/stop/restart سرویس
- [ ] نمایش وضعیت فعلی
- [ ] دستورات CLI مستقیم

### 6. مدیریت peers ساده
- [ ] نمایش peer های متصل (`easytier-cli peer`)
- [ ] اضافه کردن peer جدید (فقط IP:Port)
- [ ] حذف peer
- [ ] بدون آمار پیچیده

### 7. مدیریت شبکه اساسی
- [ ] ایجاد network جدید (name + secret + IP)
- [ ] اتصال به network موجود
- [ ] نمایش route های فعال
- [ ] ping test ساده

---

## Phase 3: کیفیت تانل و ابزار (3 تسک) 🚀

### 8. بهینه‌سازی performance
- [ ] تنظیم MTU مناسب
- [ ] buffer size optimization
- [ ] تنظیم sysctl های ضروری فقط
- [ ] بدون monitoring پیچیده

### 9. subnet proxy ساده  
- [ ] تنظیم `-n` parameter برای subnet sharing
- [ ] validation CIDR basic
- [ ] تست connectivity ساده با ping
- [ ] بدون routing table پیچیده

### 10. ابزار troubleshooting مینیمال
- [ ] تست اتصال خودکار (ping peers)
- [ ] بررسی وضعیت سرویس
- [ ] نمایش لاگ آخر (tail)
- [ ] restart در صورت خرابی

---

## ✅ خروجی نهایی

پس از تکمیل 10 تسک:

```bash
# نصب یک‌کلیکه
curl -fsSL https://example.com/install.sh | sudo bash

# مدیریت ساده
sudo easytier-manager

# منوی 6 گزینه‌ای:
# 1) شروع سرویس  
# 2) توقف سرویس
# 3) نمایش وضعیت
# 4) مدیریت peers
# 5) مدیریت شبکه  
# 6) خروج
```

---

## 🔥 اولویت‌ها (Critical Path)

1. **تسک 1:** نصب binary ✅ اولویت بالا
2. **تسک 5:** منوی اصلی ✅ اولویت بالا  
3. **تسک 2:** systemd service ✅ اولویت بالا
4. **تسک 6:** peer management ✅ اولویت متوسط
5. سایر تسک‌ها ✅ اولویت پایین

---

## 🚫 موارد حذف شده (اضافه‌کاری‌ها)

- ❌ Watchdog پیچیده
- ❌ Cron jobs
- ❌ Email alerting  
- ❌ Performance monitoring
- ❌ Security hardening اضافی
- ❌ WireGuard integration
- ❌ Dashboard متنی
- ❌ Progress bar و spinner
- ❌ Multi-distribution testing
- ❌ Auto-update mechanism

---

## وضعیت کلی
- **تسک‌های تکمیل شده:** 4/10 ✅
- **تسک‌های باقی‌مانده:** 6/10 📝  
- **زمان تخمینی:** 3-4 ساعت

---
**آخرین بروزرسانی:** $(date)  
**مسئول:** BMad Master 🧙 