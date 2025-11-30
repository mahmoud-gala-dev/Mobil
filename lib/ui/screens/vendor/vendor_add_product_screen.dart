import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/api_service.dart';
import '../../widgets/common_app_bar.dart';

class VendorAddProductScreen extends StatefulWidget {
  const VendorAddProductScreen({super.key});

  @override
  State<VendorAddProductScreen> createState() => _VendorAddProductScreenState();
}

class _VendorAddProductScreenState extends State<VendorAddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _skuController = TextEditingController();
  
  // Form values
  int? _selectedCategoryId;
  int? _selectedBrandId;
  bool _isActive = true;
  bool _isFeatured = false;
  bool _isFresh = false;
  
  // Image picker
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _brands = [];
  
  @override
  void initState() {
    super.initState();
    _loadFormData();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _stockController.dispose();
    _skuController.dispose();
    super.dispose();
  }
  
  Future<void> _loadFormData() async {
    setState(() => _isLoading = true);
    try {
      // Load categories and brands
      final categoriesData = await ApiService.I.categories();
      final brandsData = await ApiService.I.brands();
      
      setState(() {
        _categories = categoriesData.map((cat) => {
          'id': cat.dbId,
          'name': cat.name,
        }).toList();
        _brands = brandsData;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ خطأ في تحميل البيانات: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        print('✅ تم اختيار الصورة: ${image.path}');
      }
    } catch (e) {
      print('❌ خطأ في اختيار الصورة: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في اختيار الصورة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final productData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'stock': int.parse(_stockController.text),
        'is_active': _isActive ? 1 : 0,
        'is_featured': _isFeatured ? 1 : 0,
        'is_fresh': _isFresh ? 1 : 0,
        if (_originalPriceController.text.isNotEmpty)
          'original_price': double.parse(_originalPriceController.text),
        if (_skuController.text.isNotEmpty) 'sku': _skuController.text,
        if (_selectedCategoryId != null) 'category_id': _selectedCategoryId,
        if (_selectedBrandId != null) 'brand_id': _selectedBrandId,
      };
      
      print('📤 إرسال بيانات المنتج: $productData');
      if (_selectedImage != null) {
        print('📸 مع صورة: ${_selectedImage!.path}');
      }
      
      await ApiService.I.vendorCreateProduct(productData, imageFile: _selectedImage);
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إضافة المنتج بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // العودة للداشبورد
        context.pop();
      }
    } catch (e) {
      print('❌ خطأ في إضافة المنتج: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إضافة المنتج: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'إضافة منتج جديد',
        leadingIcon: Icons.add_box_outlined,
        additionalActions: [
          // زر الحفظ في الأعلى
          if (!_isLoading)
            TextButton.icon(
              onPressed: _submitProduct,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text(
                'حفظ',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
        ],
      ),
      body: _isLoading && _categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // معلومات أساسية
                    _buildSectionTitle('المعلومات الأساسية'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _nameController,
                      label: 'اسم المنتج',
                      hint: 'أدخل اسم المنتج',
                      icon: Icons.inventory_2_outlined,
                      validator: (val) => val?.isEmpty == true ? 'الاسم مطلوب' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'الوصف',
                      hint: 'أدخل وصف المنتج',
                      icon: Icons.description_outlined,
                      maxLines: 4,
                      validator: (val) => val?.isEmpty == true ? 'الوصف مطلوب' : null,
                    ),
                    const SizedBox(height: 24),
                    
                    // صورة المنتج
                    _buildSectionTitle('صورة المنتج'),
                    const SizedBox(height: 12),
                    _buildImagePicker(),
                    const SizedBox(height: 24),
                    
                    // التصنيف والعلامة التجارية
                    _buildSectionTitle('التصنيف والعلامة التجارية'),
                    const SizedBox(height: 12),
                    _buildCategoryDropdown(
                      value: _selectedCategoryId,
                      items: _categories,
                      label: 'التصنيف',
                      hint: 'اختر التصنيف',
                      icon: Icons.category_outlined,
                      onChanged: (val) => setState(() => _selectedCategoryId = val),
                    ),
                    const SizedBox(height: 16),
                    _buildBrandDropdown(
                      value: _selectedBrandId,
                      items: _brands,
                      label: 'العلامة التجارية',
                      hint: 'اختر العلامة التجارية (اختياري)',
                      icon: Icons.branding_watermark_outlined,
                      onChanged: (val) => setState(() => _selectedBrandId = val),
                    ),
                    const SizedBox(height: 24),
                    
                    // السعر والمخزون
                    _buildSectionTitle('السعر والمخزون'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _priceController,
                            label: 'السعر',
                            hint: '0.00',
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            validator: (val) {
                              if (val?.isEmpty == true) return 'السعر مطلوب';
                              if (double.tryParse(val!) == null) return 'سعر غير صحيح';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _originalPriceController,
                            label: 'السعر الأصلي',
                            hint: '0.00 (اختياري)',
                            icon: Icons.money_off_outlined,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _stockController,
                            label: 'الكمية المتوفرة',
                            hint: '0',
                            icon: Icons.inventory_outlined,
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val?.isEmpty == true) return 'الكمية مطلوبة';
                              if (int.tryParse(val!) == null) return 'كمية غير صحيحة';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _skuController,
                            label: 'رمز المنتج (SKU)',
                            hint: 'اختياري',
                            icon: Icons.qr_code_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // الخيارات
                    _buildSectionTitle('الخيارات'),
                    const SizedBox(height: 12),
                    _buildSwitch(
                      value: _isActive,
                      title: 'منتج نشط',
                      subtitle: 'سيظهر المنتج للعملاء',
                      onChanged: (val) => setState(() => _isActive = val),
                    ),
                    _buildSwitch(
                      value: _isFeatured,
                      title: 'منتج مميز',
                      subtitle: 'سيظهر في قسم المنتجات المميزة',
                      onChanged: (val) => setState(() => _isFeatured = val),
                    ),
                    _buildSwitch(
                      value: _isFresh,
                      title: 'منتج طازج',
                      subtitle: 'سيظهر في قسم المنتجات الطازجة',
                      onChanged: (val) => setState(() => _isFresh = val),
                    ),
                    const SizedBox(height: 32),
                    
                    // أزرار الإجراءات
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => context.pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('إلغاء', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _submitProduct,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(
                              _isLoading ? 'جاري الحفظ...' : 'حفظ المنتج',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
    );
  }
  
  Widget _buildCategoryDropdown({
    required int? value,
    required List<Map<String, dynamic>> items,
    required String label,
    required String hint,
    required IconData icon,
    required Function(int?) onChanged,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
      items: items.map((item) {
        return DropdownMenuItem<int>(
          value: item['id'] as int,
          child: Text(item['name'] ?? 'غير معروف'),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
  
  Widget _buildBrandDropdown({
    required int? value,
    required List<Map<String, dynamic>> items,
    required String label,
    required String hint,
    required IconData icon,
    required Function(int?) onChanged,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
      items: items.map((item) {
        final itemId = item['id'];
        return DropdownMenuItem<int>(
          value: itemId is int ? itemId : int.tryParse(itemId.toString()),
          child: Text(item['name'] ?? item['name_ar'] ?? 'غير معروف'),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
  
  Widget _buildSwitch({
    required bool value,
    required String title,
    required String subtitle,
    required Function(bool) onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ),
    );
  }
  
  Widget _buildImagePicker() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: _selectedImage != null
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.red,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      onPressed: () => setState(() => _selectedImage = null),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            )
          : InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'اضغط لاختيار صورة المنتج',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الحد الأقصى: 1920x1920 بكسل',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

