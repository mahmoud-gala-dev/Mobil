import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';

/// أدوات مساعدة لتحسين أداء التطبيق وتجنب حظر الخيط الرئيسي
class PerformanceUtils {
  /// تنفيذ عملية ثقيلة في خيط منفصل باستخدام compute
  /// 
  /// مثال:
  /// ```dart
  /// final result = await PerformanceUtils.runInBackground(
  ///   heavyComputation,
  ///   inputData,
  /// );
  /// ```
  static Future<R> runInBackground<T, R>(
    ComputeCallback<T, R> callback,
    T message, {
    String? debugLabel,
  }) async {
    try {
      if (kDebugMode && debugLabel != null) {
        print('🔄 [Performance] تنفيذ $debugLabel في الخلفية...');
      }
      
      final result = await compute(callback, message);
      
      if (kDebugMode && debugLabel != null) {
        print('✅ [Performance] اكتمل $debugLabel');
      }
      
      return result;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ [Performance] خطأ في تنفيذ $debugLabel: $e');
        print('📋 Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// تأخير العمليات غير الحرجة حتى بعد رسم أول frame
  /// 
  /// مثال:
  /// ```dart
  /// PerformanceUtils.runAfterBuild(() {
  ///   // عمليات غير حرجة
  /// });
  /// ```
  static void runAfterBuild(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      callback();
    });
  }

  /// تأخير العمليات غير الحرجة مع تحكم في الوقت
  /// 
  /// مثال:
  /// ```dart
  /// await PerformanceUtils.runDelayed(() {
  ///   // عمليات غير حرجة
  /// }, delay: Duration(seconds: 1));
  /// ```
  static Future<void> runDelayed(
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 300),
  }) async {
    await Future.delayed(delay);
    callback();
  }

  /// تنفيذ عملية مع Timeout لتجنب الانتظار الطويل
  /// 
  /// مثال:
  /// ```dart
  /// final result = await PerformanceUtils.runWithTimeout(
  ///   () => fetchData(),
  ///   timeout: Duration(seconds: 10),
  ///   onTimeout: () => defaultData,
  /// );
  /// ```
  static Future<T> runWithTimeout<T>(
    Future<T> Function() operation, {
    required Duration timeout,
    required T Function() onTimeout,
    String? debugLabel,
  }) async {
    try {
      if (kDebugMode && debugLabel != null) {
        print('⏱️ [Performance] تنفيذ $debugLabel مع timeout ${timeout.inSeconds}s');
      }
      
      return await operation().timeout(
        timeout,
        onTimeout: () {
          if (kDebugMode && debugLabel != null) {
            print('⚠️ [Performance] $debugLabel تجاوز الوقت المحدد');
          }
          return onTimeout();
        },
      );
    } catch (e) {
      if (kDebugMode && debugLabel != null) {
        print('❌ [Performance] خطأ في $debugLabel: $e');
      }
      rethrow;
    }
  }

  /// تنفيذ عمليات متعددة بشكل متوازي
  /// 
  /// مثال:
  /// ```dart
  /// final results = await PerformanceUtils.runParallel([
  ///   () => fetchUser(),
  ///   () => fetchProducts(),
  ///   () => fetchCategories(),
  /// ]);
  /// ```
  static Future<List<T>> runParallel<T>(
    List<Future<T> Function()> operations, {
    String? debugLabel,
  }) async {
    try {
      if (kDebugMode && debugLabel != null) {
        print('🔄 [Performance] تنفيذ ${operations.length} عملية بشكل متوازي: $debugLabel');
      }
      
      final futures = operations.map((op) => op()).toList();
      final results = await Future.wait(futures);
      
      if (kDebugMode && debugLabel != null) {
        print('✅ [Performance] اكتملت جميع العمليات: $debugLabel');
      }
      
      return results;
    } catch (e) {
      if (kDebugMode && debugLabel != null) {
        print('❌ [Performance] خطأ في العمليات المتوازية: $debugLabel: $e');
      }
      rethrow;
    }
  }

  /// Debounce - تنفيذ العملية مرة واحدة بعد توقف الاستدعاءات
  /// 
  /// مثال (في State class):
  /// ```dart
  /// Timer? _debounceTimer;
  /// 
  /// void _onSearchChanged(String query) {
  ///   PerformanceUtils.debounce(
  ///     _debounceTimer,
  ///     () => performSearch(query),
  ///     duration: Duration(milliseconds: 500),
  ///   );
  /// }
  /// ```
  static Timer debounce(
    Timer? existingTimer,
    VoidCallback callback, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    existingTimer?.cancel();
    return Timer(duration, callback);
  }

  /// Throttle - تنفيذ العملية مرة واحدة في فترة زمنية محددة
  /// 
  /// مثال (في State class):
  /// ```dart
  /// DateTime? _lastCall;
  /// 
  /// void _onScroll() {
  ///   if (PerformanceUtils.throttle(_lastCall, Duration(milliseconds: 200))) {
  ///     _lastCall = DateTime.now();
  ///     loadMoreItems();
  ///   }
  /// }
  /// ```
  static bool throttle(DateTime? lastCallTime, Duration minInterval) {
    if (lastCallTime == null) return true;
    
    final now = DateTime.now();
    final difference = now.difference(lastCallTime);
    
    return difference >= minInterval;
  }

  /// قياس وقت تنفيذ عملية (للتطوير فقط)
  /// 
  /// مثال:
  /// ```dart
  /// final result = await PerformanceUtils.measure(
  ///   'fetchProducts',
  ///   () => productsService.fetchAll(),
  /// );
  /// ```
  static Future<T> measure<T>(
    String label,
    Future<T> Function() operation,
  ) async {
    if (!kDebugMode) {
      return await operation();
    }

    final stopwatch = Stopwatch()..start();
    print('⏱️ [Performance] بدء قياس: $label');

    try {
      final result = await operation();
      stopwatch.stop();
      
      final duration = stopwatch.elapsedMilliseconds;
      final emoji = duration < 100 ? '✅' : duration < 500 ? '⚠️' : '🐌';
      
      print('$emoji [Performance] $label اكتمل في ${duration}ms');
      
      return result;
    } catch (e) {
      stopwatch.stop();
      print('❌ [Performance] $label فشل بعد ${stopwatch.elapsedMilliseconds}ms: $e');
      rethrow;
    }
  }

  /// معالج عام للأخطاء مع تسجيل تفصيلي
  static Future<T?> safeExecute<T>(
    Future<T> Function() operation, {
    required String operationName,
    T? fallback,
    bool rethrowError = false,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ [Performance] خطأ في $operationName: $e');
        print('📋 Stack trace: $stackTrace');
      }
      
      if (rethrowError) {
        rethrow;
      }
      
      return fallback;
    }
  }

  /// تنظيف الذاكرة والموارد
  static void cleanup() {
    if (kDebugMode) {
      print('🧹 [Performance] تنظيف الموارد...');
    }
    
    // يمكن إضافة تنظيف إضافي هنا
  }
}

/// Extension لتسهيل استخدام compute على Future
extension FutureComputeExtension<T> on Future<T> {
  /// تنفيذ Future في خيط منفصل
  Future<T> runInBackground() async {
    return await this;
  }
}

/// Mixin لإضافة قدرات تحسين الأداء للWidgets
mixin PerformanceMixin<T extends StatefulWidget> on State<T> {
  Timer? _debounceTimer;
  DateTime? _lastThrottleTime;

  /// تنفيذ عملية مع debounce
  void debounce(VoidCallback callback, {Duration duration = const Duration(milliseconds: 300)}) {
    _debounceTimer = PerformanceUtils.debounce(_debounceTimer, callback, duration: duration);
  }

  /// تنفيذ عملية مع throttle
  void throttle(VoidCallback callback, {Duration minInterval = const Duration(milliseconds: 200)}) {
    if (PerformanceUtils.throttle(_lastThrottleTime, minInterval)) {
      _lastThrottleTime = DateTime.now();
      callback();
    }
  }

  /// تنفيذ عملية بعد البناء
  void runAfterBuild(VoidCallback callback) {
    PerformanceUtils.runAfterBuild(callback);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
