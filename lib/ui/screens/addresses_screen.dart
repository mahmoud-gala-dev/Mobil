import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  List<Map<String, dynamic>> _addresses = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final addresses = await ApiService.I.getAddresses();
      setState(() {
        _addresses = addresses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAddress(int addressId) async {
    try {
      await ApiService.I.deleteAddress(addressId);
      _loadAddresses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف العنوان بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  Future<void> _setDefaultAddress(int addressId) async {
    try {
      await ApiService.I.setDefaultAddress(addressId);
      _loadAddresses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تعيين العنوان الافتراضي')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عناويني'),
        backgroundColor: Colors.blue,
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
                        onPressed: _loadAddresses,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : _addresses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text('لا توجد عناوين محفوظة'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              _showAddressDialog(context);
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('إضافة عنوان جديد'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAddresses,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _addresses.length,
                        itemBuilder: (ctx, i) {
                          final address = _addresses[i];
                          final isDefault = address['is_default'] == true || address['is_default'] == 1;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isDefault ? Colors.blue : Colors.grey,
                                child: Icon(
                                  isDefault ? Icons.home : Icons.location_on,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                address['label'] ?? 'عنوان',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(address['address'] ?? ''),
                                  if (address['city'] != null || address['governorate'] != null)
                                    Text('${address['city'] ?? ''}, ${address['governorate'] ?? ''}'),
                                  if (isDefault)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Text(
                                        'العنوان الافتراضي',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (ctx) => [
                                  if (!isDefault)
                                    const PopupMenuItem(
                                      value: 'default',
                                      child: Row(
                                        children: [
                                          Icon(Icons.star, size: 20),
                                          SizedBox(width: 8),
                                          Text('تعيين كافتراضي'),
                                        ],
                                      ),
                                    ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 20),
                                        SizedBox(width: 8),
                                        Text('تعديل'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 20, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('حذف', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'default') {
                                    _setDefaultAddress(address['id']);
                                  } else if (value == 'edit') {
                                    _showAddressDialog(context, address: address);
                                  } else if (value == 'delete') {
                                    _showDeleteConfirmation(context, address['id']);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddressDialog(context);
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, int addressId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا العنوان؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteAddress(addressId);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddressDialog(BuildContext context, {Map<String, dynamic>? address}) {
    final labelController = TextEditingController(text: address?['label']);
    final addressController = TextEditingController(text: address?['address']);
    final cityController = TextEditingController(text: address?['city']);
    final governorateController = TextEditingController(text: address?['governorate']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(address == null ? 'إضافة عنوان جديد' : 'تعديل العنوان'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: 'التسمية (مثل: المنزل، العمل)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'العنوان التفصيلي',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'المدينة',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: governorateController,
                decoration: const InputDecoration(
                  labelText: 'المحافظة',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              final data = {
                'label': labelController.text,
                'address': addressController.text,
                'city': cityController.text,
                'governorate': governorateController.text,
              };

              try {
                if (address == null) {
                  await ApiService.I.createAddress(data);
                } else {
                  await ApiService.I.updateAddress(address['id'], data);
                }
                
                if (context.mounted) {
                  Navigator.pop(ctx);
                  _loadAddresses();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(address == null ? 'تم إضافة العنوان بنجاح' : 'تم تحديث العنوان بنجاح'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: $e')),
                  );
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

