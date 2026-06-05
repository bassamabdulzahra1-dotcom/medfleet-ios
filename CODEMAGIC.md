# بناء MedFleet iOS عبر Codemagic (من Windows)

[Codemagic](https://codemagic.io) يبني تطبيق iOS على Mac سحابي — **ما تحتاج Mac**.

المستودع: https://github.com/bassamabdulzahra1-dotcom/medfleet-ios

---

## 1. إنشاء حساب Codemagic

1. ادخل https://codemagic.io/signup  
2. سجّل بحساب **GitHub** (نفس حساب المستودع)

---

## 2. ربط المشروع

1. **Applications** → **Add application**  
2. اختر GitHub → مستودع **medfleet-ios**  
3. Project type: **Other** أو **iOS native**  
4. Codemagic يكتشف `codemagic.yaml` تلقائياً

---

## 3. أول بناء (Simulator — مجاني للاختبار)

1. **Start new build**  
2. Branch: `main`  
3. Workflow: **MedFleet — Simulator (اختبار سريع)**  
4. **Start build**

إذا نجح → الكود سليم ✅

---

## 4. بناء IPA للآيفون (يحتاج Apple Developer ~99$/سنة)

### أ) App Store Connect API Key

1. https://appstoreconnect.apple.com → **Users and Access** → **Integrations** → **App Store Connect API**  
2. **Generate API Key** (App Manager)  
3. حمّل ملف `.p8` — مرة واحدة فقط

### ب) في Codemagic

**Team settings** → **Team integrations** → **Developer Portal** → أضف API Key

**Code signing identities**:
- **Generate certificate** (Apple Distribution)  
- **Fetch profiles** لـ Bundle ID: `net.medfleet.rep`

### ج) App Store Connect

1. أنشئ App جديد: Bundle ID `net.medfleet.rep`  
2. اسم: **MedFleet**

### د) البناء

1. **Start new build**  
2. Workflow: **MedFleet — IPA (iPhone / TestFlight)**  
3. بعد النجاح → حمّل `.ipa` من Artifacts  
4. أو فعّل `app_store_connect` في `codemagic.yaml` للرفع التلقائي لـ TestFlight

---

## Workflows في codemagic.yaml

| Workflow | الغرض | Apple Developer |
|----------|--------|-----------------|
| `ios-simulator` | اختبار البناء | ❌ لا |
| `ios-ipa` | ملف IPA للآيفون | ✅ نعم |

---

## Bundle ID

```
net.medfleet.rep
```

---

## مشاكل شائعة

| الخطأ | الحل |
|-------|------|
| XcodeGen not found | يُثبّت تلقائياً في السكربت |
| Code signing failed | أضف Certificate + Profile في Codemagic |
| No matching profile | Bundle ID في Apple = `net.medfleet.rep` |
| Scheme not found | Scheme = `MedFleet` (يُنشأ من XcodeGen) |

---

## إيميل الإشعارات

`bassamabdulzahra1@gmail.com` — مضبوط في `codemagic.yaml`
