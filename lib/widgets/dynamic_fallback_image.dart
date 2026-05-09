import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_settings_provider.dart';
import '../helpers/image_helper.dart';

/// DynamicFallbackImage
///
/// Widget لعرض الصور مع دعم الصورة الافتراضية الديناميكية
/// من لوحة التحكم (Admin Panel)
class DynamicFallbackImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool useAppLogo;

  const DynamicFallbackImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.useAppLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettingsProvider>();

    // الحصول على URL الكامل للصورة
    final fullUrl = ImageHelper.getFullImageUrl(imageUrl);

    // URL الصورة الافتراضية من الإعدادات
    final fallbackUrl = useAppLogo
        ? appSettings.getDefaultProductImageUrl()
        : null;

    // إذا كان URL الأصلي فارغ، استخدم الصورة الافتراضية
    if (fullUrl.isEmpty) {
      return _buildFallbackImage(context, fallbackUrl);
    }

    // بناء الصورة مع معالجة الأخطاء
    Widget imageWidget = Image.network(
      fullUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoadingState(context, loadingProgress);
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildFallbackImage(context, fallbackUrl);
      },
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  /// بناء حالة التحميل
  Widget _buildLoadingState(BuildContext context, ImageChunkEvent progress) {
    final progressValue = progress.expectedTotalBytes != null
        ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
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
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            value: progressValue,
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  /// بناء الصورة الافتراضية
  Widget _buildFallbackImage(BuildContext context, String? fallbackUrl) {
    // إذا كان هناك URL للصورة الافتراضية، حاول تحميلها
    if (fallbackUrl != null && fallbackUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.network(
          fallbackUrl,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            // إذا فشل تحميل الصورة الافتراضية أيضاً
            return _buildPlaceholderIcon(context);
          },
        ),
      );
    }

    return _buildPlaceholderIcon(context);
  }

  /// بناء أيقونة placeholder
  Widget _buildPlaceholderIcon(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          Icons.shopping_bag_outlined,
          size: (width ?? 100) * 0.4,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}

/// ProductImageWithFallback
///
/// Widget متخصص لصور المنتجات مع الصورة الافتراضية
class ProductImageWithFallback extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ProductImageWithFallback({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return DynamicFallbackImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      useAppLogo: true,
    );
  }
}
