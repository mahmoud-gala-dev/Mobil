import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';
import '../widgets/common_app_bar.dart';

class VendorsScreen extends StatefulWidget {
  const VendorsScreen({super.key});

  @override
  State<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends State<VendorsScreen> {
  List<Map<String, dynamic>> _vendors = [];
  final Map<int, int> _vendorProductCounts = {};
  bool _isLoading = true;
  bool _isLoadingCounts = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    print('🏪 [VendorsScreen] جلب قائمة المتاجر...');
    
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final vendors = await ApiService.I.vendors();
      print('✅ [VendorsScreen] تم جلب ${vendors.length} متجر');
      
      if (vendors.isNotEmpty) {
        final firstVendor = vendors[0];
        print('📋 [VendorsScreen] مفاتيح البيانات: ${firstVendor.keys.toList()}');
        print('🏪 [VendorsScreen] اسم المتجر الأول: ${_getVendorName(firstVendor)}');
        
        // استخراج عدد المنتجات من الـ API response مباشرة
        if (firstVendor['products_count'] != null) {
          print('📊 [VendorsScreen] عدد المنتجات من API: ${firstVendor['products_count']}');
        }
      }
      
      // استخراج عدد المنتجات من response مباشرة
      for (var vendor in vendors) {
        final vendorId = _getVendorId(vendor);
        if (vendorId != null && vendor['products_count'] != null) {
          int productCount = 0;
          if (vendor['products_count'] is int) {
            productCount = vendor['products_count'] as int;
          } else if (vendor['products_count'] is num) {
            productCount = (vendor['products_count'] as num).toInt();
          } else if (vendor['products_count'] is String) {
            productCount = int.tryParse(vendor['products_count']) ?? 0;
          }
          _vendorProductCounts[vendorId] = productCount;
        }
      }
      
      setState(() {
        _vendors = vendors;
        _isLoading = false;
        _isLoadingCounts = false; // عدد المنتجات أصبح متاحاً مباشرة
      });
      
      print('✅ [VendorsScreen] تم تحميل أعداد المنتجات من API مباشرة');
    } catch (e) {
      print('❌ [VendorsScreen] خطأ في جلب المتاجر: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  String _getVendorName(Map<String, dynamic> vendor) {
    // محاولة الحصول على الاسم من عدة مفاتيح محتملة
    // API يرجع name_ar و name
    return vendor['name_ar'] as String? ?? 
           vendor['name'] as String? ?? 
           vendor['store_name'] as String? ?? 
           vendor['business_name'] as String? ?? 
           'متجر';
  }
  
  int? _getVendorId(Map<String, dynamic> vendor) {
    if (vendor['id'] == null) return null;
    
    if (vendor['id'] is int) {
      return vendor['id'] as int;
    } else if (vendor['id'] is num) {
      return (vendor['id'] as num).toInt();
    } else if (vendor['id'] is String) {
      return int.tryParse(vendor['id']);
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: const CommonAppBar(
        title: 'المتاجر',
        leadingIcon: Icons.store_rounded,
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'حدث خطأ',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadVendors,
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
                )
              : _vendors.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.store_outlined,
                            size: 120,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'لا توجد متاجر متاحة',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'لم نتمكن من العثور على أي متاجر حالياً',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadVendors,
                      child: CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.all(16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) {
                          final vendor = _vendors[i];
                          final vendorName = _getVendorName(vendor);
                          
                          print('🏬 [VendorsScreen] المتجر #$i: $vendorName');
                          
                          // معالجة آمنة لـ rating (قد يكون String أو num)
                          double rating = 0.0;
                          if (vendor['rating'] != null) {
                            if (vendor['rating'] is num) {
                              rating = (vendor['rating'] as num).toDouble();
                            } else if (vendor['rating'] is String) {
                              rating = double.tryParse(vendor['rating']) ?? 0.0;
                            }
                            print('⭐ [VendorsScreen] التقييم: $rating (نوع: ${vendor['rating'].runtimeType})');
                          }
                          
                          // معالجة آمنة لـ reviews_count (قد يكون String أو num)
                          int reviewsCount = 0;
                          if (vendor['reviews_count'] != null) {
                            if (vendor['reviews_count'] is num) {
                              reviewsCount = (vendor['reviews_count'] as num).toInt();
                            } else if (vendor['reviews_count'] is String) {
                              reviewsCount = int.tryParse(vendor['reviews_count']) ?? 0;
                            }
                            print('📊 [VendorsScreen] عدد التقييمات: $reviewsCount (نوع: ${vendor['reviews_count'].runtimeType})');
                          }
                          
                          final vendorId = _getVendorId(vendor) ?? 0;
                          final productCount = _vendorProductCounts[vendorId] ?? 0;
                          
                          return Card(
                            elevation: 2,
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                print('👆 [VendorsScreen] النقر على المتجر: $vendorName (ID: $vendorId)');
                                
                                context.push('/vendor/$vendorId');
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Logo مع Badge لعدد المنتجات
                                        Stack(
                                          children: [
                                    Container(
                                              width: 80,
                                              height: 80,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer,
                                                borderRadius: BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.1),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                      ),
                                      child: vendor['logo'] != null
                                          ? ClipRRect(
                                                      borderRadius: BorderRadius.circular(16),
                                              child: Image.network(
                                                vendor['logo'],
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Icon(
                                                  Icons.store_rounded,
                                                          size: 40,
                                                  color: colorScheme.primary,
                                                ),
                                              ),
                                            )
                                          : Icon(
                                              Icons.store_rounded,
                                                      size: 40,
                                              color: colorScheme.primary,
                                            ),
                                    ),
                                            // Badge عدد المنتجات
                                            if (!_isLoadingCounts)
                                              Positioned(
                                                top: -6,
                                                right: -6,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme.primary,
                                                    borderRadius: BorderRadius.circular(12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withValues(alpha: 0.2),
                                                        blurRadius: 6,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.inventory_2,
                                                        color: Colors.white,
                                                        size: 12,
                                                      ),
                                                      const SizedBox(width: 3),
                                                      Text(
                                                        '$productCount',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: 16),
                                    
                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            vendorName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                              const SizedBox(height: 6),
                                          if (vendor['description'] != null)
                                            Text(
                                              vendor['description'],
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                                    height: 1.3,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Arrow Icon
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 18,
                                          color: Colors.grey[400],
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 12),
                                    
                                    // إحصائيات سفلية
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          // التقييم
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.star_rounded,
                                                color: Colors.amber[700],
                                                size: 18,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                rating.toStringAsFixed(1),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '($reviewsCount)',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                          
                                          // Divider
                                          Container(
                                            width: 1,
                                            height: 20,
                                            color: Colors.grey[300],
                                          ),
                                          
                                          // عدد المنتجات
                                          if (!_isLoadingCounts)
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                    Icon(
                                                  Icons.shopping_bag_outlined,
                                                  color: colorScheme.primary,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '$productCount منتج',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: colorScheme.primary,
                                                  ),
                                                ),
                                              ],
                                            )
                                          else
                                            SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: colorScheme.primary,
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
                                },
                                childCount: _vendors.length,
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: AppFooter(),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
