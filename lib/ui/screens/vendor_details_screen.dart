import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../state/auth_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/app_drawer.dart';
import '../../models/models.dart';

class VendorDetailsScreen extends StatefulWidget {
  final int vendorId;

  const VendorDetailsScreen({super.key, required this.vendorId});

  @override
  State<VendorDetailsScreen> createState() => _VendorDetailsScreenState();
}

class _VendorDetailsScreenState extends State<VendorDetailsScreen> 
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _vendor;
  List<ProductModel> _products = [];
  List<Map<String, dynamic>> _reviews = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String _error = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadVendorDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadVendorDetails() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = '';
      });
    }

    try {
      print('🏪 [VendorDetails] ═══════════════════════════════════');
      print('🏪 [VendorDetails] جلب تفاصيل المتجر #${widget.vendorId}');
      
      // جلب البيانات بشكل متوازي
      final results = await Future.wait([
        ApiService.I.vendorDetails(widget.vendorId),
        ApiService.I.vendorProducts(widget.vendorId),
        ApiService.I.getVendorReviews(widget.vendorId).catchError((e) {
          print('⚠️ [VendorDetails] خطأ في جلب التقييمات: $e');
          return {'data': <Map<String, dynamic>>[]};
        }),
      ]);
      
      final vendorData = results[0] as Map<String, dynamic>;
      final products = results[1] as List<ProductModel>;
      final reviewsData = results[2] as Map<String, dynamic>;
      
      print('📊 [VendorDetails] البيانات المستلمة:');
      print('   - اسم المتجر: ${vendorData['name_ar'] ?? vendorData['name']}');
      print('   - عدد المنتجات: ${products.length}');
      print('   - عدد التقييمات: ${(reviewsData['data'] as List?)?.length ?? 0}');
      
      // معالجة آمنة للتقييمات
      List<Map<String, dynamic>> reviewsList = [];
      if (reviewsData['data'] != null) {
        if (reviewsData['data'] is List) {
          reviewsList = (reviewsData['data'] as List)
              .where((e) => e != null)
              .map((e) => e as Map<String, dynamic>)
              .toList();
        } else if (reviewsData['data'] is Map) {
          // في حالة كانت البيانات Map واحد، نضيفه كعنصر في القائمة
          reviewsList = [reviewsData['data'] as Map<String, dynamic>];
        }
      }
      
      // حساب الإحصائيات
      final stats = {
        'total_products': products.length,
        'total_reviews': vendorData['reviews_count'] ?? reviewsList.length,
        'average_rating': _parseNumber(vendorData['rating']),
        'total_orders': vendorData['orders_count'] ?? 0,
      };
      
      if (mounted) {
        setState(() {
          _vendor = vendorData;
          _products = products;
          _reviews = reviewsList;
          _stats = stats;
          _isLoading = false;
        });
      }
      
      print('✅ [VendorDetails] تم تحميل جميع البيانات بنجاح');
      print('🏪 [VendorDetails] ═══════════════════════════════════');
    } catch (e, stackTrace) {
      print('❌ [VendorDetails] ═══════════════════════════════════');
      print('❌ [VendorDetails] خطأ في تحميل المتجر #${widget.vendorId}');
      print('❌ [VendorDetails] الخطأ: $e');
      print('❌ [VendorDetails] Stack trace: $stackTrace');
      print('❌ [VendorDetails] ═══════════════════════════════════');
      
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  double _parseNumber(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    
    // التحقق من كون المستخدم تاجر (بائع)
    // ملاحظة: يمكن تحسين هذا عند إضافة vendor_id للـ UserModel
    final isVendorOwner = auth.isAuthenticated && auth.isVendor;
    
    return Scaffold(
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? _buildErrorWidget()
              : CustomScrollView(
                  slivers: [
                    _buildAppBar(colorScheme, isVendorOwner),
                    _buildVendorInfo(colorScheme),
                    _buildTabBar(),
                    _buildTabContent(),
                  ],
                ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text('خطأ: $_error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadVendorDetails,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme, bool isVendorOwner) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: colorScheme.primary,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: 'القائمة',
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () => context.push('/search'),
          tooltip: 'البحث',
        ),
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
          onPressed: () => context.push('/cart'),
          tooltip: 'السلة',
        ),
        if (isVendorOwner)
          IconButton(
            icon: const Icon(Icons.dashboard, color: Colors.white),
            onPressed: () => context.push('/vendor/dashboard'),
            tooltip: 'لوحة التحكم',
          ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            _buildVendorHeader(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorHeader(ColorScheme colorScheme) {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Column(
        children: [
          // Logo
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: _vendor?['logo'] != null
                  ? Image.network(
                      _vendor!['logo'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.white,
                        child: Icon(
                          Icons.store_rounded,
                          size: 50,
                          color: colorScheme.primary,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.white,
                      child: Icon(
                        Icons.store_rounded,
                        size: 50,
                        color: colorScheme.primary,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Store Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _vendor?['name_ar'] ?? _vendor?['name'] ?? _vendor?['store_name'] ?? 'متجر',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          
          // Rating
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.amber[300], size: 20),
                const SizedBox(width: 6),
                Text(
                  _stats['average_rating']?.toStringAsFixed(1) ?? '0.0',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${_stats['total_reviews']} تقييم)',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorInfo(ColorScheme colorScheme) {
    if (_vendor?['description'] == null && 
        _vendor?['city']?['name_ar'] == null && 
        _vendor?['phone'] == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_vendor?['description'] != null) ...[
              Row(
                children: [
                  Icon(Icons.info_outline, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'نبذة عن المتجر',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _vendor!['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 16),
            ],
            
            if (_vendor?['city']?['name_ar'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 20, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_vendor?['city']?['name_ar']}, ${_vendor?['governorate']?['name_ar'] ?? ''}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            
            if (_vendor?['phone'] != null)
              Row(
                children: [
                  Icon(Icons.phone, size: 20, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    _vendor!['phone'],
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          tabs: [
            Tab(
              icon: const Icon(Icons.shopping_bag_outlined, size: 20),
              text: 'المنتجات (${_products.length})',
            ),
            Tab(
              icon: const Icon(Icons.rate_review_outlined, size: 20),
              text: 'التقييمات (${_reviews.length})',
            ),
            const Tab(
              icon: Icon(Icons.bar_chart, size: 20),
              text: 'الإحصائيات',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsTab(),
          _buildReviewsTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    if (_products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 100, color: Colors.grey[300]),
              const SizedBox(height: 24),
              Text(
                'لا توجد منتجات متاحة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'هذا المتجر لم يضف أي منتجات بعد',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadVendorDetails,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _products.length,
      itemBuilder: (_, i) => ProductCard(product: _products[i]),
    );
  }

  Widget _buildReviewsTab() {
    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'لا توجد تقييمات',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _reviews.length,
      separatorBuilder: (_, __) => const Divider(height: 24),
      itemBuilder: (_, i) {
        final review = _reviews[i];
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

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatCard(
            icon: Icons.inventory_2,
            title: 'إجمالي المنتجات',
            value: '${_stats['total_products']}',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            icon: Icons.rate_review,
            title: 'إجمالي التقييمات',
            value: '${_stats['total_reviews']}',
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            icon: Icons.star,
            title: 'متوسط التقييم',
            value: (_stats['average_rating'] as double?)?.toStringAsFixed(1) ?? '0.0',
            color: Colors.amber,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            icon: Icons.shopping_bag,
            title: 'الطلبات',
            value: '${_stats['total_orders']}',
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}