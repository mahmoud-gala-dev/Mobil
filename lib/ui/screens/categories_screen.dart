import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../state/products_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/app_footer.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    print('📂 [CategoriesScreen] تهيئة صفحة الأقسام...');
  }
  
  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProductsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: const CommonAppBar(
        title: 'جميع الأقسام',
        leadingIcon: Icons.category_rounded,
      ),
      drawer: const AppDrawer(),
      body: p.categories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 100,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'لا توجد أقسام متاحة',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'تحقق من اتصال الإنترنت أو حاول مرة أخرى',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await context.read<ProductsProvider>().loadInitial();
              },
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primary,
                            colorScheme.primary.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.apps_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'استكشف الأقسام',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${p.categories.length} قسم متاح',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Grid
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                        childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                final c = p.categories[i];
                          final productCount = c.productsCount;
                          
                          return Hero(
                            tag: 'category_${c.id}',
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  print('👆 [CategoriesScreen] النقر على القسم: ${c.name}');
                                  context.push('/category/${c.id}');
                                },
                                borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                        spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                                        // الصورة مع Badge
                          Expanded(
                                          flex: 5,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                              // الصورة
                                Image.network(
                                  c.image,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) {
                                                    print('✅ [CategoriesScreen] تم تحميل صورة: ${c.name}');
                                                    return child;
                                                  }
                                    return Container(
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: CircularProgressIndicator(
                                                        strokeWidth: 3,
                                                        color: colorScheme.primary,
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                                errorBuilder: (context, error, stackTrace) {
                                                  print('❌ [CategoriesScreen] فشل تحميل صورة: ${c.name}');
                                                  return Container(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                        colors: [
                                                          colorScheme.primaryContainer,
                                                          colorScheme.primary.withOpacity(0.3),
                                                        ],
                                                      ),
                                                    ),
                                                    child: Center(
                                    child: Icon(
                                                        Icons.category_rounded,
                                                        size: 60,
                                                        color: colorScheme.primary,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              
                                              // تدرج للقراءة
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                                      Colors.black.withOpacity(0.1),
                                                      Colors.black.withOpacity(0.5),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              
                                              // عدد المنتجات Badge
                                              Positioned(
                                                top: 12,
                                                right: 12,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme.primary,
                                                    borderRadius: BorderRadius.circular(20),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.2),
                                                        blurRadius: 8,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.inventory_2,
                                                        color: Colors.white,
                                                        size: 14,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '$productCount',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                              ],
                            ),
                          ),
                          
                        // معلومات القسم
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // اسم القسم
                                Flexible(
                                  child: Text(
                                    c.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.shopping_bag_outlined,
                                      size: 13,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '$productCount منتج',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // زر استكشاف
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'استكشف',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      Icon(
                                        Icons.arrow_back,
                                        size: 11,
                                        color: colorScheme.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: p.categories.length,
                      ),
                    ),
                  ),
                  
                  // Footer
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: AppFooter(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
