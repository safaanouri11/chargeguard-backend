# ChargeGuard — تقرير المشروع الكامل
### تطبيق إدارة شحن السيارات الكهربائية في فلسطين

---

## 📋 نظرة عامة على المشروع

**ChargeGuard** هو تطبيق شامل لإدارة محطات شحن السيارات الكهربائية (EV Charging) في فلسطين، يخدم ثلاث فئات من المستخدمين:

1. **السائقون (Drivers)** — يبحثون عن محطات شحن، يحجزون، يدفعون، ويقيّمون
2. **المُضيفون (Hosts)** — أصحاب المحطات الذين يديرون شواحنهم ويستقبلون الحجوزات
3. **الإدارة (Admins)** — يراقبون النظام، يوافقون على المضيفين، يديرون المدفوعات

---

## 🛠 التقنيات المستخدمة (Tech Stack)

### Backend
| التقنية | الاستخدام |
|---|---|
| **Node.js + Express 5** | السيرفر والـ REST API |
| **MongoDB + Mongoose** | قاعدة البيانات |
| **JWT (jsonwebtoken)** | المصادقة Authentication |
| **bcryptjs** | تشفير كلمات المرور |
| **@anthropic-ai/sdk** | الذكاء الاصطناعي (Claude) |
| **CORS + dotenv** | إعدادات السيرفر |

### Frontend
| التقنية | الاستخدام |
|---|---|
| **Flutter (Dart)** | تطبيق الويب |
| **flutter_map + latlong2** | الخرائط التفاعلية (OpenStreetMap) |
| **geolocator** | تحديد موقع المستخدم |
| **http** | اتصال بـ REST API |

### الذكاء الاصطناعي
- **Claude Haiku 4.5** من Anthropic (افتراضي)
- **Claude Opus 4.7** للمهام المعقدة (اختياري)

---

## 🏗 معمارية المشروع (Architecture)

```
ChargeGuard/
├── chargeguard-backend/        ← REST API Server
│   ├── server.js               (نقطة البداية)
│   ├── models/                 (14 موديل)
│   ├── routes/                 (14 ملف routes)
│   ├── middleware/             (auth, protect, hostApproved)
│   └── utils/                  (ai, loyalty, notify, distance, ...)
│
└── flutter_application_1/      ← تطبيق Flutter
    └── lib/
        ├── main.dart           (نقطة البداية)
        ├── screens/            (40+ شاشة)
        └── utils/              (api_service, constants, ...)
```

---

## ✨ الميزات الرئيسية (Features)

### 1. نظام المصادقة والمستخدمين

**ما تم تنفيذه:**
- ✅ تسجيل سائق (Driver Registration)
- ✅ تسجيل مُضيف مع تحقق إداري (Host with Admin Approval)
- ✅ تسجيل الدخول بـ JWT
- ✅ نسيت كلمة المرور (Forgot Password) مع رمز تحقق 6 أرقام
- ✅ تغيير كلمة المرور
- ✅ حذف الحساب
- ✅ تحديث الـ Profile والصورة الشخصية

**API Endpoints:**
- `POST /api/auth/register` — تسجيل سائق
- `POST /api/auth/register-host` — تسجيل مُضيف
- `POST /api/auth/login` — تسجيل الدخول
- `POST /api/auth/forgot-password` — نسيت كلمة المرور
- `POST /api/auth/reset-password` — إعادة تعيين كلمة المرور
- `GET /api/users/profile` — جلب الملف الشخصي
- `PUT /api/users/profile` — تحديث الملف الشخصي

---

### 2. محطات الشحن (Stations)

**ما تم تنفيذه:**
- ✅ عرض كل المحطات مع تفاصيل (Power, Connector, Price, Rating, إلخ)
- ✅ خريطة تفاعلية بـ OpenStreetMap تعرض كل المحطات
- ✅ بحث جغرافي بناءً على موقع المستخدم (Haversine algorithm)
- ✅ تفاصيل المحطة (Network, Amenities, Parking, Vehicles)
- ✅ Bookmarks (المحطات المفضلة)
- ✅ Recently Viewed (المحطات المُشاهَدة مؤخراً — آخر 20)

**API Endpoints:**
- `GET /api/stations` — كل المحطات مع فلاتر متقدمة
- `GET /api/stations/nearby?lat=&lng=&radius=` — أقرب المحطات
- `GET /api/stations/filters` — قيم الفلاتر المتاحة
- `GET /api/stations/:id` — تفاصيل محطة
- `POST /api/users/recent/:stationId` — تسجيل مُشاهدة
- `GET /api/users/recent` — قائمة المُشاهَدة مؤخراً

---

### 3. الفلاتر المتقدمة (Advanced Map Filters) — مستوحى من PlugShare

**ما تم تنفيذه:**

🎚 **شريط القوة (Kilowatt Range Slider):**
- نطاق 0 إلى 350+ kW

🔌 **أنواع الموصلات (Connectors):**
- CCS2, CCS1, CHAdeMO, Type 2, NACS, GB/T, AC, J-1772

🅿️ **مواقف السيارات (Parking):**
- Accessible, Covered, Garage, Illuminated, Pull In, Pull Through, Trailer Friendly

🏪 **الخدمات المتاحة (Amenities):**
- WiFi, Dining, Restroom, Shopping, Lodging, Park, Grocery, Valet, Hiking, Camping, Free Charge

📊 **عوامل إضافية:**
- عدد المحطات (Station Count): Any / 2+ / 4+ / 6+
- الحد الأدنى للتقييم (Min Rating)
- متاح الآن فقط (Available Now)
- قريباً (Coming Soon): Include / Show Only / Hide
- الشبكة (Network): Tesla, ChargePoint, EVgo, إلخ

**معاينة فورية لعدد النتائج:**
- يعرض "X Locations" قبل الضغط على View
- شارة حمراء بعدد الفلاتر النشطة

---

### 4. الحجوزات (Bookings)

**ما تم تنفيذه:**
- ✅ حجز محطة بتاريخ ووقت محدّد
- ✅ إلغاء حجز مع استرداد المبلغ تلقائياً
- ✅ خصم تلقائي حسب tier المستخدم (Bronze 0% / Silver 5% / Gold 10%)
- ✅ تطبيق كود خصم (Promo Code) عند الحجز
- ✅ كسب 10 نقاط لكل حجز
- ✅ تاريخ الحجوزات

**API Endpoints:**
- `GET /api/bookings` — حجوزاتي
- `POST /api/bookings` — إنشاء حجز (مع تطبيق خصم tier + promo)
- `PUT /api/bookings/:id/cancel` — إلغاء حجز

---

### 5. الحالة الفورية للمحطات (Real-time Occupancy)

**ما تم تنفيذه:**
- ✅ 3 حالات للمحطة:
  - 🟢 **Free** (Available) — متاحة
  - 🔴 **Busy** (In Use) — قيد الاستخدام
  - ⚫ **Offline** — معطّلة (صيانة)
- ✅ تحديث تلقائي عند بدء/إيقاف الشحن
- ✅ المُضيف يقدر يغير الحالة يدوياً (للصيانة)
- ✅ ألوان مختلفة على الخريطة وبطاقات المحطات

**API Endpoints:**
- `PUT /api/host/stations/:id/occupancy` — تغيير الحالة (host)

---

### 6. الذكاء الاصطناعي (AI Features)

#### 6.1 توصية المحطة الذكية (AI Station Recommendation)

**ما تم تنفيذه:**
- Claude بياخد بيانات المستخدم (Connector, Battery, Region, Balance)
- بيرجع توصية مع شرح بلغة طبيعية
- يستخدم Structured Outputs لضمان شكل البيانات
- Fallback لخوارزمية scoring في حالة عدم توفر API key

**مثال على الـ Response:**
```json
{
  "recommendation": {
    "_id": "...",
    "name": "An-Najah EV Station",
    "reason": "Best match for your CCS2 connector with fast 50 kW charging at 2.5 NIS/kWh.",
    "source": "ai"
  }
}
```

#### 6.2 مخطط الرحلة الذكي (AI Trip Planner)

**ما تم تنفيذه:**
- خوارزمية Greedy لاختيار محطات الشحن على المسار
- Claude بيكتب ملخص طبيعي للرحلة
- مدن فلسطينية جاهزة (Nablus, Ramallah, Jerusalem, Hebron, Bethlehem, Jenin, Tulkarm, Jericho)
- استخدام GPS المستخدم تلقائياً

**معلومات الرحلة:**
- المسافة الكلية + المدى المتاح
- عدد محطات الشحن المطلوبة
- الوقت الإجمالي (قيادة + شحن)
- التكلفة الكلية بـ NIS
- إجمالي الـ kWh
- Timeline بصري للرحلة

**API Endpoints:**
- `GET /api/ai/recommend` — توصية محطة
- `POST /api/ai/route` — تخطيط رحلة

---

### 7. نظام الإشعارات (Notifications)

**ما تم تنفيذه:**
- ✅ إشعار عند: تأكيد حجز، إلغاء، موافقة host، payout، مراجعة جديدة، إحالة
- ✅ شاشة إشعارات كاملة مع:
  - ألوان وأيقونات حسب النوع
  - نقطة خضراء للإشعارات الغير مقروءة
  - السحب لليسار للحذف
  - الضغط للتعليم كمقروء
  - زر "Mark all read"
  - Pull-to-refresh
- ✅ عداد للإشعارات غير المقروءة

**API Endpoints:**
- `GET /api/notifications`
- `GET /api/notifications/unread-count`
- `PUT /api/notifications/:id/read`
- `PUT /api/notifications/read-all`
- `DELETE /api/notifications/:id`

---

### 8. التقييمات والمراجعات (Reviews)

**ما تم تنفيذه:**
- ✅ تقييم المحطات (1-5 نجوم) مع تعليق اختياري
- ✅ شرط حجز مكتمل قبل التقييم (Anti-spam)
- ✅ مراجعة واحدة لكل محطة لكل مستخدم (يمكن تعديلها)
- ✅ تحديث تقييم المحطة تلقائياً (المتوسط)
- ✅ شاشة المراجعات مع avatar للمستخدم

**API Endpoints:**
- `GET /api/reviews/station/:id` — مراجعات محطة
- `GET /api/reviews/me` — مراجعاتي
- `POST /api/reviews/:stationId` — إضافة/تعديل مراجعة
- `DELETE /api/reviews/:id` — حذف مراجعة

---

### 9. نظام الإحالة (Referrals)

**ما تم تنفيذه:**
- ✅ كود إحالة فريد لكل مستخدم (تلقائي 7 أحرف)
- ✅ السائق الأول يحصل على **10 NIS**
- ✅ السائق الجديد يحصل على **5 NIS welcome bonus**
- ✅ شاشة "Invite Friends" كاملة:
  - كود الإحالة الخاص
  - زر نسخ
  - إحصائيات (عدد المدعوّين + الكسب الإجمالي)
  - قائمة الأصدقاء اللي انضموا
  - شرح كيف يشتغل (3 خطوات)

**API Endpoints:**
- `GET /api/referrals/me` — كودي وإحصائياتي
- `GET /api/referrals/validate/:code` — التحقق من كود

---

### 10. برنامج الولاء (Loyalty Program)

**ما تم تنفيذه:**

**ثلاث مستويات (Tiers):**

| المستوى | النقاط | الخصم |
|---|---|---|
| 🥉 **Bronze** | 0 - 499 | 0% |
| 🥈 **Silver** | 500 - 1999 | 5% |
| 🥇 **Gold** | 2000+ | 10% |

**ما تم تنفيذه:**
- ✅ احتساب تلقائي حسب النقاط
- ✅ خصم تلقائي عند الحجز
- ✅ شاشة Loyalty Program كاملة:
  - بطاقة الـ tier الحالي
  - شريط تقدم للمستوى التالي
  - عرض الفوائد (Benefits)
  - عرض كل المستويات
- ✅ كسب 10 نقاط لكل حجز

**API Endpoints:**
- `GET /api/users/loyalty` — بيانات الـ tier

---

### 11. كوبونات الخصم (Promo Codes)

**ما تم تنفيذه:**
- ✅ نظام كامل للأكواد:
  - نسبة مئوية أو مبلغ ثابت
  - تاريخ انتهاء
  - حد أقصى للاستخدامات
  - حد أدنى لمبلغ الحجز
  - استخدام مرة واحدة لكل مستخدم
- ✅ التحقق من الكود قبل تطبيقه
- ✅ تطبيق تلقائي عند الحجز
- ✅ عرض الأكواد الفعّالة في شاشة Offers
- ✅ admin CRUD للأدمن

**API Endpoints:**
- `POST /api/promos/validate` — التحقق من كود
- `GET /api/promos/list` — الأكواد الفعّالة
- `GET /api/admin/promos` — كل الأكواد (admin)
- `POST /api/admin/promos` — إنشاء كود (admin)
- `PUT /api/admin/promos/:id` — تعديل (admin)
- `DELETE /api/admin/promos/:id` — حذف (admin)

---

### 12. متتبع البيئة (CO2 Tracker)

**ما تم تنفيذه:**
- ✅ احتساب CO2 الموفّر من تاريخ الشحن
- ✅ صيغة دقيقة:
  - 1 kWh ≈ 5 km من المدى الكهربائي
  - 0.71 kg CO2 موفّر لكل kWh
  - 1 شجرة تمتص 21 kg CO2/سنة
  - 12 km لكل لتر بنزين
- ✅ شاشة Eco Impact كاملة:
  - بطاقة hero بـ CO2 الموفّر
  - 4 إحصائيات: مسافة، طاقة، بنزين موفّر، أشجار معادلة
  - قائمة الإنجازات

**API Endpoints:**
- `GET /api/users/co2` — إحصائيات البيئة

---

### 13. لوحة المُضيف (Host Dashboard)

**ما تم تنفيذه:**
- ✅ إضافة شاحن جديد بكل التفاصيل:
  - الموقع على الخريطة
  - 10 خيارات Power (7 إلى 350 kW + AC)
  - 8 أنواع Connector
  - 8 شبكات (Tesla, ChargePoint, إلخ)
  - 11 خدمة (Amenities)
  - 7 أنواع مواقف (Parking)
  - 5 أنواع مركبات (Vehicles)
- ✅ تعديل المحطات
- ✅ تغيير حالة المحطة (Free / Busy / Offline)
- ✅ إحصائيات الـ Host:
  - الأرباح الكلية
  - حجوزات اليوم
  - الشواحن النشطة
  - متوسط التقييم
- ✅ تحليلات بيانية لآخر 7 أيام
- ✅ إدارة Payouts (طلب صرف الأموال)
- ✅ تحديث ملف الـ Host
- ✅ عرض المراجعات

**API Endpoints:**
- `GET /api/host/stats` — إحصائيات
- `GET /api/host/stations` — شواحني
- `POST /api/host/stations` — إضافة شاحن
- `PUT /api/host/stations/:id` — تعديل
- `PUT /api/host/stations/:id/occupancy` — تغيير الحالة
- `GET /api/host/bookings` — حجوزات شواحني
- `GET /api/host/analytics` — تحليلات
- `GET /api/host/payouts` — تاريخ الـ payouts
- `POST /api/host/payouts/request` — طلب صرف
- `GET /api/host/reviews` — مراجعات شواحني

---

### 14. لوحة الإدارة (Admin Panel)

**ما تم تنفيذه:**
- ✅ إحصائيات شاملة (مستخدمين، محطات، حجوزات، أرباح)
- ✅ إدارة Hosts (موافقة/رفض الطلبات)
- ✅ إدارة المستخدمين (تحديث الرصيد، حذف)
- ✅ إدارة المحطات
- ✅ إدارة Payouts
- ✅ إدارة Promo Codes
- ✅ إدارة تذاكر الدعم (Support Tickets)

**API Endpoints:**
- `GET /api/admin/analytics`
- `GET /api/admin/hosts/pending`
- `PUT /api/admin/hosts/:id/approve`
- `PUT /api/admin/hosts/:id/reject`
- `GET /api/admin/users`
- `PUT /api/admin/users/:id/balance`
- `DELETE /api/admin/users/:id`
- `GET /api/admin/stations`
- `PUT /api/admin/stations/:id`
- `DELETE /api/admin/stations/:id`
- `GET /api/admin/payouts`
- `PUT /api/admin/payouts/:id/approve`
- `PUT /api/admin/payouts/:id/reject`

---

### 15. ميزات إضافية

- ✅ المحفظة (Wallet) مع شحن رصيد
- ✅ بطاقات الدفع (Cards Management)
- ✅ الدعم الفني (Support Tickets + Live Chat)
- ✅ تتبع جلسة الشحن (Charging Session)
- ✅ مزامنة البطارية
- ✅ سجل المعاملات (Transactions)
- ✅ التحويل بين الحسابات

---

## 📊 قواعد البيانات (Database Models)

| الموديل | الوصف |
|---|---|
| **User** | المستخدمون (drivers + hosts + admins) |
| **Station** | محطات الشحن |
| **Booking** | الحجوزات |
| **Transaction** | المعاملات المالية |
| **Notification** | الإشعارات |
| **Review** | المراجعات |
| **Bookmark** | المفضلة |
| **Chat** | محادثات الدعم |
| **Ticket** | تذاكر الدعم |
| **Claim** | المطالبات بالعروض |
| **Payout** | طلبات صرف أموال الـ Host |
| **PromoCode** | كوبونات الخصم |
| **Card** | بطاقات الدفع |
| **Offer** | العروض الترويجية |

---

## 🔐 الأمان (Security)

- ✅ تشفير كلمات المرور بـ bcrypt (salt rounds: 10)
- ✅ مصادقة بـ JWT tokens
- ✅ Middleware للحماية (`protect`, `hostApproved`, `adminOnly`)
- ✅ شرط حجز مكتمل قبل التقييم (Anti-spam)
- ✅ تحقق من ملكية الحجز قبل الإلغاء
- ✅ Hosts يقدروا يعدلوا فقط شواحنهم

---

## 🌟 مزايا تقنية متقدمة

1. **Haversine Algorithm** — حساب المسافات الجغرافية
2. **Greedy Algorithm** — اختيار محطات الشحن في تخطيط الرحلة
3. **AI Integration** — Claude API للذكاء الاصطناعي
4. **Structured Outputs** — ضمان شكل البيانات من Claude
5. **Prompt Caching** — تحسين الأداء وتقليل التكاليف
6. **Real-time State** — تحديث فوري لحالة المحطات
7. **Geographic Search** — بحث مكاني فعّال
8. **Filter State Management** — Singleton pattern لمشاركة الفلاتر بين الشاشات

---

## 📈 إحصائيات المشروع

- **Backend:** 14 ملف routes، 14 موديل، 3 ملفات middleware، 6 ملفات utils
- **Frontend:** 40+ شاشة Flutter
- **API Endpoints:** 80+ endpoint
- **خطوط الكود:** 10,000+ سطر
- **عدد الـ commits:** 50+

---

## 🚀 المنشور على GitHub

```
https://github.com/safaanouri11/chargeguard-backend
```

---

## 🔮 التطوير المستقبلي (Future Work)

- [ ] نشر التطبيق على Google Play Store
- [ ] نشر التطبيق على Apple App Store
- [ ] دعم اللغة العربية الكامل (RTL)
- [ ] Push Notifications عبر Firebase
- [ ] دفع إلكتروني فعلي (Stripe / PayPal)
- [ ] خرائط Google Maps بدل OpenStreetMap
- [ ] محادثة فورية مع الـ Host (Real-time chat)
- [ ] تحليلات أعمق للمشتركين
- [ ] برنامج Affiliate للشركات
- [ ] دعم أنواع سيارات أكثر (Tesla Connector, إلخ)

---

## 📞 معلومات التواصل

**المطوّرة:** Safa Anouri
**الجامعة:** جامعة النجاح الوطنية
**التاريخ:** 2026

---

*هذا المشروع تم بناؤه باستخدام Claude AI لمساعدة التطوير، ويعكس أفضل ممارسات تطوير تطبيقات الويب الحديثة والذكاء الاصطناعي.*
