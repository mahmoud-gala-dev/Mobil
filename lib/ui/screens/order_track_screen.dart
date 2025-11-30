import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class OrderTrackScreen extends StatefulWidget {
  final String orderNumber;
  const OrderTrackScreen({super.key, required this.orderNumber});

  @override
  State<OrderTrackScreen> createState() => _OrderTrackScreenState();
}

class _OrderTrackScreenState extends State<OrderTrackScreen> {
  Map<String, dynamic>? order;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final res = await ApiService.I.trackOrder(widget.orderNumber);
      if (res['success'] == true) {
        setState(() => order = res['order'] as Map<String, dynamic>);
      }
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('تتبع الطلب ${widget.orderNumber}')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : order == null
              ? const Center(child: Text('الطلب غير موجود'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('الحالة', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(order!['status_label'] ?? order!['status']),
                    ]),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('${(order!['total'] as num).toStringAsFixed(2)} د.ك'),
                    ]),
                    const Divider(height: 24),
                    const Text('المنتجات', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...((order!['items'] as List).map((it) {
                      final p = it['product'] as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: p['image'] != null 
                            ? SizedBox(
                                width: 48,
                                height: 48,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    p['image'], 
                                    width: 48, 
                                    height: 48, 
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image_not_supported, size: 24),
                                      );
                                    },
                                  ),
                                ),
                              )
                            : null,
                          title: Text(
                            p['name'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            'x${it['quantity']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('${(it['total'] as num).toStringAsFixed(2)} د.ك'),
                        ),
                      );
                    })),
                  ],
                ),
    );
  }
}
