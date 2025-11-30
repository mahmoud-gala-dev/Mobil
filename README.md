# تطبيق Engeb Mobile (Flutter/Dart)

## نظرة عامة
تطبيق موبايل متكامل لمنصة Engeb للتجارة الإلكترونية مبني بـ Flutter/Dart مع ربط كامل لجميع مسارات API.

## المميزات الرئيسية

### 1. المستخدمين (Users)
- ✅ التسجيل وتسجيل الدخول
- ✅ عرض المنتجات المميزة
- ✅ البحث والفلترة
- ✅ التصنيفات والتصنيفات الفرعية
- ✅ تفاصيل المنتجات
- ✅ سلة التسوق
- ✅ قائمة الأمنيات
- ✅ الطلبات وتتبع الطلبات
- ✅ العناوين
- ✅ الملف الشخصي والإعدادات
- ✅ التقييمات والمراجعات
- ✅ العروض والخصومات
- ✅ الكوبونات
- ✅ عرض المتاجر والموردين

### 2. البائعين (Vendors)
- ✅ لوحة تحكم البائع
- ✅ إدارة المنتجات (إضافة، تعديل، حذف)
- ✅ إدارة الطلبات وتحديث الحالة
- ✅ التقارير والإحصائيات
- ✅ الإشعارات
- ✅ الإعدادات

### 3. المميزات الإضافية
- ✅ البحث التلقائي (Autocomplete)
- ✅ الأسئلة الشائعة (FAQs)
- ✅ التواصل والدعم
- ✅ النشرة البريدية
- ✅ الصفحات الثابتة (من نحن، الشروط، الخصوصية)

## هيكل المشروع

```
Mobil/
├── lib/
│   ├── main.dart                    # نقطة البداية
│   ├── elite_one_app.dart           # تطبيق Flutter الرئيسي
│   ├── models/
│   │   └── models.dart              # نماذج البيانات
│   ├── services/
│   │   └── api_service.dart         # خدمة API الشاملة
│   ├── state/
│   │   ├── cart_provider.dart       # إدارة حالة السلة
│   │   ├── favorites_provider.dart  # إدارة حالة المفضلة
│   │   └── products_provider.dart   # إدارة حالة المنتجات
│   └── ui/
│       ├── screens/                 # جميع الشاشات
│       │   ├── home_screen.dart
│       │   ├── categories_screen.dart
│       │   ├── category_screen.dart
│       │   ├── product_details_screen.dart
│       │   ├── cart_screen.dart
│       │   ├── checkout_screen.dart
│       │   ├── orders_screen.dart
│       │   ├── order_track_screen.dart
│       │   ├── favorites_screen.dart
│       │   ├── search_screen.dart
│       │   ├── login_screen.dart
│       │   ├── register_screen.dart
│       │   ├── profile_screen.dart
│       │   ├── vendors_screen.dart         # جديد
│       │   ├── offers_screen.dart          # جديد
│       │   ├── addresses_screen.dart       # جديد
│       │   ├── settings_screen.dart        # جديد
│       │   └── vendor_dashboard_screen.dart # جديد
│       └── widgets/
│           └── product_card.dart
├── pubspec.yaml                     # التبعيات
└── README.md                        # هذا الملف
```

## API Service - جميع المسارات المتاحة

### 🔍 البحث (Search)
```dart
search(String q)                           // البحث العام
searchProducts(String q, filters)          // البحث في المنتجات مع فلاتر
getSearchFilters()                         // الحصول على الفلاتر المتاحة
getPopularSearches()                       // عمليات البحث الشائعة
autocomplete(String q)                     // الإكمال التلقائي
```

### 📦 التصنيفات (Categories)
```dart
categories()                               // جميع التصنيفات
mainCategories()                           // التصنيفات الرئيسية
supermarketCategories()                    // تصنيفات السوبرماركت
categoryDetails(String slug)               // تفاصيل تصنيف
categorySubcategories(String slug)         // التصنيفات الفرعية
categoryProducts(String slug)              // منتجات التصنيف
```

### 🛍️ المنتجات (Products)
```dart
featured()                                 // المنتجات المميزة
freshProducts()                            // المنتجات الطازجة
offerProducts()                            // منتجات العروض
productDetails(int id)                     // تفاصيل منتج
```

### 🏪 المتاجر/الموردين (Vendors)
```dart
vendors({filters})                         // جميع المتاجر
featuredVendors()                          // المتاجر المميزة
vendorDetails(int id)                      // تفاصيل متجر
vendorProducts(int vendorId)               // منتجات المتجر
```

### 🎉 العروض (Offers)
```dart
offers({filters})                          // جميع العروض
featuredOffers()                           // العروض المميزة
flashSaleOffers()                          // عروض الفلاش
searchOffers(String q)                     // البحث في العروض
offerDetails(int id)                       // تفاصيل عرض
offersByCategory(int categoryId)           // عروض حسب التصنيف
offerCategories()                          // تصنيفات العروض
```

### 🛒 السلة (Cart)
```dart
cart()                                     // محتويات السلة
cartCount()                                // عدد المنتجات
addToCart(int productId, {quantity})       // إضافة للسلة
updateCart(int productId, int quantity)    // تحديث الكمية
removeFromCart(int productId)              // حذف من السلة
clearCart()                                // إفراغ السلة
applyCoupon(String code)                   // تطبيق كوبون
removeCoupon()                             // إزالة الكوبون
```

### 💳 الدفع (Checkout)
```dart
getCheckoutData()                          // بيانات الدفع
checkout({...})                            // إتمام الطلب
```

### ❤️ المفضلة (Wishlist)
```dart
wishlist()                                 // قائمة المفضلة
addWishlist(int productId)                 // إضافة للمفضلة
removeWishlist(int productId)              // إزالة من المفضلة
```

### 📝 الطلبات (Orders)
```dart
recentOrders()                             // الطلبات الأخيرة
trackOrder(String orderNumber)             // تتبع طلب
orderConfirmation(String orderNumber)      // تأكيد الطلب
orderDetails(int orderId)                  // تفاصيل الطلب
downloadInvoice(String orderNumber)        // تحميل الفاتورة
```

### 👤 المصادقة (Auth)
```dart
login(String email, String password)       // تسجيل الدخول
register(...)                              // التسجيل
logout()                                   // تسجيل الخروج
me()                                       // معلومات المستخدم
updateProfile({...})                       // تحديث الملف الشخصي
changePassword({...})                      // تغيير كلمة المرور
```

### 🏢 مصادقة البائعين (Vendor Auth)
```dart
vendorRegister({...})                      // تسجيل بائع جديد
vendorLogin(String email, String password) // تسجيل دخول البائع
vendorLogout()                             // تسجيل خروج البائع
vendorMe()                                 // معلومات البائع
vendorUpdateProfile(data)                  // تحديث ملف البائع
vendorValidateToken(String token)          // التحقق من التوكن
```

### 📊 لوحة تحكم البائع (Vendor Dashboard)
```dart
vendorDashboardStats()                     // إحصائيات اللوحة
vendorRecentOrders()                       // الطلبات الأخيرة
vendorTopProducts()                        // المنتجات الأكثر مبيعاً
vendorNotifications()                      // الإشعارات
vendorMarkNotificationsRead(ids)           // تحديد كمقروءة
vendorUnreadNotificationsCount()           // عدد غير المقروءة
```

### 📦 منتجات البائع (Vendor Products)
```dart
vendorGetProducts({params})                // منتجات البائع
vendorCreateProduct(data)                  // إضافة منتج
vendorGetProduct(int productId)            // تفاصيل منتج
vendorUpdateProduct(id, data)              // تحديث منتج
vendorDeleteProduct(int productId)         // حذف منتج
```

### 🛍️ طلبات البائع (Vendor Orders)
```dart
vendorGetOrders({params})                  // طلبات البائع
vendorGetOrder(int orderId)                // تفاصيل طلب
vendorUpdateOrderStatus(id, status)        // تحديث حالة الطلب
```

### 📈 تقارير البائع (Vendor Reports)
```dart
vendorReports({params})                    // التقارير
vendorSalesReport({dates})                 // تقرير المبيعات
vendorProductsReport()                     // تقرير المنتجات
vendorRevenueReport({dates})               // تقرير الإيرادات
```

### 📍 العناوين (Addresses)
```dart
getAddresses()                             // جميع العناوين
createAddress(data)                        // إضافة عنوان
updateAddress(id, data)                    // تحديث عنوان
deleteAddress(int addressId)               // حذف عنوان
setDefaultAddress(int addressId)           // تعيين افتراضي
```

### ⭐ التقييمات (Reviews)
```dart
getProductReviews(int productId)           // تقييمات منتج
getVendorReviews(int vendorId)             // تقييمات متجر
getProductReviewStats(int productId)       // إحصائيات التقييمات
storeProductReview({...})                  // إضافة تقييم منتج
storeVendorReview({...})                   // إضافة تقييم متجر
updateProductReview(id, {...})             // تحديث تقييم
deleteProductReview(int reviewId)          // حذف تقييم
rateProductReview(id, isHelpful)           // تقييم مفيد/غير مفيد
```

### 🎫 الكوبونات (Coupons)
```dart
getCoupons()                               // جميع الكوبونات
validateCoupon(String code)                // التحقق من كوبون
applyCouponCode(String code)               // تطبيق كوبون
```

### 📧 النشرة البريدية (Newsletter)
```dart
subscribeNewsletter(String email)          // الاشتراك
unsubscribeNewsletter(String email)        // إلغاء الاشتراك
resubscribeNewsletter(String email)        // إعادة الاشتراك
checkNewsletterSubscription(email)         // التحقق من الاشتراك
```

### ⚙️ الإعدادات (Settings)
```dart
getSettings()                              // جميع الإعدادات
getGeneralSettings()                       // الإعدادات العامة
getEmailSettings()                         // إعدادات البريد
getPaymentSettings()                       // إعدادات الدفع
getSeoSettings()                           // إعدادات SEO
getDesignSettings()                        // إعدادات التصميم
getDeveloperSettings()                     // إعدادات المطور
getSettingsByGroup(String group)           // حسب المجموعة
getSettingByKey(String key)                // حسب المفتاح
```

### 📄 الصفحات الثابتة (Static Pages)
```dart
getStaticPages()                           // جميع الصفحات
getStaticPageBySlug(String slug)           // صفحة حسب الرابط
getTermsPage()                             // الشروط والأحكام
getPrivacyPage()                           // الخصوصية
getRefundPage()                            // سياسة الاسترجاع
```

### 📞 التواصل والدعم (Contact & Support)
```dart
sendContact({...})                         // إرسال رسالة
getContactStats()                          // إحصائيات التواصل
getSupportChannels()                       // قنوات الدعم
getFaqs()                                  // الأسئلة الشائعة
getFaqCategories()                         // تصنيفات الأسئلة
```

### 📍 المواقع (Locations)
```dart
governorates()                             // جميع المحافظات
governorateDetails(int id)                 // تفاصيل محافظة
governorateCities(int governorateId)       // مدن المحافظة
cities()                                   // جميع المدن
cityDetails(int id)                        // تفاصيل مدينة
getGovernorates()                          // محافظات مبسطة
getCities({governorateId})                 // مدن حسب المحافظة
```

### 🏷️ العلامات التجارية والفئات (Brands & Categories)
```dart
brands()                                   // جميع العلامات
brandDetails(int id)                       // تفاصيل علامة
brandProducts(int brandId)                 // منتجات العلامة
businessCategories()                       // فئات الأعمال
businessCategoryDetails(int id)            // تفاصيل فئة
contactMethods()                           // طرق التواصل
```

## الإعداد والتشغيل

### المتطلبات
- Flutter SDK >= 3.3.0
- Dart >= 3.3.0

### التبعيات الرئيسية
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.5           # إدارة الحالة
  dio: ^5.7.0               # HTTP Client
  dio_cookie_manager: ^3.1.0 # إدارة الكوكيز
  cookie_jar: ^4.0.8        # تخزين الكوكيز
  go_router: ^14.2.3        # التنقل
  google_fonts: ^6.2.1      # الخطوط
  intl: ^0.19.0             # الترجمة والتنسيق
```

### التثبيت
```bash
# 1. تثبيت التبعيات
flutter pub get

# 2. تشغيل التطبيق
flutter run

# 3. بناء APK
flutter build apk --release

# 4. بناء iOS
flutter build ios --release
```

### تكوين API
التطبيق الآن متصل بـ: `http://192.168.100.80/Domain_project/engeb/public/api/v1`

للتغيير، افتح `lib/config/api_config.dart` وعدّل:

```dart
static const String defaultBaseUrl = serverBaseUrl; // السيرفر الفعلي

// أو اختر من الخيارات المتاحة:
// - developmentBaseUrl (localhost:8000)
// - androidEmulatorBaseUrl (10.0.2.2:8000)
// - localNetworkBaseUrl (192.168.1.x:8000)
// - serverBaseUrl (192.168.100.80/Domain_project/engeb/public)
// - productionBaseUrl (https://api.engeb.com)
```

### تشغيل مع API مخصص
```bash
flutter run --dart-define=API_BASE=http://192.168.100.80/Domain_project/engeb/public/api/v1
```

## الاستخدام

### 1. استخدام API Service
```dart
import 'package:your_app/services/api_service.dart';

// الحصول على المنتجات المميزة
final products = await ApiService.I.featured();

// البحث عن منتجات
final results = await ApiService.I.search('عنب');

// إضافة للسلة
await ApiService.I.addToCart(productId: 123, quantity: 2);
```

### 2. إدارة الحالة مع Provider
```dart
// في الشاشة
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    
    return Text('عدد المنتجات: ${cart.itemCount}');
  }
}
```

### 3. التنقل بين الشاشات
```dart
// الانتقال لشاشة تفاصيل المنتج
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (ctx) => ProductDetailsScreen(productId: 123),
  ),
);
```

## ملاحظات مهمة

### 1. المصادقة
- يتم استخدام الكوكيز لإدارة الجلسات (Session-based)
- يتم تخزين الكوكيز تلقائياً باستخدام `dio_cookie_manager`
- للبائعين: يتم استخدام التوكن بالإضافة للكوكيز

### 2. معالجة الأخطاء
جميع استدعاءات API يجب أن تكون داخل `try-catch`:

```dart
try {
  final data = await ApiService.I.someMethod();
  // معالجة النجاح
} catch (e) {
  // معالجة الخطأ
  print('خطأ: $e');
}
```

### 3. التحديث التلقائي
استخدم `RefreshIndicator` للتحديث بالسحب للأسفل:

```dart
RefreshIndicator(
  onRefresh: _loadData,
  child: ListView(...),
)
```

## الشاشات المتاحة

### للمستخدمين
1. ✅ الرئيسية (Home)
2. ✅ التصنيفات (Categories)
3. ✅ تفاصيل التصنيف (Category Details)
4. ✅ تفاصيل المنتج (Product Details)
5. ✅ البحث (Search)
6. ✅ السلة (Cart)
7. ✅ الدفع (Checkout)
8. ✅ الطلبات (Orders)
9. ✅ تتبع الطلب (Order Tracking)
10. ✅ المفضلة (Favorites)
11. ✅ تسجيل الدخول (Login)
12. ✅ التسجيل (Register)
13. ✅ الملف الشخصي (Profile)
14. ✅ المتاجر (Vendors) - جديد
15. ✅ العروض (Offers) - جديد
16. ✅ العناوين (Addresses) - جديد
17. ✅ الإعدادات (Settings) - جديد

### للبائعين
1. ✅ لوحة التحكم (Dashboard)
2. ✅ المنتجات (Products)
3. ✅ الطلبات (Orders)
4. ✅ الإشعارات (Notifications)
5. ✅ الإعدادات (Settings)

## ✅ التحسينات المكتملة (v2.0.0)

- [x] إضافة الوضع الليلي (Dark Mode) ✨
- [x] تحسين التخزين المؤقت (Caching) مع SharedPreferences 💾
- [x] إضافة اختبارات الوحدة (90+ Unit Tests) 🧪
- [x] تحسين تجربة المستخدم (UX) 🎨
- [x] إضافة الرسوم المتحركة (Animations) 🎭
- [x] Shimmer Loading Effects ✨
- [x] Empty/Error States 📋
- [x] 7 Providers إضافية (Orders, Notifications, Reviews, Vendors, Offers, Auth, Addresses) 🔄

## TODO - التحسينات المستقبلية

- [ ] إضافة الترجمة (i18n)
- [ ] إضافة التنبيهات Push Notifications
- [ ] Offline Mode
- [ ] Payment Gateway Integration
- [ ] Social Login
- [ ] Deep Linking
- [ ] Analytics Integration

## الدعم والتواصل

للمساعدة والاستفسارات:
- البريد الإلكتروني: support@engeb.com
- الموقع: https://engeb.com

## الترخيص
جميع الحقوق محفوظة © 2024 Engeb

