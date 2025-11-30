import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/products_provider.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../widgets/product_card.dart';
import '../widgets/app_drawer.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/app_footer.dart';

class CategoryScreen extends StatefulWidget {
  final String slug;
  const CategoryScreen({super.key, required this.slug});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  bool loading = true;
  String _sortBy = 'default';
  List<ProductModel> _categoryProducts = [];
  int _productCount = 0;

  @override
  void initState() {
    super.initState();
    print('📂 [CategoryScreen] تحميل منتجات القسم: ${widget.slug}');
    _loadCategoryProducts();
  }

  String? _errorMessage;

  Future<void> _loadCategoryProducts() async {
    setState(() {
      loading = true;
      _errorMessage = null;
    });
    
    try {
      print('📂 [CategoryScreen] ═══════════════════════════════════');
      print('📂 [CategoryScreen] جلب منتجات القسم');
      print('📂 [CategoryScreen] Slug: ${widget.slug}');
      print('📂 [CategoryScreen] API Endpoint: /categories/${widget.slug}/products');
      print('📂 [CategoryScreen] ═══════════════════════════════════');
      
      // جلب المنتجات من API مباشرة
      final products = await ApiService.I.categoryProducts(widget.slug);
      
      print('✅ [CategoryScreen] تم جلب ${products.length} منتج بنجاح');
      
      if (products.isEmpty) {
        print('⚠️ [CategoryScreen] القائمة فارغة - لا توجد منتجات في هذا القسم');
      } else {
        print('📦 [CategoryScreen] أول منتج: ${products[0].name}');
      }
      
      if (mounted) {
        setState(() {
          _categoryProducts = products;
          _productCount = products.length;
          loading = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ [CategoryScreen] ═══════════════════════════════════');
      print('❌ [CategoryScreen] خطأ في تحميل منتجات القسم');
      print('❌ [CategoryScreen] الخطأ: $e');
      print('❌ [CategoryScreen] Stack trace: $stackTrace');
      print('❌ [CategoryScreen] ═══════════════════════════════════');
      
      if (mounted) {
        setState(() {
          _categoryProducts = [];
          _productCount = 0;
          loading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  List<ProductModel> _getSortedProducts() {
    final sortedProducts = List<ProductModel>.from(_categoryProducts);
    
    print('🔄 [CategoryScreen] ترتيب ${sortedProducts.length} منتج حسب: $_sortBy');
    
    switch (_sortBy) {
      case 'price_low':
        sortedProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        sortedProducts.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        sortedProducts.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'name':
        sortedProducts.sort((a, b) => a.name.compareTo(b.name));
        break;
      default:
        // الترتيب الافتراضي (كما جاء من API)
        break;
    }
    
    return sortedProducts;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProductsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    
    // البحث عن القسم من الأقسام المحملة بناءً على الـ slug
    CategoryModel? category;
    try {
      // محاولة إيجاد القسم بناءً على id أو name
      category = p.categories.firstWhere(
        (c) => c.id == widget.slug || c.name.toLowerCase() == widget.slug.toLowerCase(),
        orElse: () {
          // إنشاء category افتراضي إذا لم يتم إيجاده
          print('⚠️ [CategoryScreen] لم يتم العثور على القسم: ${widget.slug}');
          return CategoryModel(id: widget.slug, dbId: 0, name: _formatCategoryName(widget.slug), image: '');
        },
      );
    } catch (e) {
      print('⚠️ [CategoryScreen] خطأ في البحث عن القسم: $e');
      category = CategoryModel(id: widget.slug, dbId: 0, name: _formatCategoryName(widget.slug), image: '');
    }

    // الحصول على المنتجات المرتبة
    final sortedProducts = _getSortedProducts();

    return Scaffold(
      appBar: CommonAppBar(
        title: category.name,
        leadingIcon: Icons.category_rounded,
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Header مع الصورة والمعلومات
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              image: category.image.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(category.image),
                      fit: BoxFit.cover,
                    )
                  : null,
              gradient: category.image.isEmpty
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withOpacity(0.7),
                      ],
                    )
                  : null,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.inventory_2,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              loading ? 'جارِ التحميل...' : '$_productCount منتج',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // شريط الفرز والفلترة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.sort, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'ترتيب حسب:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildSortChip('الافتراضي', 'default'),
                        const SizedBox(width: 8),
                        _buildSortChip('السعر (الأقل)', 'price_low'),
                        const SizedBox(width: 8),
                        _buildSortChip('السعر (الأعلى)', 'price_high'),
                        const SizedBox(width: 8),
                        _buildSortChip('التقييم', 'rating'),
                        const SizedBox(width: 8),
                        _buildSortChip('الاسم', 'name'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // قائمة المنتجات
          Expanded(
            child: loading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('جارِ تحميل المنتجات...'),
                      ],
                    ),
                  )
                : sortedProducts.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _errorMessage != null 
                                    ? Icons.error_outline 
                                    : Icons.inventory_2_outlined,
                                size: 100,
                                color: _errorMessage != null 
                                    ? Colors.red[300]
                                    : Colors.grey[300],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _errorMessage != null 
                                    ? 'حدث خطأ في تحميل المنتجات'
                                    : 'لا توجد منتجات في هذا القسم',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              if (_errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red[200]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.info_outline, size: 16, color: Colors.red[700]),
                                          const SizedBox(width: 8),
                                          Text(
                                            'تفاصيل الخطأ:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red[900],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'القسم: ${widget.slug}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red[900],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ] else ...[
                                Text(
                                  'القسم: ${widget.slug}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'تحقق من الأقسام الأخرى أو جرب لاحقاً',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                              ElevatedButton.icon(
                                onPressed: _loadCategoryProducts,
                                icon: const Icon(Icons.refresh),
                                label: const Text('إعادة المحاولة'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              if (_errorMessage == null) ...[
                                const SizedBox(height: 16),
                                TextButton.icon(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.arrow_back),
                                  label: const Text('العودة للأقسام'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadCategoryProducts,
                        child: CustomScrollView(
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.all(16),
                              sliver: SliverGrid(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.68,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (_, i) => ProductCard(product: sortedProducts[i]),
                                  childCount: sortedProducts.length,
                                ),
                              ),
                            ),
                            
                            // Footer
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.only(top: 40),
                                child: AppFooter(),
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

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    
    return InkWell(
      onTap: () {
        setState(() => _sortBy = value);
        print('✅ [CategoryScreen] تم تغيير الترتيب إلى: $label');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
            ),
    );
  }
  
  // دالة لتنسيق اسم القسم من slug
  String _formatCategoryName(String slug) {
    return slug.replaceAll('-', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}
