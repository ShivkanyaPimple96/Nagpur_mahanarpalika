import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class CertificateWebViewScreen extends StatefulWidget {
  final String url;

  CertificateWebViewScreen({required this.url});

  @override
  _CertificateWebViewScreenState createState() =>
      _CertificateWebViewScreenState();
}

class _CertificateWebViewScreenState extends State<CertificateWebViewScreen> {
  late InAppWebViewController webViewController;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Center(
            child: Text(
              'View Certificate',
              style: TextStyle(
                color: Colors.white, // White text color for contrast
                fontSize: 22, // Font size for the title
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 27, 107, 212),
        ),
        body: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(widget.url)),
          onWebViewCreated: (InAppWebViewController controller) {
            webViewController = controller;
          },
          initialOptions: InAppWebViewGroupOptions(
            crossPlatform: InAppWebViewOptions(
              javaScriptEnabled: true, // Ensure JavaScript is enabled
              useOnLoadResource: true,
              mediaPlaybackRequiresUserGesture:
                  false, // Optional: Allow media playback without user gesture
            ),
          ),
          onReceivedServerTrustAuthRequest: (InAppWebViewController controller,
              URLAuthenticationChallenge challenge) async {
            return ServerTrustAuthResponse(
              action: ServerTrustAuthResponseAction.PROCEED,
            );
          },
          onLoadError: (InAppWebViewController controller, Uri? url, int code,
              String message) {
            // Handle load error
            print("Load error: $message");
          },
          onLoadHttpError: (InAppWebViewController controller, Uri? url,
              int statusCode, String description) {
            // Handle HTTP error
            print("HTTP error: $statusCode, description: $description");
          },
        ),
      ),
    );
  }
}
