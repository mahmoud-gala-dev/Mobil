import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Widget محسّن لعرض الصور مع تقليل الضغط على Main Thread
/// 
/// يحل مشاكل:
/// - Skipped frames بسبب تحميل الصور
/// - استهلاك الذاكرة الزائد
/// - تأخر في عرض الواجهة
class OptimizedImage extends StatelessWidget {
  final String? imageUrl;
  final String? assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final int? cacheWidth;
  final int? cacheHeight;
  final Color? color;
  final BlendMode? colorBlendMode;

  const OptimizedImage({
    super.key,
    this.imageUrl,
    this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.cacheWidth,
    this.cacheHeight,
    this.color,
    this.colorBlendMode,
  }) : assert(
          imageUrl != null || assetPath != null,
          'يجب تحديد imageUrl أو assetPath',
        );

  @override
  Widget build(BuildContext context) {
    // استخدام RepaintBoundary لتقليل إعادة الرسم
    return RepaintBoundary(
      child: _buildImageWidget(),
    );
  }

  Widget _buildImageWidget() {
    Widget imageWidget;

    if (assetPath != null) {
      // صورة من Assets
      imageWidget = Image.asset(
        assetPath!,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        color: color,
        colorBlendMode: colorBlendMode,
        errorBuilder: (context, error, stackTrace) {
          if (kDebugMode) {
            print('❌ [OptimizedImage] خطأ في تحميل صورة Asset: $error');
          }
          return _buildErrorWidget();
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) {
            return child;
          }
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: frame != null ? child : _buildPlaceholder(),
          );
        },
      );
    } else {
      // صورة من الشبكة
      imageWidget = Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        color: color,
        colorBlendMode: colorBlendMode,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return _buildLoadingWidget(loadingProgress);
        },
        errorBuilder: (context, error, stackTrace) {
          if (kDebugMode) {
            print('❌ [OptimizedImage] خطأ في تحميل صورة من الشبكة: $error');
          }
          return _buildErrorWidget();
        },
      );
    }

    // إضافة BorderRadius إذا كان محدداً
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildPlaceholder() {
    if (placeholder != null) {
      return placeholder!;
    }

    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(ImageChunkEvent loadingProgress) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
              : null,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (errorWidget != null) {
      return errorWidget!;
    }

    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Icon(
        Icons.broken_image,
        color: Colors.grey,
        size: 48,
      ),
    );
  }
}

/// مساعد لحساب أبعاد الصورة المثلى للتخزين المؤقت
class ImageCacheHelper {
  /// حساب عرض التخزين المؤقت بناءً على حجم الشاشة
  static int? calculateCacheWidth(BuildContext context, double? width) {
    if (width == null) return null;
    
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    return (width * devicePixelRatio).round();
  }

  /// حساب ارتفاع التخزين المؤقت بناءً على حجم الشاشة
  static int? calculateCacheHeight(BuildContext context, double? height) {
    if (height == null) return null;
    
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    return (height * devicePixelRatio).round();
  }

  /// تنظيف ذاكرة التخزين المؤقت للصور
  static void clearImageCache() {
    imageCache.clear();
    imageCache.clearLiveImages();
    if (kDebugMode) {
      print('🧹 [ImageCacheHelper] تم تنظيف ذاكرة التخزين المؤقت للصور');
    }
  }

  /// تكوين حجم ذاكرة التخزين المؤقت
  static void configureImageCache({
    int? maxSizeBytes,
    int? maxSize,
  }) {
    if (maxSizeBytes != null) {
      imageCache.maximumSizeBytes = maxSizeBytes;
    }
    if (maxSize != null) {
      imageCache.maximumSize = maxSize;
    }
    
    if (kDebugMode) {
      print('⚙️ [ImageCacheHelper] تم تكوين ذاكرة التخزين المؤقت:');
      print('   - الحد الأقصى للبايتات: ${imageCache.maximumSizeBytes}');
      print('   - الحد الأقصى للعدد: ${imageCache.maximumSize}');
    }
  }

  /// الحصول على معلومات ذاكرة التخزين المؤقت
  static Map<String, dynamic> getCacheInfo() {
    return {
      'currentSize': imageCache.currentSize,
      'currentSizeBytes': imageCache.currentSizeBytes,
      'liveImageCount': imageCache.liveImageCount,
      'pendingImageCount': imageCache.pendingImageCount,
      'maximumSize': imageCache.maximumSize,
      'maximumSizeBytes': imageCache.maximumSizeBytes,
    };
  }
}

/// Widget محسّن لعرض قائمة من الصور مع إدارة أفضل للذاكرة
class OptimizedImageList extends StatelessWidget {
  final List<String> imageUrls;
  final double itemHeight;
  final double itemWidth;
  final ScrollPhysics? physics;
  final EdgeInsets? padding;
  final int? crossAxisCount;

  const OptimizedImageList({
    super.key,
    required this.imageUrls,
    required this.itemHeight,
    required this.itemWidth,
    this.physics,
    this.padding,
    this.crossAxisCount,
  });

  @override
  Widget build(BuildContext context) {
    if (crossAxisCount != null) {
      // عرض شبكة
      return GridView.builder(
        physics: physics ?? const BouncingScrollPhysics(),
        padding: padding ?? const EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount!,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: itemWidth / itemHeight,
        ),
        cacheExtent: 500, // تحميل مسبق للعناصر القريبة
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return RepaintBoundary(
            child: OptimizedImage(
              imageUrl: imageUrls[index],
              width: itemWidth,
              height: itemHeight,
              cacheWidth: ImageCacheHelper.calculateCacheWidth(context, itemWidth),
              cacheHeight: ImageCacheHelper.calculateCacheHeight(context, itemHeight),
            ),
          );
        },
      );
    } else {
      // عرض قائمة عمودية
      return ListView.builder(
        physics: physics ?? const BouncingScrollPhysics(),
        padding: padding ?? const EdgeInsets.all(8),
        cacheExtent: 500, // تحميل مسبق للعناصر القريبة
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OptimizedImage(
                imageUrl: imageUrls[index],
                width: itemWidth,
                height: itemHeight,
                cacheWidth: ImageCacheHelper.calculateCacheWidth(context, itemWidth),
                cacheHeight: ImageCacheHelper.calculateCacheHeight(context, itemHeight),
              ),
            ),
          );
        },
      );
    }
  }
}

/// PreloadImageHelper - تحميل مسبق للصور في الخلفية
class PreloadImageHelper {
  /// تحميل مسبق لصورة واحدة
  static Future<void> preloadImage(BuildContext context, String imageUrl) async {
    try {
      await precacheImage(NetworkImage(imageUrl), context);
      if (kDebugMode) {
        print('✅ [PreloadImage] تم تحميل الصورة مسبقاً: $imageUrl');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [PreloadImage] فشل التحميل المسبق: $e');
      }
    }
  }

  /// تحميل مسبق لمجموعة من الصور
  static Future<void> preloadImages(
    BuildContext context,
    List<String> imageUrls, {
    int maxConcurrent = 3,
  }) async {
    if (kDebugMode) {
      print('🔄 [PreloadImage] بدء تحميل ${imageUrls.length} صورة...');
    }

    // تقسيم إلى مجموعات لتجنب التحميل المفرط
    for (var i = 0; i < imageUrls.length; i += maxConcurrent) {
      final batch = imageUrls.skip(i).take(maxConcurrent).toList();
      await Future.wait(
        batch.map((url) => preloadImage(context, url)),
      );
    }

    if (kDebugMode) {
      print('✅ [PreloadImage] اكتمل تحميل جميع الصور');
    }
  }
}
