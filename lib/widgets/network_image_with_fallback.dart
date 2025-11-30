import 'package:flutter/material.dart';
import '../helpers/image_helper.dart';

/// Network Image with Fallback
/// 
/// Widget لعرض صور من الشبكة مع معالجة آمنة للأخطاء
/// ويدعم placeholder و loading و error states
class NetworkImageWithFallback extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String placeholderType;
  final BorderRadius? borderRadius;
  final bool showDebug;

  const NetworkImageWithFallback({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholderType = 'product',
    this.borderRadius,
    this.showDebug = false,
  });

  @override
  Widget build(BuildContext context) {
    // Debug logging إذا كان مفعلاً
    if (showDebug) {
      ImageHelper.debugImage(imageUrl);
    }

    // الحصول على URL الكامل
    final fullUrl = ImageHelper.getFullImageUrl(imageUrl);

    // إذا كان URL فارغ، استخدم placeholder مباشرة
    if (fullUrl.isEmpty) {
      return _buildPlaceholder(context);
    }

    // بناء الصورة مع معالجة الأخطاء
    final imageWidget = Image.network(
      fullUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child; // تحميل مكتمل
        }

        // عرض progress indicator أثناء التحميل
        return _buildLoadingState(context, loadingProgress);
      },
      errorBuilder: (context, error, stackTrace) {
        // في حالة خطأ، عرض placeholder
        if (showDebug) {
          print('❌ [NetworkImage] فشل تحميل الصورة: $fullUrl');
          print('❌ [NetworkImage] الخطأ: $error');
        }
        return _buildPlaceholder(context);
      },
    );

    // إضافة border radius إذا كان محدداً
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  /// بناء حالة التحميل
  Widget _buildLoadingState(
    BuildContext context,
    ImageChunkEvent loadingProgress,
  ) {
    final progress = loadingProgress.expectedTotalBytes != null
        ? loadingProgress.cumulativeBytesLoaded /
            loadingProgress.expectedTotalBytes!
        : null;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  /// بناء placeholder عند الفشل
  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getPlaceholderIcon(),
              size: 40,
              color: Colors.grey[400],
            ),
            if (showDebug) ...[
              const SizedBox(height: 8),
              Text(
                'فشل التحميل',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// الحصول على أيقونة placeholder حسب النوع
  IconData _getPlaceholderIcon() {
    switch (placeholderType) {
      case 'product':
        return Icons.shopping_bag_outlined;
      case 'vendor':
        return Icons.store_outlined;
      case 'category':
        return Icons.category_outlined;
      case 'user':
        return Icons.person_outline;
      default:
        return Icons.image_outlined;
    }
  }
}

/// Product Image Widget
/// widget متخصص لصور المنتجات
class ProductImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final BorderRadius? borderRadius;

  const ProductImage({
    super.key,
    required this.imageUrl,
    this.size = 100,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return NetworkImageWithFallback(
      imageUrl: imageUrl,
      width: size,
      height: size,
      placeholderType: 'product',
      borderRadius: borderRadius ?? BorderRadius.circular(8),
    );
  }
}

/// Vendor Logo Widget
/// widget متخصص لشعارات المتاجر
class VendorLogo extends StatelessWidget {
  final String? logoUrl;
  final double size;

  const VendorLogo({
    super.key,
    required this.logoUrl,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return NetworkImageWithFallback(
      imageUrl: logoUrl,
      width: size,
      height: size,
      placeholderType: 'vendor',
      borderRadius: BorderRadius.circular(size / 2), // دائري
    );
  }
}

/// Category Image Widget
/// widget متخصص لصور الأقسام
class CategoryImage extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const CategoryImage({
    super.key,
    required this.imageUrl,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return NetworkImageWithFallback(
      imageUrl: imageUrl,
      width: size,
      height: size,
      placeholderType: 'category',
      borderRadius: BorderRadius.circular(8),
    );
  }
}


