/// تكوين API - Engeb Mobile App
/// 
/// هذا الملف يحتوي على جميع إعدادات الاتصال بالـ API
library;

class ApiConfig {
  // ============ عناوين API ============
  
  /// عنوان API للتطوير (Development)
  static const String developmentBaseUrl = 'https://adminxd.eliteonegrocery.com/api/v1';
  
  /// عنوان API للمحاكي Android
  static const String androidEmulatorBaseUrl = 'https://adminxd.eliteonegrocery.com/api/v1';
  
  /// عنوان API للشبكة المحلية (استبدل بـ IP جهازك)
  static const String localNetworkBaseUrl = 'https://adminxd.eliteonegrocery.com/api/v1';
  
  /// عنوان API للسيرفر الفعلي - Engeb Project
  static const String serverBaseUrl = 'https://adminxd.eliteonegrocery.com/api/v1';
  
  /// عنوان API للإنتاج (Production)
  // static const String productionBaseUrl = 'https://eliteonegrocery.com/ad/public/api/v1';
    static const String productionBaseUrl = 'https://adminxd.eliteonegrocery.com/api/v1';

  // ============ مسارات الصور والملفات ============
  
  /// المسار الأساسي للصور والملفات (بدون /api/v1)
  static const String serverStorageUrl = 'https://eliteonegrocery.com/ad/public';
  //
  /// المسار الأساسي للصور في الإنتاج
  static const String productionStorageUrl = 'https://eliteonegrocery.com/ad/public';
  
  /// الحصول على مسار التخزين الحالي
  static String get storageUrl {
    // استخدام نفس البيئة المستخدمة في API
    if (baseUrl.contains('eliteonegrocery.com')) {
      return productionStorageUrl;
    } else if (baseUrl.contains('192.168.100.98')) {
      return serverStorageUrl;
    } else if (baseUrl.contains('localhost') || baseUrl.contains('10.0.2.2')) {
      return 'http://localhost:8000';
    } else if (baseUrl.contains('192.168')) {
      return 'http://192.168.1.100:8000';
    } else {
      return productionStorageUrl;
    }
  }
  
  // ============ العنوان الحالي ============
  
  /// العنوان الافتراضي المستخدم
  /// 
  /// للتبديل بين البيئات، غير القيمة هنا:
  /// - developmentBaseUrl للتطوير على iOS/Web
  /// - androidEmulatorBaseUrl للمحاكي Android
  /// - localNetworkBaseUrl للجهاز الفعلي على نفس الشبكة
  /// - serverBaseUrl للسيرفر الفعلي على الشبكة المحلية
  /// - productionBaseUrl للإنتاج
  static const String defaultBaseUrl = serverBaseUrl; // غيّر هنا
  
  /// الحصول على عنوان API الحالي
  /// يمكن تجاوزه عبر Environment Variable
  static String get baseUrl {
    const envBaseUrl = String.fromEnvironment('API_BASE');
    if (envBaseUrl.isNotEmpty) {
      return envBaseUrl;
    }
    return defaultBaseUrl;
  }
  
  // ============ الإعدادات ============
  
  /// مدة انتظار الاتصال (بالثواني)
  /// تم زيادة القيمة لتعطي وقتاً أكبر للاتصال بالخادم على الشبكة المحلية
  static const int connectionTimeout = 45;
  
  /// مدة انتظار الاستجابة (بالثواني)
  /// تم زيادة القيمة لتعطي وقتاً أكبر لاستقبال البيانات من الخادم
  static const int receiveTimeout = 45;
  
  /// عدد محاولات إعادة الطلب عند الفشل
  static const int maxRetries = 3;
  
  /// تفعيل تسجيل الطلبات (Logging)
  static const bool enableLogging = true;
  
  // ============ Headers ============
  
  /// Headers الافتراضية للطلبات
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-Requested-With': 'XMLHttpRequest',
  };
  
  // ============ مسارات API الرئيسية ============
  
  static const String authPath = '/auth';
  static const String productsPath = '/products';
  static const String categoriesPath = '/categories';
  static const String cartPath = '/cart';
  static const String ordersPath = '/orders';
  static const String vendorsPath = '/vendors';
  static const String offersPath = '/offers';
  static const String reviewsPath = '/reviews';
  static const String wishlistPath = '/wishlist';
  static const String addressesPath = '/addresses';
  static const String searchPath = '/search';
  
  // ============ دوال مساعدة ============
  
  /// بناء URL كامل من مسار نسبي
  static String buildUrl(String path) {
    return '$baseUrl$path';
  }
  
  /// الحصول على معلومات البيئة الحالية
  static String get environmentInfo {
    if (baseUrl.contains('localhost') || baseUrl.contains('10.0.2.2')) {
      return '🔧 Development';
    } else if (baseUrl.contains('192.168')) {
      return '🏠 Local Network';
    } else {
      return '🚀 Production';
    }
  }
  
  /// طباعة معلومات التكوين
  static void printConfig() {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📱 Engeb Mobile - API Configuration');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🌐 API Base URL: $baseUrl');
    print('🖼️  Storage URL: $storageUrl');
    print('🏷️  Environment: $environmentInfo');
    print('⏱️  Connection Timeout: ${connectionTimeout}s');
    print('📥 Receive Timeout: ${receiveTimeout}s');
    print('🔁 Max Retries: $maxRetries');
    print('📝 Logging: ${enableLogging ? 'Enabled' : 'Disabled'}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }
}

/// أمثلة الاستخدام:
/// 
/// ```dart
/// // في api_service.dart
/// final dio = Dio(BaseOptions(
///   baseUrl: ApiConfig.baseUrl,
///   connectTimeout: Duration(seconds: ApiConfig.connectionTimeout),
///   receiveTimeout: Duration(seconds: ApiConfig.receiveTimeout),
///   headers: ApiConfig.defaultHeaders,
/// ));
/// 
/// // طباعة التكوين
/// ApiConfig.printConfig();
/// 
/// // تشغيل مع عنوان مخصص
/// flutter run --dart-define=API_BASE=http://192.168.1.50:8000/api/v1
/// ```

