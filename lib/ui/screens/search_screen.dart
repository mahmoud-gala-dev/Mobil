import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/products_provider.dart';
import '../../services/api_service.dart';
import '../widgets/product_card.dart';
import '../widgets/app_drawer.dart';
import '../widgets/common_app_bar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List products = [];
  bool loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _doSearch(String q) async {
    if (q.trim().isEmpty) {
      setState(() {
        products = context.read<ProductsProvider>().products;
      });
      return;
    }
    setState(() => loading = true);
    try {
      final res = await ApiService.I.search(q);
      setState(() => products = res);
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = context.watch<ProductsProvider>().products;
    final list = _controller.text.trim().isEmpty ? initial : products;

    return Scaffold(
      appBar: const CommonAppBar(
        title: 'البحث',
        leadingIcon: Icons.search_rounded,
        showSearchButton: false, // لا نحتاج زر البحث في صفحة البحث
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث عن المنتجات'),
              onChanged: (v) => _doSearch(v),
            ),
            const SizedBox(height: 12),
            if (loading) const LinearProgressIndicator(),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.68, crossAxisSpacing: 10, mainAxisSpacing: 10),
                itemCount: list.length,
                itemBuilder: (_, i) => ProductCard(product: list[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
