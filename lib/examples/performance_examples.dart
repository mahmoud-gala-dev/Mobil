import 'package:flutter/material.dart';
import '../utils/performance_utils.dart';
import '../widgets/optimized_image.dart';
import '../services/shared_preferences_service.dart';

/// أمثلة عملية على استخدام الإصلاحات والتحسينات
/// 
/// هذا الملف يحتوي على أمثلة لكيفية استخدام:
/// - PerformanceUtils
/// - OptimizedImage
/// - SharedPreferencesService
/// 
/// يمكن استخدام هذه الأمثلة كمرجع عند تطوير features جديدة

class PerformanceExamplesScreen extends StatefulWidget {
  const PerformanceExamplesScreen({super.key});

  @override
  State<PerformanceExamplesScreen> createState() => _PerformanceExamplesScreenState();
}

class _PerformanceExamplesScreenState extends State<PerformanceExamplesScreen> 
    with PerformanceMixin {
  
  List<String> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // مثال 1: تأخير التهيئة غير الحرجة
    runAfterBuild(() {
      _loadNonCriticalData();
    });
  }

  /// مثال: تحميل بيانات غير حرجة بعد البناء
  Future<void> _loadNonCriticalData() async {
    // هذه البيانات ليست ضرورية لعرض الشاشة
    // لذا نحملها بعد البناء لتحسين وقت الاستجابة
    await PerformanceUtils.runDelayed(() {
      debugPrint('تحميل بيانات إضافية...');
    }, delay: const Duration(seconds: 1));
  }

  /// مثال: بحث مع Debounce لتقليل استدعاءات الـ API
  void _onSearchChanged(String query) {
    // استخدام debounce لتجنب استدعاء API مع كل حرف
    debounce(() {
      _performSearch(query);
    }, duration: const Duration(milliseconds: 500));
  }

  /// مثال: عملية بحث محسّنة مع معالجة أخطاء
  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);

    try {
      final results = await PerformanceUtils.measure(
        'البحث عن: $query',
        () => _searchInBackground(query),
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// مثال: عملية ثقيلة في الخلفية
  Future<List<String>> _searchInBackground(String query) async {
    return await PerformanceUtils.runInBackground(
      _heavySearchOperation,
      query,
      debugLabel: 'عملية البحث',
    );
  }

  /// عملية البحث الفعلية (تعمل في isolate منفصل)
  static List<String> _heavySearchOperation(String query) {
    // محاكاة عملية بحث ثقيلة
    final results = <String>[];
    for (var i = 0; i < 1000; i++) {
      if ('item_$i'.contains(query.toLowerCase())) {
        results.add('نتيجة $i');
      }
    }
    return results;
  }

  /// مثال: تحميل عدة موارد بشكل متوازي
  Future<void> _loadMultipleResources() async {
    setState(() => _isLoading = true);

    try {
      final results = await PerformanceUtils.runParallel([
        () => _loadUserProfile(),
        () => _loadProducts(),
        () => _loadCategories(),
      ], debugLabel: 'تحميل موارد متعددة');

      debugPrint('تم تحميل ${results.length} موارد بنجاح');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>> _loadUserProfile() async {
    await Future.delayed(const Duration(seconds: 1));
    return {'name': 'User', 'id': 1};
  }

  Future<List<dynamic>> _loadProducts() async {
    await Future.delayed(const Duration(seconds: 1));
    return [1, 2, 3, 4, 5];
  }

  Future<List<dynamic>> _loadCategories() async {
    await Future.delayed(const Duration(seconds: 1));
    return ['Category 1', 'Category 2'];
  }

  /// مثال: عملية مع timeout
  Future<void> _fetchWithTimeout() async {
    try {
      final data = await PerformanceUtils.runWithTimeout(
        () => _slowNetworkCall(),
        timeout: const Duration(seconds: 5),
        onTimeout: () => 'بيانات افتراضية',
        debugLabel: 'استدعاء الشبكة',
      );

      debugPrint('البيانات المستلمة: $data');
    } catch (e) {
      debugPrint('خطأ: $e');
    }
  }

  Future<String> _slowNetworkCall() async {
    await Future.delayed(const Duration(seconds: 10)); // أطول من timeout
    return 'بيانات حقيقية';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أمثلة تحسين الأداء'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            'مثال 1: البحث مع Debounce',
            _buildSearchExample(),
          ),
          const SizedBox(height: 24),
          _buildSection(
            'مثال 2: عرض صور محسّن',
            _buildImageExample(),
          ),
          const SizedBox(height: 24),
          _buildSection(
            'مثال 3: تحميل متوازي',
            _buildParallelLoadingExample(),
          ),
          const SizedBox(height: 24),
          _buildSection(
            'مثال 4: SharedPreferences',
            _buildSharedPreferencesExample(),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchExample() {
    return Column(
      children: [
        TextField(
          onChanged: _onSearchChanged,
          decoration: const InputDecoration(
            labelText: 'ابحث هنا',
            hintText: 'اكتب للبحث...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const CircularProgressIndicator()
        else if (_searchResults.isNotEmpty)
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_searchResults[index]),
                );
              },
            ),
          )
        else
          const Text('لا توجد نتائج'),
      ],
    );
  }

  Widget _buildImageExample() {
    final imageUrl = 'https://via.placeholder.com/300x200';
    
    return Column(
      children: [
        const Text(
          'استخدام OptimizedImage لعرض صورة بكفاءة:',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        OptimizedImage(
          imageUrl: imageUrl,
          width: 300,
          height: 200,
          borderRadius: BorderRadius.circular(12),
          cacheWidth: ImageCacheHelper.calculateCacheWidth(context, 300),
          cacheHeight: ImageCacheHelper.calculateCacheHeight(context, 200),
        ),
        const SizedBox(height: 12),
        const Text(
          '✅ الصورة محسّنة مع cache وتحميل تدريجي',
          style: TextStyle(
            fontSize: 12,
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildParallelLoadingExample() {
    return Column(
      children: [
        const Text(
          'تحميل عدة موارد في نفس الوقت:',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _loadMultipleResources,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download),
          label: Text(_isLoading ? 'جاري التحميل...' : 'تحميل الموارد'),
        ),
        const SizedBox(height: 12),
        const Text(
          '✅ تحميل Profile + Products + Categories بشكل متوازي',
          style: TextStyle(
            fontSize: 12,
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSharedPreferencesExample() {
    return Column(
      children: [
        const Text(
          'استخدام SharedPreferences بشكل آمن:',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _demonstrateSharedPreferences,
          child: const Text('اختبار SharedPreferences'),
        ),
        const SizedBox(height: 12),
        const Text(
          '✅ معالجة آمنة للأخطاء مع إعادة محاولة تلقائية',
          style: TextStyle(
            fontSize: 12,
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _demonstrateSharedPreferences() async {
    // حفظ بيانات
    final saved = await SharedPreferencesService.instance.setString(
      'demo_key',
      'قيمة تجريبية',
    );

    if (saved) {
      debugPrint('✅ تم حفظ البيانات');

      // قراءة بيانات
      final value = SharedPreferencesService.instance.getString('demo_key');
      debugPrint('✅ تم قراءة البيانات: $value');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ SharedPreferences يعمل! القيمة: $value'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      debugPrint('❌ فشل حفظ البيانات');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ SharedPreferences غير جاهز بعد'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}

/// مثال: Widget يستخدم Throttle لمعالجة التمرير
class ThrottledScrollWidget extends StatefulWidget {
  const ThrottledScrollWidget({super.key});

  @override
  State<ThrottledScrollWidget> createState() => _ThrottledScrollWidgetState();
}

class _ThrottledScrollWidgetState extends State<ThrottledScrollWidget>
    with PerformanceMixin {
  int _loadMoreCalls = 0;

  void _onScroll(ScrollController controller) {
    if (controller.position.pixels >= controller.position.maxScrollExtent * 0.8) {
      // استخدام throttle لتجنب استدعاء متكرر
      throttle(() {
        _loadMoreItems();
      }, minInterval: const Duration(seconds: 1));
    }
  }

  void _loadMoreItems() {
    setState(() {
      _loadMoreCalls++;
    });
    debugPrint('تحميل المزيد... (استدعاء رقم $_loadMoreCalls)');
  }

  @override
  Widget build(BuildContext context) {
    final controller = ScrollController();
    controller.addListener(() => _onScroll(controller));

    return ListView.builder(
      controller: controller,
      itemCount: 100,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('عنصر $index'),
          subtitle: Text('عدد استدعاءات loadMore: $_loadMoreCalls'),
        );
      },
    );
  }
}
