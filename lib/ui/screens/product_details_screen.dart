import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../state/cart_provider.dart';
import '../../state/favorites_provider.dart';
import '../../state/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/product_card.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';

class ProductDetailsScreen extends StatefulWidget {
  final int id;
  const ProductDetailsScreen({super.key, required this.id});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> with SingleTickerProviderStateMixin {
  ProductModel? product;
  List<ProductModel> relatedProducts = [];
  Map<String, dynamic>? reviewsData;
  bool loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    print('📦 [ProductDetails] جلب تفاصيل المنتج #${widget.id}...');
    setState(() => loading = true);
    try {
      final (prod, related) = await ApiService.I.productDetails(widget.id);
      print('✅ [ProductDetails] تم جلب المنتج: ${prod.name}');
      print('🔗 [ProductDetails] عدد المنتجات المشابهة: ${related.length}');
      
      // جلب التقييمات مع معالجة الأخطاء
      Map<String, dynamic>? reviews;
      try {
        print('⭐ [ProductDetails] جلب التقييمات...');
        reviews = await ApiService.I.getProductReviews(widget.id);
        print('✅ [ProductDetails] تم جلب ${reviews['total'] ?? 0} تقييم');
      } catch (e) {
        print('⚠️ [ProductDetails] خطأ في جلب التقييمات: $e');
        // تعيين قيمة افتراضية فارغة
        reviews = {'data': []};
      }
      
      setState(() {
        product = prod;
        relatedProducts = related;
        reviewsData = reviews;
        loading = false;
      });
      
      print('✅ [ProductDetails] تم تحميل جميع البيانات بنجاح');
    } catch (e) {
      print('❌ [ProductDetails] خطأ في تحميل المنتج: $e');
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل المنتج: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (product == null) {
      return Scaffold(
        appBar: const CommonAppBar(title: 'تفاصيل المنتج'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('المنتج غير موجود'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('العودة للرئيسية'),
              ),
            ],
          ),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final cart = context.watch<CartProvider>();
    final favs = context.watch<FavoritesProvider>();
    final isFav = favs.isFav(product!.id);

    return Scaffold(
      appBar: CommonAppBar(
        title: 'تفاصيل المنتج',
        additionalActions: [
          IconButton(
            onPressed: () => favs.toggle(product!.id),
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.red : null,
            ),
            tooltip: 'المفضلة',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // محتوى الصفحة
          Expanded(
            child: ListView(
              children: [
                // صورة المنتج
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    color: Colors.grey[100],
                    child: Image.network(
                      product!.image,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.image_not_supported,
                        size: 100,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),

                // معلومات المنتج
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // اسم المنتج
                      Text(
                        product!.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // التقييم
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (index) => Icon(
                              index < product!.rating.floor()
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber[700],
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${product!.rating.toStringAsFixed(1)} (${reviewsData?['total'] ?? 0} تقييم)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // السعر
                      Row(
                        children: [
                          Text(
                            '${product!.price.toStringAsFixed(2)} د.ع',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          if (product!.originalPrice != null) ...[
                            const SizedBox(width: 12),
                            Text(
                              '${product!.originalPrice!.toStringAsFixed(2)} د.ع',
                              style: TextStyle(
                                fontSize: 18,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[600],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'خصم ${(((product!.originalPrice! - product!.price) / product!.originalPrice!) * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // المورّد
                      if (product!.supplier.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.store_rounded,
                                size: 18,
                                color: colorScheme.primary,
                              ),
              const SizedBox(width: 8),
                              Text(
                                'المورّد: ${product!.supplier}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Tabs (الوصف، التقييمات، المنتجات المشابهة)
                TabBar(
                  controller: _tabController,
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: colorScheme.primary,
                  tabs: const [
                    Tab(text: 'الوصف'),
                    Tab(text: 'التقييمات'),
                    Tab(text: 'منتجات مشابهة'),
                  ],
                ),

                SizedBox(
                  height: 400,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // الوصف
                      _buildDescriptionTab(),
                      
                      // التقييمات
                      _buildReviewsTab(),
                      
                      // منتجات مشابهة
                      _buildRelatedProductsTab(),
                    ],
                  ),
                ),
                
                // Footer
                const SizedBox(height: 40),
                const AppFooter(),
              ],
            ),
          ),

          // زر الإضافة للسلة
          Container(
            padding: const EdgeInsets.all(16),
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
              child: Row(
                children: [
                  // زر المفضلة
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () => favs.toggle(product!.id),
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // زر الإضافة للسلة
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        cart.add(product!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم إضافة المنتج للسلة'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text(
                        'إضافة للسلة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'وصف المنتج',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'معلومات تفصيلية عن ${product!.name}',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'المميزات',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildFeatureItem('جودة عالية'),
          _buildFeatureItem('توصيل سريع'),
          _buildFeatureItem('ضمان الجودة'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    // معالجة مرنة لهيكل التقييمات من الـ API
    List<Map<String, dynamic>> reviews = [];
    
    if (reviewsData != null) {
      // محاولة 1: data هي List مباشرة
      if (reviewsData!['data'] is List) {
        reviews = (reviewsData!['data'] as List).cast<Map<String, dynamic>>();
      }
      // محاولة 2: reviews هي List
      else if (reviewsData!['reviews'] is List) {
        reviews = (reviewsData!['reviews'] as List).cast<Map<String, dynamic>>();
      }
      // محاولة 3: data.data هي List (pagination)
      else if (reviewsData!['data'] is Map && reviewsData!['data']['data'] is List) {
        reviews = (reviewsData!['data']['data'] as List).cast<Map<String, dynamic>>();
      }
    }
    
    if (reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'لا توجد تقييمات بعد',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final auth = context.read<AuthProvider>();
                if (!auth.isAuthenticated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('يجب تسجيل الدخول أولاً لإضافة تقييم'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                  context.push('/auth/customer/login');
                } else {
                  _showAddReviewDialog();
                }
              },
              child: const Text('كن أول من يقيّم'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length + 1,
      separatorBuilder: (_, __) => const Divider(height: 24),
      itemBuilder: (_, index) {
        if (index == 0) {
          return ElevatedButton.icon(
            onPressed: () {
              final auth = context.read<AuthProvider>();
              if (!auth.isAuthenticated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('يجب تسجيل الدخول أولاً لإضافة تقييم'),
                    duration: Duration(seconds: 3),
                  ),
                );
                context.push('/auth/customer/login');
              } else {
                _showAddReviewDialog();
              }
            },
            icon: const Icon(Icons.add_comment),
            label: const Text('إضافة تقييم'),
          );
        }
        
        final review = reviews[index - 1];
        final rating = (review['rating'] as num?)?.toInt() ?? 0;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    (review['user']?['name'] as String?)?.substring(0, 1) ?? 'ع',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['user']?['name'] ?? 'عميل',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < rating ? Icons.star : Icons.star_border,
                            size: 16,
                            color: Colors.amber[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (review['comment'] != null) ...[
              const SizedBox(height: 8),
              Text(
                review['comment'],
                style: TextStyle(color: Colors.grey[800]),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRelatedProductsTab() {
    if (relatedProducts.isEmpty) {
      return Center(
        child: Text(
          'لا توجد منتجات مشابهة',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: relatedProducts.length,
      itemBuilder: (_, i) => ProductCard(product: relatedProducts[i]),
    );
  }

  void _showAddReviewDialog() {
    print('📝 [ProductDetails] فتح نموذج إضافة تقييم...');
    
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة تقييم'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('التقييم:'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    onPressed: () {
                      setState(() => rating = index + 1);
                      print('⭐ [ProductDetails] تحديد التقييم: $rating نجوم');
                    },
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber[700],
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: 'التعليق (اختياري)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              print('🚫 [ProductDetails] إلغاء إضافة التقييم');
              Navigator.pop(ctx);
            },
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              print('📤 [ProductDetails] إرسال التقييم...');
              print('   المنتج: ${product!.id}');
              print('   التقييم: $rating نجوم');
              print('   التعليق: ${commentController.text.isNotEmpty ? commentController.text : "(بدون تعليق)"}');
              
              // التحقق من تسجيل الدخول
              final auth = context.read<AuthProvider>();
              print('🔐 [ProductDetails] حالة تسجيل الدخول: ${auth.isAuthenticated}');
              if (auth.token != null) {
                print('🔑 [ProductDetails] Token موجود: ${auth.token!.substring(0, 20)}...');
              }
              
              try {
                print('🚀 [ProductDetails] إرسال الطلب إلى: /reviews/products');
                
                await ApiService.I.storeProductReview(
                  productId: product!.id,
                  rating: rating,
                  comment: commentController.text.isNotEmpty 
                      ? commentController.text 
                      : null,
                );
                
                print('✅ [ProductDetails] تم إضافة التقييم بنجاح');
                
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text('تم إضافة التقييم بنجاح'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _load(); // إعادة تحميل البيانات
                }
              } catch (e, stackTrace) {
                print('❌ [ProductDetails] فشل إضافة التقييم: $e');
                print('📍 [ProductDetails] Stack Trace: $stackTrace');
                print('🔍 [ProductDetails] نوع الخطأ: ${e.runtimeType}');
                
                String errorMessage = 'خطأ: $e';
                if (e.toString().contains('404') || e.toString().contains('Not Found')) {
                  errorMessage = 'خطأ: الروت /reviews/products غير موجود في API';
                  print('⚠️ [ProductDetails] يرجى التحقق من routes/api.php');
                } else if (e.toString().contains('401') || e.toString().contains('Unauthenticated')) {
                  errorMessage = 'خطأ: يجب تسجيل الدخول أولاً';
                  print('⚠️ [ProductDetails] المستخدم غير مسجل دخول');
                }
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(child: Text(errorMessage)),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }
}
