import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../services/api_service.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';

class StaticPageScreen extends StatefulWidget {
  final String slug;
  
  const StaticPageScreen({
    super.key,
    required this.slug,
  });

  @override
  State<StaticPageScreen> createState() => _StaticPageScreenState();
}

class _StaticPageScreenState extends State<StaticPageScreen> {
  Map<String, dynamic>? _pageData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  Future<void> _loadPage() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('📄 [StaticPage] جلب الصفحة: ${widget.slug}');
      final data = await ApiService.I.getStaticPage(widget.slug);
      
      if (mounted) {
        setState(() {
          _pageData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [StaticPage] خطأ في تحميل الصفحة: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: _pageData?['title'] ?? 'صفحة',
        leadingIcon: Icons.description_outlined,
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'خطأ في تحميل الصفحة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadPage,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPage,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // العنوان
                        Text(
                          _pageData?['title'] ?? '',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        
                        // الوصف (إن وجد)
                        if (_pageData?['meta_description'] != null &&
                            _pageData!['meta_description'].toString().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            _pageData!['meta_description'],
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        
                        // المحتوى HTML
                        if (_pageData?['content'] != null)
                          Html(
                            data: _pageData!['content'],
                            style: {
                              "body": Style(
                                fontSize: FontSize(16),
                                lineHeight: const LineHeight(1.6),
                              ),
                              "h1": Style(
                                fontSize: FontSize(24),
                                fontWeight: FontWeight.bold,
                                margin: Margins(top: Margin(20), bottom: Margin(10)),
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              "h2": Style(
                                fontSize: FontSize(20),
                                fontWeight: FontWeight.bold,
                                margin: Margins(top: Margin(16), bottom: Margin(8)),
                              ),
                              "h3": Style(
                                fontSize: FontSize(18),
                                fontWeight: FontWeight.bold,
                                margin: Margins(top: Margin(12), bottom: Margin(6)),
                              ),
                              "p": Style(
                                margin: Margins(bottom: Margin(12)),
                                lineHeight: const LineHeight(1.6),
                              ),
                              "ul": Style(
                                margin: Margins(left: Margin(20), bottom: Margin(12)),
                              ),
                              "ol": Style(
                                margin: Margins(left: Margin(20), bottom: Margin(12)),
                              ),
                              "li": Style(
                                margin: Margins(bottom: Margin(6)),
                              ),
                            },
                          )
                        else
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: Text(
                                'لا يوجد محتوى لعرضه',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        
                        // Footer
                        const SizedBox(height: 40),
                        const AppFooter(),
                      ],
                    ),
                  ),
                ),
    );
  }
}
