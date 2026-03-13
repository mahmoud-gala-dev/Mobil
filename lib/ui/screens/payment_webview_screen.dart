import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// صفحة WebView لعرض بوابة الدفع MyFatoorah
class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final int orderId;
  final int transactionId;
  final String? callbackBaseUrl;

  const PaymentWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.orderId,
    required this.transactionId,
    this.callbackBaseUrl,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _loadingProgress = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            setState(() {
              _loadingProgress = progress / 100;
            });
          },
          onPageStarted: (url) {
            print('[PaymentWebView] Page started: $url');
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (url) {
            print('[PaymentWebView] Page finished: $url');
            setState(() => _isLoading = false);
            _checkForCallback(url);
          },
          onWebResourceError: (error) {
            print('[PaymentWebView] Error: ${error.description}');
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          },
          onNavigationRequest: (request) {
            print('[PaymentWebView] Navigation request: ${request.url}');

            // التحقق من callback URLs
            if (_isCallbackUrl(request.url)) {
              _handleCallback(request.url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  bool _isCallbackUrl(String url) {
    // التحقق من URLs المعروفة للـ callback
    return url.contains('/payments/myfatoorah/callback') ||
           url.contains('/payments/myfatoorah/error') ||
           url.contains('/payment/result') ||
           url.contains('paymentId=');
  }

  void _checkForCallback(String url) {
    if (_isCallbackUrl(url)) {
      _handleCallback(url);
    }
  }

  void _handleCallback(String url) {
    print('[PaymentWebView] Handling callback: $url');

    final uri = Uri.parse(url);
    final result = uri.queryParameters['result'] ??
        (url.contains('callback') ? 'success' : 'error');
    final orderId = uri.queryParameters['orderId'] ??
        widget.orderId.toString();
    final txId = uri.queryParameters['tx'] ??
        widget.transactionId.toString();
    final error = uri.queryParameters['err'];

    // الانتقال لصفحة النتيجة
    context.go(
      '/payment/result'
      '?result=$result'
      '&orderId=$orderId'
      '&tx=$txId'
      '${error != null ? '&err=$error' : ''}',
    );
  }

  Future<bool> _onWillPop() async {
    // عرض تأكيد قبل الخروج
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء الدفع؟'),
        content: const Text(
          'هل أنت متأكد من إلغاء عملية الدفع؟\n'
          'يمكنك المحاولة مرة أخرى لاحقاً.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('متابعة الدفع'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      if (mounted) {
        context.go(
          '/payment/result'
          '?result=error'
          '&orderId=${widget.orderId}'
          '&tx=${widget.transactionId}'
          '&err=user_cancelled',
        );
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _onWillPop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Image.network(
                'https://www.myfatoorah.com/images/logo.png',
                height: 24,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),
              const Text('الدفع الآمن'),
            ],
          ),
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _onWillPop,
          ),
          bottom: _isLoading
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(4),
                  child: LinearProgressIndicator(
                    value: _loadingProgress,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : null,
        ),
        body: _hasError
            ? _buildErrorWidget()
            : Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_isLoading && _loadingProgress < 0.3)
                    Container(
                      color: Colors.white,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('جاري تحميل صفحة الدفع...'),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
        bottomNavigationBar: _buildSecurityNotice(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'تعذّر تحميل صفحة الدفع',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'تحقق من اتصالك بالإنترنت وحاول مرة أخرى',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isLoading = true;
                });
                _controller.reload();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/checkout'),
              child: const Text('العودة للسلة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 16, color: Colors.green[700]),
          const SizedBox(width: 8),
          Text(
            'دفع آمن ومشفر عبر MyFatoorah',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
