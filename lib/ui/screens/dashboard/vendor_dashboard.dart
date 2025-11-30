import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../state/auth_provider.dart';
import '../../../services/api_service.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/app_drawer.dart';

class VendorDashboard extends StatefulWidget {
  const VendorDashboard({super.key});

  @override
  State<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends State<VendorDashboard> {
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _recentOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    try {
      print('📊 [VendorDashboard] جلب بيانات الداشبورد...');
      final response = await ApiService.I.vendorDashboardStats();
      print('✅ [VendorDashboard] تم جلب الإحصائيات: $response');
      
      // استخراج البيانات من response بشكل آمن
      final stats = response['data'] as Map<String, dynamic>? ?? response;
      
      // جلب الطلبات بشكل آمن
      List<Map<String, dynamic>> orders = [];
      try {
        final ordersResponse = await ApiService.I.vendorRecentOrders();
        orders = ordersResponse;
        print('✅ [VendorDashboard] تم جلب الطلبات: ${orders.length} طلب');
      } catch (ordersError) {
        print('⚠️ [VendorDashboard] تحذير: فشل جلب الطلبات: $ordersError');
        // نستمر مع قائمة فارغة بدلاً من إيقاف كل شيء
        orders = [];
      }
      
      if (!mounted) return;
      
      setState(() {
        _stats = stats;
        _recentOrders = orders;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('❌ [VendorDashboard] خطأ في تحميل البيانات: $e');
      print('Stack trace: $stackTrace');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        // تعيين قيم افتراضية لتجنب أخطاء null
        _stats = null;
        _recentOrders = [];
      });
      
      if (mounted) {
        // معالجة أنواع مختلفة من الأخطاء
        String errorMessage = 'خطأ في تحميل البيانات';
        bool shouldRedirect = false;
        
        if (e.toString().contains('401') || 
            e.toString().contains('Unauthenticated') ||
            e.toString().contains('Invalid authentication token')) {
          errorMessage = 'انتهت صلاحية جلستك. يرجى تسجيل الدخول مرة أخرى';
          shouldRedirect = true;
        } else if (e.toString().contains('403') || e.toString().contains('not active')) {
          errorMessage = 'حسابك غير مفعل أو في انتظار الموافقة';
        } else if (e.toString().contains('404') || e.toString().contains('not found')) {
          errorMessage = 'لم يتم العثور على بيانات المتجر';
        } else {
          errorMessage = 'خطأ: ${e.toString()}';
        }
        
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
            duration: const Duration(seconds: 4),
            action: shouldRedirect ? SnackBarAction(
              label: 'تسجيل الدخول',
              textColor: Colors.white,
              onPressed: () {
                context.go('/auth/vendor/login');
              },
            ) : null,
          ),
        );
        
        // إعادة التوجيه التلقائي للصفحة تسجيل الدخول
        if (shouldRedirect) {
          Future.delayed(const Duration(seconds: 2), () {
            if (context.mounted) {
              // تنظيف البيانات المحفوظة
              context.read<AuthProvider>().logout();
              context.go('/auth/vendor/login');
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!auth.isAuthenticated || !auth.isVendor) {
      return Scaffold(
        appBar: const CommonAppBar(title: 'لوحة تحكم البائع'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.store_outlined, size: 100, color: Colors.grey[400]),
              const SizedBox(height: 24),
              const Text(
                'يجب تسجيل الدخول كبائع',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.push('/auth/vendor/login'),
                child: const Text('تسجيل الدخول'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: CommonAppBar(
        title: 'لوحة التحكم',
        leadingIcon: Icons.dashboard_rounded,
        additionalActions: [
          IconButton(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: colorScheme.primaryContainer,
                              child: Icon(
                                Icons.store_rounded,
                                size: 45,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'مرحباً ${auth.user?.name ?? ""}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'إليك نظرة سريعة على متجرك',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stats Grid
                    if (_stats != null) ...[
                      const Text(
                        'الإحصائيات',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.13,
                        children: [
                          _buildStatCard(
                            icon: Icons.shopping_bag_outlined,
                            title: 'إجمالي الطلبات',
                            value: '${_stats!['total_orders'] ?? 0}',
                            color: Colors.blue,
                            subtitle: _stats!['pending_orders'] != null 
                              ? '${_stats!['pending_orders']} قيد الانتظار'
                              : null,
                          ),
                          _buildStatCard(
                            icon: Icons.attach_money,
                            title: 'إجمالي المبيعات',
                            value: '${(_stats!['total_sales'] ?? 0).toStringAsFixed(0)} د.ع',
                            color: Colors.purple,
                            subtitle: _stats!['today_sales'] != null 
                              ? 'اليوم: ${(_stats!['today_sales']).toStringAsFixed(0)} د.ع'
                              : null,
                          ),
                          _buildStatCard(
                            icon: Icons.inventory_2_outlined,
                            title: 'المنتجات',
                            value: '${_stats!['total_products'] ?? 0}',
                            color: Colors.green,
                            subtitle: _stats!['active_products'] != null 
                              ? '${_stats!['active_products']} نشط'
                              : null,
                          ),
                          _buildStatCard(
                            icon: Icons.people_outlined,
                            title: 'العملاء',
                            value: '${_stats!['total_customers'] ?? 0}',
                            color: Colors.teal,
                            subtitle: _stats!['avg_order_value'] != null 
                              ? 'متوسط: ${(_stats!['avg_order_value']).toStringAsFixed(0)} د.ع'
                              : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Quick Actions
                    const Text(
                      'إجراءات سريعة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            context,
                            icon: Icons.add_box_outlined,
                            label: 'إضافة منتج',
                            onTap: () {
                              context.push('/vendor/add-product');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            context,
                            icon: Icons.list_alt_outlined,
                            label: 'الطلبات',
                            onTap: () {
                              context.push('/vendor/orders');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Recent Orders
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'الطلبات الأخيرة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.push('/vendor/orders');
                          },
                          child: const Text('عرض الكل'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_recentOrders.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'لا توجد طلبات حتى الآن',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recentOrders.length,
                        itemBuilder: (_, i) => _buildOrderCard(_recentOrders[i]),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    String? subtitle,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
              maxLines: 1,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String?;
    Color statusColor;
    String statusText;

    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'قيد الانتظار';
        break;
      case 'processing':
        statusColor = Colors.blue;
        statusText = 'قيد المعالجة';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusText = 'مكتمل';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'ملغي';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status ?? 'غير معروف';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withAlpha(50),
          child: Icon(Icons.shopping_bag_outlined, color: statusColor),
        ),
        title: Text('طلب #${order['id']}'),
        subtitle: Text('${order['total']} د.ع'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('قريباً...')),
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج من حسابك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                context.go('/home');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تسجيل الخروج بنجاح')),
                );
              }
            },
            child: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

