import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../widgets/common_app_bar.dart';

class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String _selectedStatus = 'all';
  
  final List<Map<String, dynamic>> _statusFilters = [
    {'value': 'all', 'label': 'الكل', 'icon': Icons.list_alt, 'color': Colors.blue},
    {'value': 'pending', 'label': 'قيد الانتظار', 'icon': Icons.pending_outlined, 'color': Colors.orange},
    {'value': 'processing', 'label': 'قيد التحضير', 'icon': Icons.local_shipping_outlined, 'color': Colors.blue},
    {'value': 'delivered', 'label': 'مكتملة', 'icon': Icons.check_circle_outlined, 'color': Colors.green},
    {'value': 'cancelled', 'label': 'ملغاة', 'icon': Icons.cancel_outlined, 'color': Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      print('📦 [VendorOrders] جلب الطلبات...');
      
      final params = _selectedStatus != 'all' ? {'status': _selectedStatus} : null;
      final orders = await ApiService.I.vendorGetOrders(params: params);
      
      print('✅ [VendorOrders] تم جلب ${orders.length} طلب');
      
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('❌ [VendorOrders] خطأ في تحميل الطلبات: $e');
      print('Stack trace: $stackTrace');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('خطأ: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'processing':
        return 'قيد التحضير';
      case 'delivered':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending_outlined;
      case 'processing':
        return Icons.local_shipping_outlined;
      case 'delivered':
        return Icons.check_circle_outlined;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outlined;
    }
  }

  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    try {
      print('🔄 [VendorOrders] تحديث حالة الطلب #$orderId إلى $newStatus');
      
      await ApiService.I.vendorUpdateOrderStatus(orderId, newStatus);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم تحديث حالة الطلب بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        
        // إعادة تحميل الطلبات
        _loadOrders();
      }
    } catch (e) {
      print('❌ [VendorOrders] خطأ في تحديث حالة الطلب: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث الحالة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order['status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getStatusIcon(order['status']),
                      color: _getStatusColor(order['status']),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'طلب #${order['id']}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(order['status']).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getStatusLabel(order['status']),
                            style: TextStyle(
                              color: _getStatusColor(order['status']),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // معلومات العميل
              _buildDetailSection(
                title: 'معلومات العميل',
                icon: Icons.person_outline,
                children: [
                  _buildDetailRow('الاسم', order['customer_name'] ?? 'غير متوفر'),
                  _buildDetailRow('الهاتف', order['customer_phone'] ?? 'غير متوفر'),
                  _buildDetailRow('العنوان', order['customer_address'] ?? 'غير متوفر'),
                ],
              ),
              const SizedBox(height: 20),
              
              // المنتجات
              _buildDetailSection(
                title: 'المنتجات (${order['items_count'] ?? 0})',
                icon: Icons.shopping_cart_outlined,
                children: [
                  if (order['items'] != null)
                    ...(order['items'] as List).map((item) => _buildOrderItem(item)),
                ],
              ),
              const SizedBox(height: 20),
              
              // المجموع
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'المجموع الكلي',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${order['total'] ?? 0} د.ع',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // أزرار تغيير الحالة
              if (order['status'] != 'delivered' && order['status'] != 'cancelled')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'تغيير حالة الطلب',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (order['status'] == 'pending')
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _updateOrderStatus(order['id'], 'processing');
                        },
                        icon: const Icon(Icons.local_shipping_outlined),
                        label: const Text('بدء التحضير'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    if (order['status'] == 'processing')
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _updateOrderStatus(order['id'], 'delivered');
                        },
                        icon: const Icon(Icons.check_circle_outlined),
                        label: const Text('تم التوصيل'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateOrderStatus(order['id'], 'cancelled');
                      },
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('إلغاء الطلب'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'منتج',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'الكمية: ${item['quantity']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${item['price']} د.ع',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: const CommonAppBar(
        title: 'الطلبات',
        leadingIcon: Icons.list_alt_outlined,
      ),
      body: Column(
        children: [
          // فلاتر الحالة
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _statusFilters.length,
              itemBuilder: (context, index) {
                final filter = _statusFilters[index];
                final isSelected = _selectedStatus == filter['value'];
                
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          filter['icon'] as IconData,
                          size: 18,
                          color: isSelected ? Colors.white : filter['color'] as Color,
                        ),
                        const SizedBox(width: 6),
                        Text(filter['label'] as String),
                      ],
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedStatus = filter['value'] as String);
                        _loadOrders();
                      }
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: filter['color'] as Color,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          
          const Divider(height: 1),
          
          // قائمة الطلبات
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 100,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'لا توجد طلبات',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'لم يتم استلام أي طلبات بعد',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _orders.length,
                          itemBuilder: (context, index) {
                            final order = _orders[index];
                            final statusColor = _getStatusColor(order['status']);
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              child: InkWell(
                                onTap: () => _showOrderDetails(order),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  _getStatusIcon(order['status']),
                                                  color: statusColor,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'طلب #${order['id']}',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    order['customer_name'] ?? 'عميل',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _getStatusLabel(order['status']),
                                              style: TextStyle(
                                                color: statusColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      const Divider(height: 1),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.shopping_bag_outlined,
                                                size: 16,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${order['items_count'] ?? 0} منتج',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '${order['total'] ?? 0} د.ع',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

