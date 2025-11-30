import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../state/favorites_provider.dart';
import '../../state/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../widgets/product_card.dart';
import '../widgets/app_drawer.dart';
import '../widgets/common_app_bar.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<ProductModel> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    
    // التحقق من تسجيل الدخول
    final auth = context.read<AuthProvider>();
    
    if (!auth.isAuthenticated) {
      print('⚠️ [FavoritesScreen] المستخدم غير مسجل دخول، التحويل لصفحة تسجيل الدخول');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('يجب تسجيل الدخول أولاً لعرض مفضلاتك'),
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
      final data = await ApiService.I.wishlist();
      final List raw = data['items'] as List? ?? [];
      setState(() {
        items = raw.map((e) => ProductModel.fromApi(e as Map<String, dynamic>)).toList();
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FavoritesProvider>(); // re-render when favorites change
    
    return Scaffold(
      appBar: const CommonAppBar(
        title: 'المفضلة',
        leadingIcon: Icons.favorite_rounded,
        showFavoritesButton: false, // لا نحتاج زر المفضلة في صفحة المفضلة
      ),
      drawer: const AppDrawer(),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border_rounded,
                        size: 120,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'لا توجد منتجات مفضلة',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'أضف منتجات لقائمة المفضلة لعرضها هنا',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/home'),
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: const Text('تصفح المنتجات'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, i) => ProductCard(product: items[i]),
                ),
    );
  }
}
