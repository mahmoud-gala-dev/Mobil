import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../state/products_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/app_drawer.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/enhanced_slider_card.dart';
import '../widgets/app_footer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProductsProvider>();
    
    return Scaffold(
      appBar: const CommonAppBar(
        title: 'إيليت وان',
        leadingIcon: Icons.store_rounded,
      ),
      drawer: const AppDrawer(),
      body: p.loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'جارِ تحميل البيانات...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : p.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
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
                          p.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => p.loadInitial(),
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
              : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // السلايدر المحسّن في بداية الصفحة
                  if (p.sliders.isNotEmpty)
                    CarouselSlider(
                      options: CarouselOptions(
                        height: MediaQuery.of(context).size.height * 0.25,
                        autoPlay: true,
                        autoPlayInterval: const Duration(seconds: 5),
                        autoPlayAnimationDuration: const Duration(milliseconds: 800),
                        enlargeCenterPage: false,
                        viewportFraction: 1.0,
                        enableInfiniteScroll: true,
                        pauseAutoPlayOnTouch: true,
                      ),
                      items: p.sliders.map((slider) {
                        return EnhancedSliderCard(slider: slider);
                      }).toList(),
                    )
                  else
                    const SizedBox(height: 10),
                  
                  // الأقسام
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.category_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'الأقسام',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () => context.push('/categories'),
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text('عرض الكل'),
                        ),
                      ],
                    ),
                  ),
                  
                  // عرض الأقسام أو رسالة
                  if (p.categories.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                Icons.category_outlined,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'لا توجد أقسام متاحة حالياً',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'تحقق من اتصال الإنترنت أو إعدادات الخادم',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        scrollDirection: Axis.horizontal,
                        itemCount: p.categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) {
                          final c = p.categories[i];
                          print('📂 [HomeScreen] القسم #$i: ${c.name}');
                          print('🖼️  [HomeScreen] صورة القسم: ${c.image}');
                          
                          return InkWell(
                            onTap: () {
                              print('👆 [HomeScreen] النقر على القسم: ${c.name} (${c.id})');
                              context.push('/category/${c.id}');
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 90,
                              child: Column(
                                children: [
                                  Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        c.image,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            print('✅ [HomeScreen] تم تحميل صورة القسم: ${c.name}');
                                            return child;
                                          }
                                          return Container(
                                            color: Colors.grey[200],
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                        loadingProgress.expectedTotalBytes!
                                                    : null,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          print('❌ [HomeScreen] خطأ في تحميل صورة القسم: ${c.name}');
                                          print('❌ [HomeScreen] المسار: ${c.image}');
                                          print('❌ [HomeScreen] الخطأ: $error');
                                          return Container(
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primaryContainer,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.category,
                                              size: 40,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: 90,
                                    child: Text(
                                      c.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),
                  
                  // المنتجات
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'الأكثر طلباً',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // عرض المنتجات أو رسالة
                  if (p.products.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(30),
                          child: Column(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'لا توجد منتجات متاحة حالياً',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: p.products.length,
                      itemBuilder: (_, i) => ProductCard(product: p.products[i]),
                    ),
                    
                    // Footer
                    const SizedBox(height: 40),
                    const AppFooter(),
                  ],
                ),
              ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.category_outlined), label: 'الأقسام'),
          NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), label: 'السلة'),
        ],
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/categories');
              break;
            case 2:
              context.go('/cart');
              break;
          }
        },
        selectedIndex: 0,
      ),
    );
  }
}
