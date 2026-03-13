/// إعدادات بوابة الدفع MyFatoorah
/// للتبديل بين الوضع التجريبي والإنتاجي
class PaymentConfig {
  PaymentConfig._();

  /// الوضع الحالي - يُقرأ من الخادم
  static bool _isTestMode = true;

  /// هل MyFatoorah مفعّل؟
  static bool _isEnabled = false;

  /// تحديث الإعدادات من الخادم
  static void updateFromServer({
    required bool isEnabled,
    required bool isTestMode,
  }) {
    _isEnabled = isEnabled;
    _isTestMode = isTestMode;
  }

  /// هل الوضع تجريبي؟
  static bool get isTestMode => _isTestMode;

  /// هل MyFatoorah مفعّل؟
  static bool get isEnabled => _isEnabled;

  /// Base URL حسب الوضع
  static String get baseUrl => _isTestMode
      ? 'https://apitest.myfatoorah.com'
      : 'https://api.myfatoorah.com';

  /// اسم الوضع للعرض
  static String get modeName => _isTestMode ? 'تجريبي' : 'إنتاجي';

  /// لون الوضع للعرض
  static String get modeColor => _isTestMode ? 'orange' : 'green';
}
