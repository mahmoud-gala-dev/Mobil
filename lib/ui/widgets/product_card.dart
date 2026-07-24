import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../state/favorites_provider.dart';
import '../../state/app_settings_provider.dart';
import '../../helpers/cart_helper.dart';
import '../../services/sound_service.dart';
import '../../services/toast_service.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  const ProductCard({super.key, required this.product});

  Future<void> _addToCart(BuildContext context) async {
    // استخدام CartHelper للتحقق من تسجيل الدخول وإضافة المنتج
    await CartHelper.addToCart(context, product);
  }

  Future<void> _toggleFavorite(
      BuildContext context, FavoritesProvider favs) async {
    final isFav = favs.isFav(product.id);

    // تبديل حالة المفضلة
    favs.toggle(product.id);

    // تشغيل الصوت
    await SoundService().playAddToFavoriteSound();

    // عرض رسالة التوست
    if (!isFav) {
      ToastService().showAddToFavorite(product.name);
    } else {
      ToastService().showRemoveFromFavorite(product.name);
    }
  }

  /// بناء صورة المنتج مع دعم الصورة الافتراضية الديناميكية
  Widget _buildProductImage(BuildContext context, String defaultImageUrl) {
    final imageUrl = product.image;

    // إذا كانت صورة المنتج فارغة، استخدم الصورة الافتراضية
    final displayUrl = (imageUrl.isEmpty) ? defaultImageUrl : imageUrl;

    return Image.network(
      displayUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // عند فشل تحميل صورة المنتج، حاول تحميل الصورة الافتراضية
        if (displayUrl != defaultImageUrl && defaultImageUrl.isNotEmpty) {
          return Image.network(
            defaultImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, st) => _buildPlaceholderIcon(),
          );
        }
        return _buildPlaceholderIcon();
      },
    );
  }

  /// أيقونة placeholder عند فشل جميع الصور
  Widget _buildPlaceholderIcon() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.shopping_bag_outlined,
          size: 40,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favs = context.watch<FavoritesProvider>();
    final appSettings = context.watch<AppSettingsProvider>();
    final isFav = favs.isFav(product.id);

    // الحصول على صورة المنتج الافتراضية من الإعدادات
    final defaultImageUrl = appSettings.getDefaultProductImageUrl();

    return InkWell(
      onTap: () => context.push('/product/${product.id}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // قسم الصورة
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  SizedBox.expand(
                    child: _buildProductImage(context, defaultImageUrl),
                  ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Material(
                      color: Colors.white.withOpacity(0.9),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _toggleFavorite(context, favs),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.red : Colors.grey[600],
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (product.originalPrice != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red[600],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(((product.originalPrice! - product.price) / product.originalPrice!) * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // قسم المعلومات
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اسم المنتج
                    Expanded(
                      flex: 2,
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // السعر
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        Text(
                          '${product.price.toStringAsFixed(2)} د.ع',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 13,
                          ),
                        ),
                        if (product.originalPrice != null)
                          Text(
                            product.originalPrice!.toStringAsFixed(2),
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // زر الإضافة
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: ElevatedButton(
                        onPressed: () => _addToCart(context),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_shopping_cart, size: 14),
                            SizedBox(width: 4),
                            Text('إضافة', style: TextStyle(fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
