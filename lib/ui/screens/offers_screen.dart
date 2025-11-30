import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../state/cart_provider.dart';
import '../../models/models.dart';
import '../widgets/app_drawer.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/app_footer.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  List<Map<String, dynamic>> _offers = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  String _error = '';
  int? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final categories = await ApiService.I.offerCategories();
      final offers = await ApiService.I.featuredOffers();

      if (mounted) {
        setState(() {
          _categories = categories;
          _offers = offers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadOffersByCategory(int categoryId) async {
    setState(() {
      _isLoading = true;
      _error = '';
      _selectedCategory = categoryId;
    });

    try {
      final offers = await ApiService.I.offersByCategory(categoryId);
      if (mounted) {
        setState(() {
          _offers = offers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: const CommonAppBar(
        title: 'العروض الخاصة',
        leadingIcon: Icons.local_offer_rounded,
      ),
      drawer: const AppDrawer(),
      body: _isLoading && _offers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('خطأ: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Categories
                    if (_categories.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(12),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.filter_list, size: 20, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'تصفية حسب الفئة:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  // زر الكل
                                  Padding(
                                padding: const EdgeInsets.only(left: 8),
                                    child: FilterChip(
                                  label: const Text('الكل'),
                                  selected: _selectedCategory == null,
                                  onSelected: (selected) {
                                    if (selected) {
                                          setState(() => _selectedCategory = null);
                                      _loadData();
                                    }
                                  },
                                      backgroundColor: Colors.grey[100],
                                      selectedColor: colorScheme.primary,
                                      checkmarkColor: Colors.white,
                                      labelStyle: TextStyle(
                                        color: _selectedCategory == null ? Colors.white : Colors.black87,
                                        fontWeight: _selectedCategory == null ? FontWeight.bold : FontWeight.normal,
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                  // أزرار الفئات
                                  ..._categories.map((category) {
                                    final isSelected = _selectedCategory == category['id'];
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                                      child: FilterChip(
                                        label: Text(category['name_ar'] ?? category['name'] ?? 'فئة'),
                                        selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    _loadOffersByCategory(category['id']);
                                  }
                                },
                                        backgroundColor: Colors.grey[100],
                                        selectedColor: colorScheme.primary,
                                        checkmarkColor: Colors.white,
                                        labelStyle: TextStyle(
                                          color: isSelected ? Colors.white : Colors.black87,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Offers
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _offers.length,
                          itemBuilder: (ctx, i) {
                            final offer = _offers[i];
                            return _OfferCard(offer: offer);
                          },
                            ),
                            
                            // Footer
                            const SizedBox(height: 40),
                            const AppFooter(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final Map<String, dynamic> offer;

  const _OfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // معالجة آمنة للأرقام (قد تأتي كـ String أو num)
    double parseNumber(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }
    
    final discount = parseNumber(offer['discount_percentage']);
    final originalPrice = parseNumber(offer['original_price']);
    final discountedPrice = parseNumber(offer['discounted_price']);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shadowColor: Colors.black.withAlpha(51),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to offer details
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (offer['image'] != null)
                    Image.network(
                      offer['image'],
                      fit: BoxFit.cover,
                      loadingBuilder: (ctx, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (ctx, err, stack) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.primaryContainer,
                              colorScheme.primary.withAlpha(77),
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.local_offer_rounded,
                          size: 50,
                          color: colorScheme.primary,
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primaryContainer,
                            colorScheme.primary.withAlpha(77),
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.local_offer_rounded,
                        size: 50,
                        color: colorScheme.primary,
                      ),
                    ),
                  
                  // تدرج للقراءة
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withAlpha(77),
                        ],
                      ),
                    ),
                  ),
                  
                  // Discount badge
                  if (discount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red[600]!, Colors.red[400]!],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withAlpha(102),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.flash_on,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                          '-${discount.toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Info
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    // العنوان
                    Expanded(
                      child: Text(
                        offer['title'] ?? 'عرض مميز',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          height: 1.2,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // السعر
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${discountedPrice.toStringAsFixed(2)} ج.م',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                      if (originalPrice > discountedPrice)
                        Text(
                          '${originalPrice.toStringAsFixed(2)} ج.م',
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        // أزرار الإجراءات
                        Row(
                          children: [
                            // زر عرض التفاصيل
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withAlpha(51),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    // الانتقال لصفحة تفاصيل العرض
                                    if (offer['id'] != null) {
                                      context.push('/offer/${offer['id']}');
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.visibility,
                                      color: colorScheme.primary,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            // زر إضافة للسلة
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withAlpha(77),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () async {
                                    // إضافة للسلة فعلياً
                                    if (offer['id'] != null) {
                                      try {
                                        final cart = context.read<CartProvider>();
                                        
                                        // محاولة إضافة العرض مباشرة
                                        try {
                                          await ApiService.I.addOfferToCart(offer['id'] as int, quantity: 1);
                                          await cart.refresh();
                                        } catch (e) {
                                          // إذا فشل، حاول إضافة المنتج المرتبط
                                          if (offer['product_id'] != null) {
                                            final product = ProductModel(
                                              id: offer['product_id'] as int,
                                              name: offer['title'] ?? 'عرض',
                                              image: offer['image'] ?? '',
                                              price: (offer['discounted_price'] as num?)?.toDouble() ?? 0.0,
                                              originalPrice: (offer['original_price'] as num?)?.toDouble(),
                                              rating: 0.0,
                                              category: '',
                                              supplier: '',
                                            );
                                            
                                            await cart.add(product, qty: 1);
                                          } else {
                                            throw Exception('لا يمكن إضافة هذا العرض للسلة');
                                          }
                                        }
                                        
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(Icons.check_circle, color: Colors.white),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text('تم إضافة "${offer['title']}" للسلة'),
                                                  ),
                                                ],
                                              ),
                                              duration: const Duration(seconds: 2),
                                              behavior: SnackBarBehavior.floating,
                                              backgroundColor: Colors.green,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(Icons.error, color: Colors.white),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text('خطأ: ${e.toString()}'),
                                                  ),
                                                ],
                                              ),
                                              duration: const Duration(seconds: 3),
                                              behavior: SnackBarBehavior.floating,
                                              backgroundColor: Colors.red,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Row(
                                            children: [
                                              Icon(Icons.warning, color: Colors.white),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Text('هذا العرض غير متاح للشراء حالياً'),
                                              ),
                                            ],
                                          ),
                                          duration: const Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: Colors.orange,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.add_shopping_cart,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
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

