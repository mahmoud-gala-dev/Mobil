# 🎨 إرشادات أيقونة التطبيق - Engeb

## 📱 نظرة عامة
هذا المجلد يحتوي على جميع الملفات المطلوبة لإنشاء أيقونات تطبيق Engeb الاحترافية.

## 🚀 طريقة سريعة لإنشاء الأيقونات

### الطريقة 1: استخدام HTML Generator (الأسهل)
1. افتح ملف `generate_app_icon.html` في المتصفح
2. اضغط على زر "تحميل جميع الأحجام"
3. احفظ الملفات المحملة في مجلد `assets/icon/`
4. قم بتشغيل:
   ```bash
   flutter pub run flutter_launcher_icons
   ```

### الطريقة 2: استخدام Batch Script (لـ Windows)
```bash
# قم بتشغيل
CREATE_APP_ICON_NOW.bat
```

أو

```bash
INSTALL_ICONS.bat
```

## 📦 الملفات المطلوبة

يجب أن تحتوي على الملفات التالية:

- `app_icon.png` - 1024×1024 px (الأيقونة الرئيسية)
- `app_icon_foreground.png` - 180×180 px (للـ Android Adaptive Icon)
- `app_icon_512.png` - 512×512 px (اختياري)
- `app_icon_192.png` - 192×192 px (اختياري)

## ⚙️ التكوين في pubspec.yaml

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
  adaptive_icon_background: "#16A34A"
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
  min_sdk_android: 21
  remove_alpha_ios: true
```

## 🎨 مواصفات التصميم

### الألوان الرئيسية
- **الأخضر الداكن**: #16A34A
- **الأخضر المتوسط**: #22C55E
- **الأخضر الفاتح**: #4ADE80

### العناصر البصرية
- أيقونة حقيبة تسوق (Shopping Bag) باللون الأبيض
- خلفية متدرجة خضراء احترافية
- ظلال ناعمة لإعطاء عمق
- تصميم modern وminimalist

## 📝 ملاحظات مهمة

### لـ Android
- يتم إنشاء Adaptive Icons تلقائياً
- الخلفية: اللون الأخضر (#16A34A)
- الـ Foreground: أيقونة حقيبة التسوق البيضاء

### لـ iOS
- يتم إزالة الشفافية (Alpha) تلقائياً
- دعم جميع الأحجام المطلوبة

## 🔧 استكشاف الأخطاء

### إذا لم تعمل الأوامر:

```bash
# قم بتحديث الحزم أولاً
flutter pub get

# ثم جرب
dart run flutter_launcher_icons

# أو
flutter pub run flutter_launcher_icons:main
```

### إذا كنت تستخدم Flutter 3.0+:

```bash
dart run flutter_launcher_icons
```

## 🎯 نصائح للتصميم الاحترافي

1. **البساطة**: استخدم تصميم بسيط وواضح
2. **التباين**: تأكد من وضوح الأيقونة على خلفيات مختلفة
3. **الألوان**: استخدم ألوان تعبر عن هوية التطبيق
4. **القابلية للتمييز**: يجب أن تكون الأيقونة مميزة عن تطبيقات أخرى

## 📱 اختبار الأيقونات

بعد إنشاء الأيقونات، قم باختبارها:

```bash
# على Android
flutter run

# على iOS
flutter run -d ios
```

## 🆘 الدعم

إذا واجهت مشاكل:
1. تأكد من أن حزمة `flutter_launcher_icons` مثبتة في pubspec.yaml
2. تحقق من أن الملفات موجودة في المسار الصحيح
3. حاول حذف وإعادة إنشاء الأيقونات

---

**🛍️ Engeb - متجرك الإلكتروني المتكامل**

© 2025 جميع الحقوق محفوظة



