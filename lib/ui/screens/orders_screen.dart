import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../state/auth_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/common_app_bar.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List orders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    // تأجيل التنفيذ حتى يكتمل البناء
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
    });
  }

  Future<void> _load() async {
    if (!mounted) return;
    
    setState(() => loading = true);
    
    // التحقق من تسجيل الدخول
    final auth = context.read<AuthProvider>();
    
    if (!auth.isAuthenticated) {
      print('⚠️ [OrdersScreen] المستخدم غير مسجل دخول، التحويل لصفحة تسجيل الدخول');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('يجب تسجيل الدخول أولاً لعرض طلباتك'),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          context.go('/auth/customer/login');
        }
      }
      return;
    }
    
    try {
      orders = await ApiService.I.recentOrders();
    } catch (e) {
      print('❌ [OrdersScreen] خطأ في جلب الطلبات: $e');
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        title: 'طلباتي',
        leadingIcon: Icons.receipt_long_rounded,
      ),
      drawer: const AppDrawer(),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 120,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'لا توجد طلبات',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'لم تقم بأي طلبات بعد',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/home'),
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: const Text('ابدأ التسوق'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final o = orders[i] as Map<String, dynamic>;
                    final colorScheme = Theme.of(context).colorScheme;
                    
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.receipt,
                            color: colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          o['order_number'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            o['status_label'] ?? o['status'] ?? '',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${(o['total'] as num).toStringAsFixed(2)} د.ع',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Icon(Icons.arrow_forward_ios, size: 14),
                          ],
                        ),
                        onTap: () => context.push('/order-track/${o['order_number']}'),
                      ),
                    );
                  },
                ),
    );
  }
}
