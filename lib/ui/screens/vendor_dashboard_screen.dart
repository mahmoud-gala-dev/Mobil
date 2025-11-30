import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _recentOrders = [];
  List<Map<String, dynamic>> _topProducts = [];
  int _unreadNotifications = 0;
  bool _isLoading = true;
  String _error = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final stats = await ApiService.I.vendorDashboardStats();
      final recentOrders = await ApiService.I.vendorRecentOrders();
      final topProducts = await ApiService.I.vendorTopProducts();
      final unreadCount = await ApiService.I.vendorUnreadNotificationsCount();

      setState(() {
        _stats = stats;
        _recentOrders = recentOrders;
        _topProducts = topProducts;
        _unreadNotifications = unreadCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        backgroundColor: Colors.blue,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => const VendorNotificationsScreen(),
                    ),
                  );
                },
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_unreadNotifications',
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
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('خطأ: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDashboardData,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Cards
                        _buildStatsGrid(),
                        const SizedBox(height: 24),
                        // Recent Orders
                        _buildSectionHeader('الطلبات الأخيرة', onSeeAll: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => const VendorOrdersScreen(),
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                        _buildRecentOrders(),
                        const SizedBox(height: 24),
                        // Top Products
                        _buildSectionHeader('المنتجات الأكثر مبيعاً', onSeeAll: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => const VendorProductsScreen(),
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                        _buildTopProducts(),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          switch (index) {
            case 0:
              // Dashboard - already here
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => const VendorProductsScreen(),
                ),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => const VendorOrdersScreen(),
                ),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => const VendorSettingsScreen(),
                ),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'المنتجات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'الطلبات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard(
          'إجمالي المبيعات',
          '${_stats?['total_sales'] ?? 0} ج.م',
          Icons.attach_money,
          Colors.green,
        ),
        _buildStatCard(
          'عدد الطلبات',
          '${_stats?['total_orders'] ?? 0}',
          Icons.shopping_cart,
          Colors.blue,
        ),
        _buildStatCard(
          'المنتجات',
          '${_stats?['total_products'] ?? 0}',
          Icons.inventory,
          Colors.orange,
        ),
        _buildStatCard(
          'التقييم',
          '${_stats?['rating'] ?? 0}',
          Icons.star,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('عرض الكل'),
          ),
      ],
    );
  }

  Widget _buildRecentOrders() {
    if (_recentOrders.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('لا توجد طلبات حديثة')),
        ),
      );
    }

    return Column(
      children: _recentOrders.take(5).map((order) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(order['status']),
              child: const Icon(Icons.shopping_cart, color: Colors.white),
            ),
            title: Text('طلب #${order['order_number'] ?? order['id']}'),
            subtitle: Text('${order['total'] ?? 0} ج.م'),
            trailing: Chip(
              label: Text(
                _getStatusText(order['status']),
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: _getStatusColor(order['status']).withOpacity(0.2),
            ),
            onTap: () {
              // Navigate to order details
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopProducts() {
    if (_topProducts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('لا توجد بيانات متاحة')),
        ),
      );
    }

    return Column(
      children: _topProducts.take(5).map((product) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product['image'] != null
                  ? Image.network(
                      product['image'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image),
                    ),
            ),
            title: Text(product['name'] ?? ''),
            subtitle: Text('${product['price'] ?? 0} ج.م'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'المبيعات: ${product['sales_count'] ?? 0}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${product['total_sales'] ?? 0} ج.م',
                  style: const TextStyle(color: Colors.green, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'processing':
        return 'قيد التجهيز';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      default:
        return 'غير معروف';
    }
  }
}

// Placeholder screens
class VendorNotificationsScreen extends StatelessWidget {
  const VendorNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(child: Text('شاشة الإشعارات')),
    );
  }
}

class VendorProductsScreen extends StatelessWidget {
  const VendorProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المنتجات'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(child: Text('شاشة المنتجات')),
    );
  }
}

class VendorOrdersScreen extends StatelessWidget {
  const VendorOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الطلبات'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(child: Text('شاشة الطلبات')),
    );
  }
}

class VendorSettingsScreen extends StatelessWidget {
  const VendorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(child: Text('شاشة الإعدادات')),
    );
  }
}

