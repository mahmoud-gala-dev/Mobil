import 'package:flutter/material.dart';
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

class _CartScreenState extends State<CartScreen> {
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadCart();
  }
  
  Future<void> _checkAuthAndLoadCart() async {
    if (!mounted) return;
    
    // التحقق من تسجيل الدخول
    final auth = context.read<AuthProvider>();
    
    if (!auth.isAuthenticated) {
      print('⚠️ [CartScreen] المستخدم غير مسجل دخول، التحويل لصفحة تسجيل الدخول');
      
      // عرض رسالة توضيحية والتحويل بعد بناء الواجهة
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('يجب تسجيل الدخول أولاً للوصول إلى السلة'),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          // التحويل لصفحة تسجيل الدخول بعد عرض الرسالة
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              context.go('/auth/customer/login');
            }
          });
        });
      }
      return;
    }
    
    print('✅ [CartScreen] المستخدم مسجل دخول، جلب بيانات السلة');
    
    // تحميل السلة
    await context.read<CartProvider>().refresh();
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = cart.items.values.toList();
    final subtotal = cart.subtotal;
    final delivery = subtotal >= 10 ? 0 : 1.5;
    final vat = subtotal * 0.15;
    final total = subtotal + delivery + vat;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CommonAppBar(
        title: 'سلة التسوق',
        leadingIcon: Icons.shopping_cart_rounded,
        showCartBadge: false, // لا نحتاج عداد السلة في صفحة السلة
        additionalActions: items.isNotEmpty
            ? [
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('تنظيف السلة'),
                        content: const Text('هل أنت متأكد من حذف جميع المنتجات؟'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('إلغاء'),
                          ),
                          TextButton(
                            onPressed: () {
                              cart.clear();
                              Navigator.pop(ctx);
                            },
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('حذف الكل'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: const Text('تنظيف'),
                ),
              ]
            : null,
      ),
      drawer: const AppDrawer(),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 120,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'سلة التسوق فارغة',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'قم بإضافة منتجات لعرضها هنا',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/home'),
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: const Text('تصفح المنتجات'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // قائمة المنتجات
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final item = items[i];
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // صورة المنتج
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item.product.image,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image_not_supported),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  
                                  // تفاصيل المنتج
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${item.product.price.toStringAsFixed(2)} د.ع / وحدة',
                                          style: TextStyle(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        
                                        // عناصر التحكم
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // أزرار الكمية
                                            Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.grey[300]!),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    onPressed: () => cart.setQty(item.product.id, item.qty - 1),
                                                    icon: const Icon(Icons.remove, size: 18),
                                                    padding: const EdgeInsets.all(4),
                                                    constraints: const BoxConstraints(),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                                    child: Text(
                                                      '${item.qty}',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed: () => cart.setQty(item.product.id, item.qty + 1),
                                                    icon: const Icon(Icons.add, size: 18),
                                                    padding: const EdgeInsets.all(4),
                                                    constraints: const BoxConstraints(),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            
                                            // السعر الإجمالي
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '${(item.product.price * item.qty).toStringAsFixed(2)} د.ع',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: colorScheme.primary,
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () => cart.remove(item.product.id),
                                                  icon: const Icon(Icons.delete_outline, size: 20),
                                                  color: Colors.red[400],
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
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
                          );
                        },
                      ),
                    ),
                    
                    // ملخص الطلب
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(25),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // تفاصيل السعر
                              _PriceRow(label: 'المجموع الفرعي', value: '${subtotal.toStringAsFixed(2)} د.ع'),
                              const SizedBox(height: 8),
                              _PriceRow(
                                label: 'التوصيل',
                                value: delivery == 0 ? 'مجاني' : '${delivery.toStringAsFixed(2)} د.ع',
                                valueColor: delivery == 0 ? Colors.green[600] : null,
                              ),
                              const SizedBox(height: 8),
                              _PriceRow(label: 'ضريبة 15%', value: '${vat.toStringAsFixed(2)} د.ع'),
                              const Divider(height: 24, thickness: 1.5),
                              _PriceRow(
                                label: 'الإجمالي',
                                value: '${total.toStringAsFixed(2)} د.ع',
                                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                                valueStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // زر إتمام الطلب
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton.icon(
                                  onPressed: () => context.push('/checkout'),
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text(
                                    'إتمام الطلب',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final Color? valueColor;

  const _PriceRow({
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: labelStyle ?? const TextStyle(fontSize: 15),
        ),
        Text(
          value,
          style: valueStyle ??
              TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
        ),
      ],
    );
  }
}
