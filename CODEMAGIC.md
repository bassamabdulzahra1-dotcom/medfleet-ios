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

## 4. ربط حساب Apple Developer (حسابك المطور)

Codemagic **ما يطلب Apple ID وكلمة المرور**. الربط يتم عبر **API Key** + **شهادات التوقيع** — كلها تروح لحسابك أنت في Apple.

```
┌─────────────────┐     API Key (.p8)      ┌─────────────────┐
│  Apple Developer │ ───────────────────► │    Codemagic    │
│  App Store Connect│     Certificate      │  (Mac سحابي)    │
│  (حسابك أنت)     │     Profile          └────────┬────────┘
└─────────────────┘                               │
         ▲                                          │ يبني + يوقّع + يرفع
         │                                          ▼
         └──────────── TestFlight / App Store ◄── IPA
```

### الخطوة 1 — App ID (Apple Developer Portal)

1. https://developer.apple.com/account  
2. **Certificates, Identifiers & Profiles** → **Identifiers** → **+**  
3. **App IDs** → Bundle ID: **`net.medfleet.rep`**  
4. اسم: **MedFleet Rep**

> إذا موجود مسبقاً — تخطّى هذه الخطوة.

### الخطوة 2 — تطبيق في App Store Connect

1. https://appstoreconnect.apple.com  
2. **Apps** → **+** → **New App**  
3. الاسم: **MedFleet**  
4. Bundle ID: **net.medfleet.rep**  
5. SKU: أي رقم (مثلاً `medfleet-rep-001`)

> **ملاحظة:** Apple ID للتطبيق (رقم) تحتاجه لاحقاً لـ TestFlight التلقائي — من **App Information → Apple ID**.

### الخطوة 3 — API Key (المفتاح اللي يربط Codemagic بحسابك)

1. App Store Connect → **Users and Access**  
2. **Integrations** → **App Store Connect API**  
3. **Generate API Key**  
   - الاسم: `Codemagic`  
   - Access: **App Manager**  
4. **Download** ملف `.p8` (مرة واحدة فقط!)  
5. احفظ **Issuer ID** (فوق الجدول) و **Key ID** (عمود في الجدول)

### الخطوة 4 — أضف المفتاح في Codemagic ⭐ (هنا تربط حسابك)

1. https://codemagic.io → **Teams** (أيقونة الفريق)  
2. **Team integrations**  
3. **Developer Portal** → **Manage keys** → **Add key**  
4. املأ:
   - **Key name:** `medfleet-apple` (أي اسم — تستخدمه في yaml)  
   - **Issuer ID** + **Key ID**  
   - ارفع ملف **.p8**  
5. **Save**

### الخطوة 5 — شهادات التوقيع (Code signing)

1. **Team settings** → **codemagic.yaml settings** → **Code signing identities**  
2. تبويب **iOS certificates** → **Generate certificate**  
   - Type: **Apple Distribution**  
   - API key: اختر `medfleet-apple`  
   - Reference name: `medfleet_dist`  
3. تبويب **iOS provisioning profiles** → **Fetch profiles**  
   - اختر profile لـ **`net.medfleet.rep`** (App Store)  
   - Reference name: `medfleet_appstore`

> Codemagic ينشئ الشهادة **داخل حساب Apple Developer تبعك** — مو حساب منفصل.

### الخطوة 6 — فعّل الرفع التلقائي لـ TestFlight

في `codemagic.yaml` workflow **ios-ipa**، أزل التعليق عن:

```yaml
integrations:
  app_store_connect: medfleet-apple   # نفس اسم Key في Codemagic

publishing:
  app_store_connect:
    auth: integration
    submit_to_testflight: true
```

### الخطوة 7 — شغّل البناء

1. Codemagic → **medfleet-ios** → **Start new build**  
2. Workflow: **MedFleet — IPA (iPhone / TestFlight)**  
3. **Start build**

**النتيجة:**
- Codemagic يبني على Mac سحابي  
- يوقّع التطبيق بشهادات **حسابك**  
- يرفع `.ipa` إلى **App Store Connect → TestFlight**  
- تنزل التطبيق على iPhone من تطبيق **TestFlight**

---

## 5. بناء IPA للآيفون (ملخص)

(انظر الخطوات 1–7 أعلاه — هذا القسم القديم مدمج فيها)

### د) البناء

1. **Start new build**  
2. Workflow: **MedFleet — IPA (iPhone / TestFlight)**  
3. بعد النجاح → `.ipa` في Artifacts + TestFlight إذا فعّلت الرفع التلقائي

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
