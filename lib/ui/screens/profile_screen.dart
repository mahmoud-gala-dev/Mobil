import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../state/auth_provider.dart';
import '../../models/models.dart';
import '../widgets/app_drawer.dart';

class ProfileScreen extends StatefulWidget {
  final int initialTab;
  const ProfileScreen({super.key, this.initialTab = 0});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  List<AddressModel> _addresses = [];
  bool loading = true;
  bool saving = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _load();
  }

  Future<void> _load() async {
    print('📱 [ProfileScreen] تحميل بيانات البروفايل...');
    setState(() => loading = true);
    try {
      // التحقق من تسجيل الدخول أولاً
      final auth = context.read<AuthProvider>();
      
      if (!auth.isAuthenticated) {
        print('⚠️ [ProfileScreen] المستخدم غير مسجل دخول، التحويل لصفحة تسجيل الدخول');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('يجب تسجيل الدخول أولاً للوصول إلى حسابك'),
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
      
      // استخدام البيانات من AuthProvider أولاً للسرعة
      if (auth.isAuthenticated && auth.user != null) {
        _name.text = auth.user!.name;
        _email.text = auth.user!.email;
        final phoneValue = auth.user!.phone;
        _phone.text = (phoneValue != null && phoneValue.trim().isNotEmpty) 
            ? phoneValue.trim() 
            : '';
        
        print('✅ [ProfileScreen] تم تعبئة البيانات من AuthProvider:');
        print('   الاسم: ${_name.text}');
        print('   البريد: ${_email.text}');
        print('   الهاتف: ${_phone.text}');
      }
      
      // ثم جلب البيانات المحدثة من API للتأكد
      try {
        print('📡 [ProfileScreen] جلب بيانات المستخدم المحدثة من API...');
        final me = await ApiService.I.me();
        print('📦 [ProfileScreen] استجابة me API: $me');
        
        // معالجة بيانات المستخدم
        final u = me['user'] as Map<String, dynamic>?;
        if (u != null) {
          _name.text = (u['name'] ?? '').toString().trim();
          _email.text = (u['email'] ?? '').toString().trim();
          // التأكد من معالجة phone null بشكل صحيح
          final phoneValue = u['phone'];
          _phone.text = (phoneValue != null && phoneValue.toString().trim().isNotEmpty) 
              ? phoneValue.toString().trim() 
              : '';
          
          print('✅ [ProfileScreen] تحديث بيانات المستخدم من API:');
          print('   الاسم: ${_name.text}');
          print('   البريد: ${_email.text}');
          print('   الهاتف: ${_phone.text}');
        } else {
          print('⚠️ [ProfileScreen] لا توجد بيانات مستخدم في الاستجابة');
        }
      } catch (e) {
        print('⚠️ [ProfileScreen] فشل جلب البيانات من API: $e');
        // الاستمرار مع البيانات من AuthProvider
      }
      
      // تحميل العناوين
      print('📡 [ProfileScreen] جلب العناوين...');
      try {
        final addresses = await ApiService.I.getAddresses();
        print('📦 [ProfileScreen] استجابة العناوين: $addresses');
        _addresses = addresses.map((a) => AddressModel.fromApi(a)).toList();
        print('✅ [ProfileScreen] تم جلب ${_addresses.length} عنوان');
        
        if (_addresses.isNotEmpty) {
          final defaultAddr = _addresses.where((a) => a.isDefault).toList();
          print('🏠 [ProfileScreen] العناوين الافتراضية: ${defaultAddr.length}');
        }
      } catch (e) {
        print('⚠️ [ProfileScreen] خطأ في جلب العناوين: $e');
        _addresses = [];
      }
      
    } catch (e, stackTrace) {
      print('❌ [ProfileScreen] خطأ في تحميل البيانات: $e');
      print('📍 [ProfileScreen] Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _save() async {
    print('💾 [ProfileScreen] حفظ التغييرات...');
    print('   الاسم: ${_name.text}');
    print('   البريد: ${_email.text}');
    print('   الهاتف: ${_phone.text}');
    
    setState(() => saving = true);
    try {
      // تحديث البروفايل عبر AuthProvider لتحديث البيانات في كل التطبيق
      await context.read<AuthProvider>().updateProfile(
        name: _name.text,
        email: _email.text,
        phone: _phone.text,
      );
      
      print('✅ [ProfileScreen] تم حفظ التغييرات بنجاح');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('تم حفظ التغييرات'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ [ProfileScreen] فشل حفظ التغييرات: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('فشل حفظ التغييرات: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _logout() async {
    print('👋 [ProfileScreen] تسجيل الخروج...');
    
    try {
      await context.read<AuthProvider>().logout();
      print('✅ [ProfileScreen] تم تسجيل الخروج بنجاح');
    } catch (e) {
      print('❌ [ProfileScreen] خطأ في تسجيل الخروج: $e');
    }
    
    if (mounted) {
      print('🔄 [ProfileScreen] الانتقال إلى صفحة تسجيل الدخول');
      context.go('/auth/customer/login');
    }
  }

  void _showAddAddressDialog() async {
    final labelController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    
    // جلب المحافظات من API
    List<Map<String, dynamic>> governorates = [];
    List<Map<String, dynamic>> cities = [];
    bool isLoadingCities = false;
    
    try {
      governorates = await ApiService.I.getGovernorates();
      print('✅ [ProfileScreen] تم جلب ${governorates.length} محافظة');
    } catch (e) {
      print('❌ [ProfileScreen] فشل جلب المحافظات: $e');
    }
    
    String? selectedGovernorate;
    int? selectedGovernorateId;
    String? selectedCity;
    bool isDefault = false;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
        title: const Text('إضافة عنوان جديد'),
            content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                  // التسمية
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    labelText: 'التسمية (مثل: المنزل، العمل)',
                      prefixIcon: Icon(Icons.label_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                  const SizedBox(height: 16),
                  
                  // العنوان التفصيلي
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'العنوان التفصيلي',
                      prefixIcon: Icon(Icons.home_outlined),
                    border: OutlineInputBorder(),
                      hintText: 'مثال: شارع الملك فهد، مبنى 5، شقة 12',
                  ),
                  maxLines: 3,
                ),
                  const SizedBox(height: 16),
                  
                  // المحافظة (Dropdown)
                  DropdownButtonFormField<String>(
                    value: selectedGovernorate,
                  decoration: const InputDecoration(
                      labelText: 'المحافظة',
                      prefixIcon: Icon(Icons.location_city),
                    border: OutlineInputBorder(),
                  ),
                    hint: const Text('اختر المحافظة'),
                    isExpanded: true,
                    items: governorates.map((gov) {
                      return DropdownMenuItem<String>(
                        value: gov['name_ar'] as String?,
                        child: Text(gov['name_ar'] as String? ?? ''),
                        onTap: () {
                          selectedGovernorateId = (gov['id'] as num?)?.toInt();
                        },
                      );
                    }).toList(),
                    onChanged: (value) async {
                      setDialogState(() {
                        selectedGovernorate = value;
                        selectedCity = null; // إعادة تعيين المدينة
                        cities = [];
                        isLoadingCities = true;
                      });
                      
                      // جلب المدن بناءً على المحافظة المختارة
                      if (selectedGovernorateId != null) {
                        try {
                          final fetchedCities = await ApiService.I.getCities(
                            governorateId: selectedGovernorateId,
                          );
                          setDialogState(() {
                            cities = fetchedCities;
                            isLoadingCities = false;
                          });
                          print('✅ [ProfileScreen] تم جلب ${cities.length} مدينة للمحافظة $selectedGovernorate');
                        } catch (e) {
                          print('❌ [ProfileScreen] فشل جلب المدن: $e');
                          setDialogState(() {
                            isLoadingCities = false;
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // المدينة (Dropdown)
                  DropdownButtonFormField<String>(
                    value: selectedCity,
                    decoration: InputDecoration(
                      labelText: 'المدينة',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: const OutlineInputBorder(),
                      suffixIcon: isLoadingCities
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                    hint: Text(
                      selectedGovernorate == null
                          ? 'اختر المحافظة أولاً'
                          : 'اختر المدينة',
                    ),
                    isExpanded: true,
                    items: cities.map((city) {
                      return DropdownMenuItem<String>(
                        value: city['name_ar'] as String?,
                        child: Text(city['name_ar'] as String? ?? ''),
                      );
                    }).toList(),
                    onChanged: selectedGovernorate == null || isLoadingCities
                        ? null
                        : (value) {
                            setDialogState(() {
                              selectedCity = value;
                            });
                          },
                  ),
                  const SizedBox(height: 16),
                  
                  // رقم الهاتف (اختياري)
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف (اختياري)',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                      hintText: 'رقم هاتف للتواصل عند التوصيل',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  
                  // جعله افتراضي
                CheckboxListTile(
                  value: isDefault,
                  onChanged: (value) {
                      setDialogState(() {
                        isDefault = value ?? false;
                      });
                  },
                  title: const Text('جعله العنوان الافتراضي'),
                    subtitle: const Text('سيتم استخدامه تلقائياً عند الطلب'),
                  controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                ),
              ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
              ElevatedButton.icon(
            onPressed: () async {
                  // التحقق من البيانات
                  if (labelController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('الرجاء إدخال تسمية العنوان')),
                    );
                    return;
                  }
                  
                  if (addressController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('الرجاء إدخال العنوان التفصيلي')),
                );
                return;
              }

                  final addressData = {
                    'label': labelController.text.trim(),
                    'address': addressController.text.trim(),
                    'city': selectedCity ?? '',
                    'governorate': selectedGovernorate ?? '',
                    'phone': phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
                    'is_default': isDefault,
                  };
                  
                  print('📍 [ProfileScreen] إضافة عنوان جديد...');
                  print('   البيانات المرسلة: $addressData');
                  
                  try {
                    final response = await ApiService.I.createAddress(addressData);
                    print('✅ [ProfileScreen] استجابة API: $response');
                    print('✅ [ProfileScreen] تم إضافة العنوان بنجاح');

                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text('تم إضافة العنوان بنجاح'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                    ),
                  );
                  _load();
                }
              } catch (e) {
                print('❌ [ProfileScreen] فشل إضافة العنوان: $e');
                
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
            },
                icon: const Icon(Icons.add_location),
                label: const Text('إضافة'),
          ),
        ],
          );
        },
      ),
    );
  }

  void _showEditAddressDialog(AddressModel address) async {
    final labelController = TextEditingController(text: address.label);
    final addressController = TextEditingController(text: address.address);
    final phoneController = TextEditingController(text: address.phone ?? '');
    
    // جلب المحافظات من API
    List<Map<String, dynamic>> governorates = [];
    List<Map<String, dynamic>> cities = [];
    bool isLoadingCities = false;
    
    try {
      governorates = await ApiService.I.getGovernorates();
      print('✅ [ProfileScreen] تم جلب ${governorates.length} محافظة');
    } catch (e) {
      print('❌ [ProfileScreen] فشل جلب المحافظات: $e');
    }
    
    String? selectedGovernorate = address.governorate;
    int? selectedGovernorateId;
    String? selectedCity = address.city;
    bool isDefault = address.isDefault;
    
    // البحث عن معرف المحافظة الحالية
    if (selectedGovernorate != null && selectedGovernorate.isNotEmpty) {
      final currentGov = governorates.firstWhere(
        (gov) => gov['name_ar'] == selectedGovernorate,
        orElse: () => <String, dynamic>{},
      );
      if (currentGov.isNotEmpty) {
        selectedGovernorateId = (currentGov['id'] as num?)?.toInt();
        
        // جلب المدن للمحافظة الحالية
        if (selectedGovernorateId != null) {
          try {
            cities = await ApiService.I.getCities(governorateId: selectedGovernorateId);
            print('✅ [ProfileScreen] تم جلب ${cities.length} مدينة للمحافظة $selectedGovernorate');
          } catch (e) {
            print('❌ [ProfileScreen] فشل جلب المدن: $e');
          }
        }
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
        title: const Text('تعديل العنوان'),
            content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                  // التسمية
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    labelText: 'التسمية',
                      prefixIcon: Icon(Icons.label_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                  const SizedBox(height: 16),
                  
                  // العنوان التفصيلي
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'العنوان التفصيلي',
                      prefixIcon: Icon(Icons.home_outlined),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                  const SizedBox(height: 16),
                  
                  // المحافظة (Dropdown)
                  DropdownButtonFormField<String>(
                    value: selectedGovernorate,
                  decoration: const InputDecoration(
                      labelText: 'المحافظة',
                      prefixIcon: Icon(Icons.location_city),
                    border: OutlineInputBorder(),
                  ),
                    hint: const Text('اختر المحافظة'),
                    isExpanded: true,
                    items: governorates.map((gov) {
                      return DropdownMenuItem<String>(
                        value: gov['name_ar'] as String?,
                        child: Text(gov['name_ar'] as String? ?? ''),
                        onTap: () {
                          selectedGovernorateId = (gov['id'] as num?)?.toInt();
                        },
                      );
                    }).toList(),
                    onChanged: (value) async {
                      setDialogState(() {
                        selectedGovernorate = value;
                        selectedCity = null;
                        cities = [];
                        isLoadingCities = true;
                      });
                      
                      if (selectedGovernorateId != null) {
                        try {
                          final fetchedCities = await ApiService.I.getCities(
                            governorateId: selectedGovernorateId,
                          );
                          setDialogState(() {
                            cities = fetchedCities;
                            isLoadingCities = false;
                          });
                        } catch (e) {
                          print('❌ [ProfileScreen] فشل جلب المدن: $e');
                          setDialogState(() {
                            isLoadingCities = false;
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // المدينة (Dropdown)
                  DropdownButtonFormField<String>(
                    value: selectedCity,
                    decoration: InputDecoration(
                      labelText: 'المدينة',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: const OutlineInputBorder(),
                      suffixIcon: isLoadingCities
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                    hint: Text(
                      selectedGovernorate == null
                          ? 'اختر المحافظة أولاً'
                          : 'اختر المدينة',
                    ),
                    isExpanded: true,
                    items: cities.map((city) {
                      return DropdownMenuItem<String>(
                        value: city['name_ar'] as String?,
                        child: Text(city['name_ar'] as String? ?? ''),
                      );
                    }).toList(),
                    onChanged: selectedGovernorate == null || isLoadingCities
                        ? null
                        : (value) {
                            setDialogState(() {
                              selectedCity = value;
                            });
                          },
                  ),
                  const SizedBox(height: 16),
                  
                  // رقم الهاتف (اختياري)
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف (اختياري)',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                      hintText: 'رقم هاتف للتواصل عند التوصيل',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  
                  // جعله افتراضي
                CheckboxListTile(
                  value: isDefault,
                  onChanged: (value) {
                      setDialogState(() {
                        isDefault = value ?? false;
                      });
                  },
                  title: const Text('جعله العنوان الافتراضي'),
                    subtitle: const Text('سيتم استخدامه تلقائياً عند الطلب'),
                  controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                ),
              ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
              ElevatedButton.icon(
            onPressed: () async {
                  if (labelController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('الرجاء إدخال تسمية العنوان')),
                    );
                    return;
                  }
                  
                  if (addressController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('الرجاء إدخال العنوان التفصيلي')),
                    );
                    return;
                  }
                  
                  final updatedData = {
                    'label': labelController.text.trim(),
                    'address': addressController.text.trim(),
                    'city': selectedCity ?? '',
                    'governorate': selectedGovernorate ?? '',
                    'phone': phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
                    'is_default': isDefault,
                  };
                  
                  print('📝 [ProfileScreen] تحديث العنوان ID: ${address.id}');
                  print('   البيانات المرسلة: $updatedData');
                  
                  try {
                    final response = await ApiService.I.updateAddress(address.id, updatedData);
                    print('✅ [ProfileScreen] استجابة API: $response');

                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 12),
                              Text('تم تحديث العنوان بنجاح'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                  );
                  _load();
                }
              } catch (e) {
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
            },
                icon: const Icon(Icons.save_outlined),
                label: const Text('حفظ'),
          ),
        ],
          );
        },
      ),
    );
  }

  Future<void> _deleteAddress(int addressId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا العنوان؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      print('🗑️ [ProfileScreen] حذف العنوان ID: $addressId');
      try {
        await ApiService.I.deleteAddress(addressId);
        print('✅ [ProfileScreen] تم حذف العنوان بنجاح');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('تم حذف العنوان بنجاح'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
          _load();
        }
      } catch (e) {
        print('❌ [ProfileScreen] فشل حذف العنوان: $e');
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
  }

  Future<void> _setDefaultAddress(int addressId) async {
    print('⭐ [ProfileScreen] تعيين العنوان الافتراضي ID: $addressId');
    try {
      await ApiService.I.setDefaultAddress(addressId);
      print('✅ [ProfileScreen] تم تعيين العنوان الافتراضي بنجاح');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('تم تعيين العنوان الافتراضي'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
        _load();
      }
    } catch (e) {
      print('❌ [ProfileScreen] فشل تعيين العنوان الافتراضي: $e');
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

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(
              Icons.account_circle_rounded,
              color: Colors.white,
              size: 28,
            ),
            SizedBox(width: 12),
            Text(
              'حسابي',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // زر البحث
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => context.push('/search'),
            tooltip: 'البحث',
          ),
          // زر السلة
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            onPressed: () => context.push('/cart'),
            tooltip: 'السلة',
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.person_outline),
              text: 'المعلومات الشخصية',
            ),
            Tab(
              icon: Icon(Icons.location_on_outlined),
              text: 'العناوين',
            ),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(),
                _buildAddressesTab(),
              ],
            ),
    );
  }

  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Avatar Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
          child: Stack(
            children: [
              CircleAvatar(
                    radius: 55,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.person,
                      size: 55,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                  child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                    onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('قريباً: رفع الصورة الشخصية')),
                          );
                    },
                  ),
                ),
              ),
            ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Personal Information Section
        const Text(
          'المعلومات الشخصية',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Name Card
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
          controller: _name,
          decoration: const InputDecoration(
            labelText: 'الاسم الكامل',
            prefixIcon: Icon(Icons.person_outline),
                border: InputBorder.none,
                filled: false,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Email Card
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
          controller: _email,
              keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'البريد الإلكتروني',
            prefixIcon: Icon(Icons.email_outlined),
                border: InputBorder.none,
                filled: false,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Phone Card
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
          controller: _phone,
              keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'رقم الهاتف',
            prefixIcon: Icon(Icons.phone_outlined),
                border: InputBorder.none,
                filled: false,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        
        // Actions Section
        const Text(
          'الإعدادات',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Save Button
        SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: saving ? null : _save,
            icon: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(
              saving ? 'جارٍ الحفظ...' : 'حفظ التغييرات',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Logout Button
        SizedBox(
          height: 54,
          child: OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_outlined),
            label: const Text(
              'تسجيل الخروج',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAddressesTab() {
    return Column(
      children: [
        // Add Address Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _showAddAddressDialog,
            icon: const Icon(Icons.add_location),
            label: const Text('إضافة عنوان جديد'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
        
        // Addresses List
        Expanded(
          child: _addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد عناوين محفوظة',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _addresses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final address = _addresses[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: address.isDefault
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[300],
                            child: Icon(
                              Icons.location_on,
                              color: address.isDefault ? Colors.white : Colors.grey[600],
                            ),
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  address.label,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (address.isDefault) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'افتراضي',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(address.address),
                              if (address.city != null || address.governorate != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '${address.city ?? ''}, ${address.governorate ?? ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (ctx) => [
                              if (!address.isDefault)
                                const PopupMenuItem(
                                  value: 'default',
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle_outline),
                                      SizedBox(width: 8),
                                      Text('جعله افتراضي'),
                                    ],
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined),
                                    SizedBox(width: 8),
                                    Text('تعديل'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('حذف', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'default') {
                                _setDefaultAddress(address.id);
                              } else if (value == 'edit') {
                                _showEditAddressDialog(address);
                              } else if (value == 'delete') {
                                _deleteAddress(address.id);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
