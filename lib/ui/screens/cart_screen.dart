import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../state/cart_provider.dart';
import '../../state/auth_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/common_app_bar.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with TickerProviderStateMixin {
  bool _loading = true;
  bool _hasError = false;
  String _errorMessage = '';
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _checkAuthAndLoadCart();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndLoadCart() async {
    if (!mounted) return;

    final auth = context.read<AuthProvider>();

    if (!auth.isAuthenticated) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('يجب تسجيل الدخول أولاً للوصول إلى السلة'),
                  ),
                ],
              ),
              backgroundColor: Colors.orange.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) context.go('/auth/customer/login');
          });
        });
      }
      return;
    }

    await _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });

    try {
      await context.read<CartProvider>().refresh();
      if (mounted) {
        setState(() => _loading = false);
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = cart.items.values.toList();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: CommonAppBar(
        title: 'سلة التسوق',
        leadingIcon: Icons.shopping_cart_rounded,
        showCartBadge: false,
        additionalActions: items.isNotEmpty
            ? [
                IconButton(
                  onPressed: () => _showClearCartDialog(cart),
                  icon: const Icon(Icons.delete_sweep_outlined),
                  tooltip: 'تنظيف السلة',
                ),
              ]
            : null,
      ),
      drawer: const AppDrawer(),
      body: _buildBody(cart, items, colorScheme, isDark),
    );
  }

  Widget _buildBody(
    CartProvider cart,
    List<CartItem> items,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    if (_loading) {
      return _buildLoadingState(colorScheme);
    }

    if (_hasError) {
      return _buildErrorState(colorScheme, isDark);
    }

    if (items.isEmpty) {
      return _buildEmptyState(colorScheme, isDark);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildCartContent(cart, items, colorScheme, isDark),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(colorScheme.primary),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'جارٍ تحميل سلة التسوق...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'حدث خطأ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage.isNotEmpty ? _errorMessage : 'تعذر تحميل سلة التسوق',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCart,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة متحركة
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shopping_cart_outlined,
                  size: 80,
                  color: colorScheme.primary.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'سلة التسوق فارغة',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'اكتشف منتجاتنا الرائعة وأضفها إلى سلتك',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.storefront_rounded),
              label: const Text('تصفح المنتجات'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent(
    CartProvider cart,
    List<CartItem> items,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final subtotal = cart.subtotal;
    final delivery = subtotal >= 10 ? 0.0 : 1.5;
    final vat = subtotal * 0.15;
    final total = subtotal + delivery + vat;

    return Column(
      children: [
        // عدد المنتجات
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
          child: Row(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${items.length} ${items.length == 1 ? 'منتج' : 'منتجات'} في السلة',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),

        // قائمة المنتجات
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) => _CartItemCard(
              item: items[i],
              cart: cart,
              colorScheme: colorScheme,
              isDark: isDark,
              onRemove: () => _removeItem(cart, items[i]),
            ),
          ),
        ),

        // ملخص الطلب
        _OrderSummary(
          subtotal: subtotal,
          delivery: delivery,
          vat: vat,
          total: total,
          colorScheme: colorScheme,
          isDark: isDark,
          onCheckout: () => context.push('/checkout'),
        ),
      ],
    );
  }

  void _showClearCartDialog(CartProvider cart) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_sweep, color: Colors.red.shade700),
            ),
            const SizedBox(width: 12),
            const Text('تنظيف السلة'),
          ],
        ),
        content: const Text('هل أنت متأكد من حذف جميع المنتجات من السلة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              cart.clear();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Text('تم تنظيف السلة'),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف الكل'),
          ),
        ],
      ),
    );
  }

  void _removeItem(CartProvider cart, CartItem item) {
    HapticFeedback.lightImpact();
    cart.remove(item.product.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حذف "${item.product.name}" من السلة'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'تراجع',
          onPressed: () => cart.add(item.product, qty: item.qty),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Cart Item Card - بطاقة المنتج في السلة
// ═══════════════════════════════════════════════════════════════════════════

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final CartProvider cart;
  final ColorScheme colorScheme;
  final bool isDark;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.cart,
    required this.colorScheme,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('cart_item_${item.product.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text(
              'حذف',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        return true;
      },
      onDismissed: (_) => onRemove(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة المنتج
              Hero(
                tag: 'product_${item.product.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.product.image,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: colorScheme.primary,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // تفاصيل المنتج
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اسم المنتج
                    Text(
                      item.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // سعر الوحدة
                    Text(
                      '${item.product.price.toStringAsFixed(2)} د.ع / وحدة',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // أزرار التحكم والسعر
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // أزرار الكمية
                        _QuantityControls(
                          quantity: item.qty,
                          onDecrease: () {
                            HapticFeedback.selectionClick();
                            if (item.qty > 1) {
                              cart.setQty(item.product.id, item.qty - 1);
                            } else {
                              onRemove();
                            }
                          },
                          onIncrease: () {
                            HapticFeedback.selectionClick();
                            cart.setQty(item.product.id, item.qty + 1);
                          },
                          colorScheme: colorScheme,
                          isDark: isDark,
                        ),

                        // السعر الإجمالي
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${(item.product.price * item.qty).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: colorScheme.primary,
                              ),
                            ),
                            Text(
                              'د.ع',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Quantity Controls - أزرار التحكم في الكمية
// ═══════════════════════════════════════════════════════════════════════════

class _QuantityControls extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final ColorScheme colorScheme;
  final bool isDark;

  const _QuantityControls({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuantityButton(
            icon: quantity > 1 ? Icons.remove_rounded : Icons.delete_outline_rounded,
            onTap: onDecrease,
            color: quantity > 1 ? colorScheme.primary : Colors.red,
            isDark: isDark,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 40),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
          ),
          _QuantityButton(
            icon: Icons.add_rounded,
            onTap: onIncrease,
            color: colorScheme.primary,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final bool isDark;

  const _QuantityButton({
    required this.icon,
    required this.onTap,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Order Summary - ملخص الطلب
// ═══════════════════════════════════════════════════════════════════════════

class _OrderSummary extends StatelessWidget {
  final double subtotal;
  final double delivery;
  final double vat;
  final double total;
  final ColorScheme colorScheme;
  final bool isDark;
  final VoidCallback onCheckout;

  const _OrderSummary({
    required this.subtotal,
    required this.delivery,
    required this.vat,
    required this.total,
    required this.colorScheme,
    required this.isDark,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // تفاصيل السعر
              _SummaryRow(
                label: 'المجموع الفرعي',
                value: '${subtotal.toStringAsFixed(2)} د.ع',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _SummaryRow(
                label: 'التوصيل',
                value: delivery == 0 ? 'مجاني' : '${delivery.toStringAsFixed(2)} د.ع',
                valueColor: delivery == 0 ? Colors.green : null,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _SummaryRow(
                label: 'ضريبة القيمة المضافة (15%)',
                value: '${vat.toStringAsFixed(2)} د.ع',
                isDark: isDark,
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Divider(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  thickness: 1.5,
                ),
              ),

              // الإجمالي
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الإجمالي',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey[800],
                    ),
                  ),
                  Text(
                    '${total.toStringAsFixed(2)} د.ع',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // زر إتمام الطلب
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: onCheckout,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_checkout_rounded, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'إتمام الطلب',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // رسالة التوصيل المجاني
              if (subtotal < 10)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 16,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'أضف ${(10 - subtotal).toStringAsFixed(2)} د.ع للتوصيل المجاني',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? (isDark ? Colors.white : Colors.grey[800]),
          ),
        ),
      ],
    );
  }
}
