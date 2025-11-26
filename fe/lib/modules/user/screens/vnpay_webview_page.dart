// lib/modules/user/screens/vnpay_webview_page.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../constants/app_color.dart';

class VNPayWebViewPage extends StatefulWidget {
  final String paymentUrl;
  final String intentId; // ✅ DÙNG intentId

  const VNPayWebViewPage({
    Key? key,
    required this.paymentUrl,
    required this.intentId,
  }) : super(key: key);

  @override
  State<VNPayWebViewPage> createState() => _VNPayWebViewPageState();
}

class _VNPayWebViewPageState extends State<VNPayWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
            print('🔗 Page loading: $url');
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            print('✅ Page loaded: $url');
          },
          onNavigationRequest: (NavigationRequest request) {
            print('🧭 Navigation request: ${request.url}');

            // ✅ BẮT CALLBACK
            if (request.url.startsWith('myapp://payment/result')) {
              _handlePaymentResult(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _handlePaymentResult(String url) {
    final uri = Uri.parse(url);
    final success = uri.queryParameters['success'] == 'true';
    final intentId = uri.queryParameters['intentId'];

    print('🎯 Payment result received:');
    print('   Success: $success');
    print('   Intent ID: $intentId');

    // ✅ VỀ LẠI CHECKOUT với result
    Navigator.of(context).pop(success);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final confirm = await _showCancelDialog();
        if (confirm == true && mounted) {
          Navigator.of(context).pop(false);
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thanh toán VNPay'),
          backgroundColor: AppColors.primary,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final confirm = await _showCancelDialog();
              if (confirm == true && mounted) {
                Navigator.of(context).pop(false);
              }
            },
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                color: Colors.white,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 16),
                      Text(
                        'Đang tải trang thanh toán...',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showCancelDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy thanh toán?'),
        content: const Text(
          'Bạn có chắc muốn hủy thanh toán?\nBạn có thể quay lại thanh toán sau.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}