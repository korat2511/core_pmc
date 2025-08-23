import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as path;
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../services/api_service.dart';

class FileViewer extends StatefulWidget {
  final String fileUrl;
  final String fileName;
  final String fileExtension;

  const FileViewer({
    super.key,
    required this.fileUrl,
    required this.fileName,
    required this.fileExtension,
  });

  @override
  State<FileViewer> createState() => _FileViewerState();
}

class _FileViewerState extends State<FileViewer> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading progress
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = 'Failed to load file: ${error.description}';
            });
          },
        ),
      );

    _loadFile();
  }

  void _loadFile() {
    final extension = widget.fileExtension.toLowerCase();
    String url = widget.fileUrl;

    // Ensure URL is absolute
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = '${ApiService.baseUrl}/$url';
    }

    if (extension == 'pdf') {
      // For PDFs, use Google Docs Viewer or direct PDF URL
      final googleDocsUrl = 'https://docs.google.com/viewer?url=${Uri.encodeComponent(url)}&embedded=true';
      _webViewController.loadRequest(Uri.parse(googleDocsUrl));
    } else if (extension == 'doc' || extension == 'docx') {
      // For Word documents, use Google Docs Viewer
      final googleDocsUrl = 'https://docs.google.com/viewer?url=${Uri.encodeComponent(url)}&embedded=true';
      _webViewController.loadRequest(Uri.parse(googleDocsUrl));
    } else if (extension == 'dwg') {
      // For DWG files, use Google Docs Viewer
      final googleDocsUrl = 'https://docs.google.com/viewer?url=${Uri.encodeComponent(url)}&embedded=true';
      _webViewController.loadRequest(Uri.parse(googleDocsUrl));
    } else if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension)) {
      // For images, load directly
      _webViewController.loadRequest(Uri.parse(url));
    } else {
      // For other file types, show error
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Preview not available for .$extension files';
      });
    }
  }

  Future<void> _openInExternalApp() async {
    String url = widget.fileUrl;
    
    // Ensure URL is absolute
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = '${ApiService.baseUrl}/$url';
    }

    final uri = Uri.parse(url);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        SnackBarUtils.showError(context, message: 'No app available to open this file');
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Failed to open file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.fileName,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textWhite,
        actions: [
          IconButton(
            icon: Icon(Icons.open_in_new),
            onPressed: _openInExternalApp,
            tooltip: 'Open in external app',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return _buildErrorView();
    }

    if (_isLoading) {
      return _buildLoadingView();
    }

    return WebViewWidget(controller: _webViewController);
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.primaryColor,
          ),
          SizedBox(height: 16),
          Text(
            'Loading ${widget.fileName}...',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: ResponsiveUtils.responsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.errorColor,
            ),
            SizedBox(height: 16),
            Text(
              'Unable to preview file',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openInExternalApp,
              icon: Icon(Icons.open_in_new),
              label: Text('Open in External App'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.textWhite,
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
