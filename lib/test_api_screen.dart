import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'config/api_config.dart';

/// شاشة اختبار API - لتجربة الاتصال بالباك إند
/// 
/// لاستخدامها، أضف في main.dart:
/// ```dart
/// import 'test_api_screen.dart';
/// // في MaterialApp
/// home: TestApiScreen(),
/// ```

class TestApiScreen extends StatefulWidget {
  const TestApiScreen({super.key});

  @override
  State<TestApiScreen> createState() => _TestApiScreenState();
}

class _TestApiScreenState extends State<TestApiScreen> {
  final List<TestResult> _results = [];
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    // عرض معلومات التكوين تلقائياً
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showConfigDialog();
    });
  }

  void _showConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚙️ تكوين API'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('🌐 Base URL', ApiConfig.baseUrl),
              _buildInfoRow('🏷️ البيئة', ApiConfig.environmentInfo),
              _buildInfoRow('⏱️ Connection Timeout', '${ApiConfig.connectionTimeout}s'),
              _buildInfoRow('📥 Receive Timeout', '${ApiConfig.receiveTimeout}s'),
              _buildInfoRow('🔁 Max Retries', '${ApiConfig.maxRetries}'),
              _buildInfoRow('📝 Logging', ApiConfig.enableLogging ? 'مفعّل' : 'معطّل'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runTests() async {
    setState(() {
      _isRunning = true;
      _results.clear();
    });

    await _runTest('Ping Test', () async {
      final response = await ApiService.I.ping();
      return response['message'] == 'ok';
    });

    await _runTest('جلب المنتجات المميزة', () async {
      final products = await ApiService.I.featured();
      return products.isNotEmpty;
    });

    await _runTest('جلب التصنيفات', () async {
      final categories = await ApiService.I.categories();
      return categories.isNotEmpty;
    });

    await _runTest('البحث', () async {
      final results = await ApiService.I.search('test');
      return true; // حتى لو فارغة النتائج، الاستدعاء نجح
    });

    await _runTest('جلب العروض المميزة', () async {
      final offers = await ApiService.I.featuredOffers();
      return true;
    });

    await _runTest('جلب المتاجر', () async {
      final vendors = await ApiService.I.vendors();
      return true;
    });

    await _runTest('جلب المحافظات', () async {
      final governorates = await ApiService.I.governorates();
      return governorates.isNotEmpty;
    });

    await _runTest('جلب الإعدادات العامة', () async {
      final settings = await ApiService.I.getGeneralSettings();
      return settings.isNotEmpty;
    });

    setState(() => _isRunning = false);

    _showResultsDialog();
  }

  Future<void> _runTest(String name, Future<bool> Function() test) async {
    final stopwatch = Stopwatch()..start();
    try {
      final success = await test();
      stopwatch.stop();
      _addResult(TestResult(
        name: name,
        success: success,
        duration: stopwatch.elapsedMilliseconds,
        error: null,
      ));
    } catch (e) {
      stopwatch.stop();
      _addResult(TestResult(
        name: name,
        success: false,
        duration: stopwatch.elapsedMilliseconds,
        error: e.toString(),
      ));
    }
  }

  void _addResult(TestResult result) {
    setState(() => _results.add(result));
  }

  void _showResultsDialog() {
    final passed = _results.where((r) => r.success).length;
    final failed = _results.length - passed;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          failed == 0 ? '✅ جميع الاختبارات نجحت!' : '⚠️ بعض الاختبارات فشلت',
          style: TextStyle(color: failed == 0 ? Colors.green : Colors.orange),
        ),
        content: Text('نجح: $passed\nفشل: $failed'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 اختبار API'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showConfigDialog,
            tooltip: 'معلومات التكوين',
          ),
        ],
      ),
      body: Column(
        children: [
          // معلومات الاتصال
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.language, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ApiConfig.baseUrl,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  ApiConfig.environmentInfo,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          // زر تشغيل الاختبارات
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _isRunning ? null : _runTests,
              icon: _isRunning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isRunning ? 'جاري الاختبار...' : 'تشغيل الاختبارات'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),

          // نتائج الاختبارات
          Expanded(
            child: _results.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.science, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'اضغط على "تشغيل الاختبارات" للبدء',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            result.success ? Icons.check_circle : Icons.error,
                            color: result.success ? Colors.green : Colors.red,
                          ),
                          title: Text(result.name),
                          subtitle: result.error != null
                              ? Text(
                                  result.error!,
                                  style: const TextStyle(color: Colors.red, fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : Text('${result.duration}ms'),
                          trailing: result.success
                              ? const Icon(Icons.done, color: Colors.green)
                              : const Icon(Icons.close, color: Colors.red),
                        ),
                      );
                    },
                  ),
          ),

          // إحصائيات
          if (_results.isNotEmpty && !_isRunning)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(
                    'نجح',
                    _results.where((r) => r.success).length,
                    Colors.green,
                  ),
                  _buildStat(
                    'فشل',
                    _results.where((r) => !r.success).length,
                    Colors.red,
                  ),
                  _buildStat(
                    'الإجمالي',
                    _results.length,
                    Colors.blue,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}

class TestResult {
  final String name;
  final bool success;
  final int duration;
  final String? error;

  TestResult({
    required this.name,
    required this.success,
    required this.duration,
    this.error,
  });
}

