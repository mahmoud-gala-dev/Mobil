import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

/// AppSettingsProvider
///
/// Provider لإدارة إعدادات التطبيق المجلوبة من الـ API
/// يتضمن الشعار الافتراضي للمنتجات وإعدادات الموقع
class AppSettingsProvider extends ChangeNotifier {
  // حالة التحميل
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // حالة الخطأ
  String? _error;
  String? get error => _error;

  // إعدادات الموقع
  String _siteName = 'إيليت وان';
  String get siteName => _siteName;

  String _siteNameEn = 'Elite One';
  String get siteNameEn => _siteNameEn;

  String? _siteLogo;
  String? get siteLogo => _siteLogo;

  String? _siteLogoUrl;
  String? get siteLogoUrl => _siteLogoUrl;

  // الصورة الافتراضية للمنتجات
  String? _defaultProductImage;
  String? get defaultProductImage => _defaultProductImage;

  String? _defaultProductImageUrl;
  String? get defaultProductImageUrl => _defaultProductImageUrl;

  // معلومات الاتصال
  String _contactPhone = '';
  String get contactPhone => _contactPhone;

  String _contactEmail = '';
  String get contactEmail => _contactEmail;

  // هل تم تحميل الإعدادات؟
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  /// جلب إعدادات التطبيق من الـ API
  Future<void> fetchSettings() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.I.getGeneralSettings();

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;

        _siteName = data['site_name'] ?? 'إيليت وان';
        _siteNameEn = data['site_name_en'] ?? 'Elite One';
        _siteLogo = data['site_logo'];
        _siteLogoUrl = data['site_logo_url'];
        _defaultProductImage = data['default_product_image'];
        _defaultProductImageUrl = data['default_product_image_url'];
        _contactPhone = data['contact_phone'] ?? '';
        _contactEmail = data['contact_email'] ?? '';

        _isLoaded = true;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ [AppSettingsProvider] فشل جلب الإعدادات: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// الحصول على صورة المنتج الافتراضية
  /// إذا لم يتم تحميل الإعدادات، يُرجع الشعار المحلي
  String getDefaultProductImageUrl() {
    // أولوية 1: الصورة الافتراضية المحددة من لوحة التحكم
    if (_defaultProductImageUrl != null && _defaultProductImageUrl!.isNotEmpty) {
      return _defaultProductImageUrl!;
    }

    // أولوية 2: شعار الموقع
    if (_siteLogoUrl != null && _siteLogoUrl!.isNotEmpty) {
      return _siteLogoUrl!;
    }

    // أولوية 3: صورة placeholder من الـ Storage
    return '${ApiConfig.storageUrl}/images/placeholder-product.png';
  }

  /// التحقق مما إذا كان URL صالحاً
  bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  /// إعادة تحميل الإعدادات
  Future<void> refresh() async {
    _isLoaded = false;
    await fetchSettings();
  }
}
