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
- [x] تمپلیت ساده `/etc/easytier/config.yml`
- [x] فقط موارد ضروری (IP, peers, network-name)
- [x] بدون encryption پیچیده

---

## Phase 2: منوی تعاملی (3 تسک) 🎛️

### 5. اسکریپت مدیریت (`moonmesh`)
- [x] منوی اصلی ساده با 6 گزینه اصلی
- [x] start/stop/restart سرویس
- [x] نمایش وضعیت فعلی
- [x] دستورات CLI مستقیم

### 6. مدیریت peers ساده
- [x] نمایش peer های متصل (`easytier-cli peer`)
- [x] اضافه کردن peer جدید (فقط IP:Port)
- [x] حذف peer
- [x] بدون آمار پیچیده

### 7. مدیریت شبکه اساسی ✅ **تکمیل شد**
- [x] ایجاد network جدید (name + secret + IP)
- [x] اتصال به network موجود
- [x] نمایش route های فعال
- [x] ping test پیشرفته

---

## Phase 3: کیفیت تانل و ابزار (3 تسک) 🚀

### 8. بهینه‌سازی performance ✅ **تکمیل شد**
- [x] تنظیم MTU مناسب
- [x] buffer size optimization
- [x] تنظیم sysctl های ضروری فقط
- [x] منوی تعاملی performance در moonmesh

### 9. subnet proxy ساده  
- [ ] تنظیم `-n` parameter برای subnet sharing
- [ ] validation CIDR basic
- [ ] تست connectivity ساده با ping
- [ ] بدون routing table پیچیده

### 10. ابزار troubleshooting مینیمال ✅ **تکمیل شد**
- [x] تست اتصال خودکار (ping peers)
- [x] بررسی وضعیت سرویس
- [x] نمایش لاگ آخر (tail)
- [x] restart در صورت خرابی
- [x] تشخیص کامل مشکلات
- [x] تعمیر خودکار مشکلات

---

## ✅ خروجی نهایی

پس از تکمیل 10 تسک:

```bash
# نصب یک‌کلیکه
curl -fsSL https://github.com/k4lantar4/moonmesh/main/install.sh | sudo bash

# مدیریت ساده
sudo moonmesh

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
- **تسک‌های تکمیل شده:** 9/10 ✅
- **تسک‌های باقی‌مانده:** 1/10 📝 (تسک 9: subnet proxy - skip شد)
- **زمان تخمینی:** تکمیل شد! 🎉

---
**آخرین بروزرسانی:** $(date)  
**مسئول:** BMad Master 🧙 