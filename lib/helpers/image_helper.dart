import '../config/api_config.dart';

/// Image Helper
/// 
/// دوال مساعدة للتعامل مع مسارات الصور وبناء URLs صحيحة
class ImageHelper {
  /// بناء URL كامل للصورة من مسار نسبي أو كامل
  /// 
  /// أمثلة:
  /// - 'products/image.jpg' → 'http://server/storage/products/image.jpg'
  /// - '/storage/products/image.jpg' → 'http://server/storage/products/image.jpg'
  /// - 'http://server/image.jpg' → 'http://server/image.jpg' (بدون تغيير)
  static String getFullImageUrl(String? imagePath) {
    // إذا كان null أو فارغ، أرجع placeholder
    if (imagePath == null || imagePath.trim().isEmpty) {
      return '';
    }

    final cleanPath = imagePath.trim();

    // إذا كان URL كامل، أرجعه مباشرة
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return cleanPath;
    }

    // تنظيف المسار من /storage/ و storage/ الزائدة
    String relativePath = cleanPath
        .replaceFirst(RegExp(r'^/+storage/+'), '')
        .replaceFirst(RegExp(r'^storage/+'), '');

    // بناء URL كامل
    final storageBase = ApiConfig.storageUrl;
    return '$storageBase/storage/$relativePath';
  }

  /// بناء URLs لعدة صور
  static List<String> getFullImageUrls(List<String>? imagePaths) {
    if (imagePaths == null || imagePaths.isEmpty) {
      return [];
    }

    return imagePaths
        .map((path) => getFullImageUrl(path))
        .where((url) => url.isNotEmpty)
        .toList();
  }

  /// الحصول على URL صورة placeholder عند الفشل
  static String getPlaceholderUrl({String type = 'product'}) {
    // يمكن إرجاع URL لصورة placeholder حسب النوع
    switch (type) {
      case 'product':
        return '${ApiConfig.storageUrl}/images/placeholder-product.png';
      case 'vendor':
        return '${ApiConfig.storageUrl}/images/placeholder-vendor.png';
      case 'category':
        return '${ApiConfig.storageUrl}/images/placeholder-category.png';
      case 'user':
        return '${ApiConfig.storageUrl}/images/placeholder-user.png';
      default:
        return '${ApiConfig.storageUrl}/images/placeholder.png';
    }
  }

  /// طباعة معلومات debug للصورة
  static void debugImage(String? imagePath) {
    print('🖼️ [ImageHelper] ═══════════════════════════════════');
    print('📥 [ImageHelper] Input Path: $imagePath');
    
    if (imagePath == null || imagePath.isEmpty) {
      print('⚠️ [ImageHelper] Path is null or empty');
      print('🖼️ [ImageHelper] ═══════════════════════════════════');
      return;
    }

    final fullUrl = getFullImageUrl(imagePath);
    print('📍 [ImageHelper] Storage Base: ${ApiConfig.storageUrl}');
    print('🌐 [ImageHelper] Full URL: $fullUrl');
    print('🖼️ [ImageHelper] ═══════════════════════════════════');
  }

  /// التحقق من صحة URL الصورة (اختياري)
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;

    // التحقق من أن URL يحتوي على امتداد صورة
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg'];
    final lowerUrl = url.toLowerCase();

    return imageExtensions.any((ext) => lowerUrl.contains(ext));
  }
}

