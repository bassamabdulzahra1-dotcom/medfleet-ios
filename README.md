# MedFleet iOS — تطبيق المندوب

نسخة iPhone من تطبيق MedFleet للمندوب (Sales Rep)، متصلة بنفس السيرفر:

`https://medfleet.net/api/v1/`

## المتطلبات

- **Mac** مع **Xcode 15+** (لا يمكن بناء iOS على Windows)
- iPhone أو Simulator (iOS 16+)
- حساب Apple Developer (للتثبيت على جهاز حقيقي أو TestFlight)

## فتح المشروع على Mac

### الطريقة 1 — XcodeGen (مُفضّلة)

```bash
cd medfleet-ios
brew install xcodegen   # مرة واحدة
xcodegen generate
open MedFleet.xcodeproj
```

### الطريقة 2 — إنشاء مشروع يدوي

1. Xcode → **File → New → Project → iOS App**
2. Product Name: `MedFleet` — Bundle ID: `net.medfleet.rep`
3. احذف الملفات الافتراضية وأضف مجلد `MedFleet/` بالكامل
4. في **Signing & Capabilities** اختر Team
5. تأكد أن `Info.plist` يحتوي صلاحيات الموقع والكاميرا

## التشغيل

1. اختر Simulator أو iPhone متصل
2. **Product → Run** (⌘R)
3. سجّل الدخول، مثلاً:
   - البريد: `bassam@medfleet.com`
   - كلمة المرور: `123456`

## الأقسام (مطابقة Android)

| القسم | الوظيفة |
|--------|---------|
| زيارات المندوب | قائمة الصيدليات، تسجيل زيارة، تثبيت GPS، إضافة صيدلية |
| الموردين | قائمة الموردين + إنشاء جدول تسديد (خصم %) |
| تسديدات الموردين | المدفوعات الفعلية فقط (`paid_only=1`) |
| المواعيد | الأقساط المجدولة مجمّعة حسب اليوم |
| حسابي | بيانات المستخدم + تسجيل خروج |

## ملاحظات

- **إنشاء خطة تسديد** → يظهر في **المواعيد** فقط
- **تسديد قسط** → يظهر في **تسديدات الموردين**
- واجهة عربية RTL
- Token يُحفظ في Keychain

## TestFlight (اختياري)

1. **Product → Archive**
2. **Distribute App → App Store Connect**
3. أضف المختبرين من App Store Connect

## هيكل الملفات

```
MedFleet/
  MedFleetApp.swift       — نقطة الدخول + التوجيه
  Data/                   — API، Models، TokenStore
  Theme/                  — ألوان وتنسيق
  Views/Auth/             — Splash، Login
  Views/Rep/              — شاشات المندوب
  Views/Driver/           — طلبات السائق (أساسي)
```

## الإصدار

- **1.0.0** — أول إصدار iOS (parity مع Android 1.6.x)
