import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/meeting_model.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/snackbar_utils.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class MeetingAttachmentViewer extends StatefulWidget {
  final MeetingAttachmentModel attachment;
  final VoidCallback? onAttachmentDeleted;

  const MeetingAttachmentViewer({
    Key? key,
    required this.attachment,
    this.onAttachmentDeleted,
  }) : super(key: key);

  @override
  State<MeetingAttachmentViewer> createState() => _MeetingAttachmentViewerState();
}

class _MeetingAttachmentViewerState extends State<MeetingAttachmentViewer> {
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
    final attachmentUrl = widget.attachment.filePath;
    
    if (attachmentUrl == null || attachmentUrl.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'No attachment URL found';
        _isLoading = false;
      });
      return;
    }

    // Determine the URL to load
    String urlToLoad;
    final fileName = widget.attachment.file.split('/').last.toLowerCase();
    
    if (_isImageFile(fileName)) {
      // For images, load directly
      urlToLoad = attachmentUrl;
    } else if (_isPdfFile(fileName)) {
      // For PDFs, use Google Docs Viewer
      urlToLoad = 'https://docs.google.com/viewer?url=${Uri.encodeComponent(attachmentUrl)}&embedded=true';
    } else {
      // For other files, try to load directly
      urlToLoad = attachmentUrl;
    }

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
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
              _hasError = true;
              _errorMessage = 'Failed to load attachment: ${error.description}';
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(urlToLoad));
  }

  bool _isImageFile(String fileName) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];
    final extension = fileName.split('.').last.toLowerCase();
    return imageExtensions.contains(extension);
  }

  bool _isPdfFile(String fileName) {
    return fileName.endsWith('.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.attachment.file.split('/').last,
              style: AppTypography.titleMedium.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _getFileTypeText(),
              style: AppTypography.bodySmall.copyWith(
                color: Colors.black.withOpacity(0.7),
              ),
            ),
          ],
        ),
        actions: [
          // Open in external app button
          IconButton(
            icon: const Icon(Icons.open_in_new, color: Colors.black),
            onPressed: _openInExternalApp,
            tooltip: 'Open in external app',
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteAttachment,
            tooltip: 'Delete attachment',
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

    return _buildWebView();
  }

  Widget _buildWebView() {
    return WebViewWidget(controller: _webViewController);
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading attachment...',
            style: TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load attachment',
            style: AppTypography.titleMedium.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.black.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openInExternalApp,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open in External App'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _getFileTypeText() {
    final fileName = widget.attachment.file.split('/').last.toLowerCase();
    
    if (_isImageFile(fileName)) {
      return 'Image';
    } else if (_isPdfFile(fileName)) {
      return 'PDF Document';
    } else if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
      return 'Word Document';
    } else if (fileName.endsWith('.xls') || fileName.endsWith('.xlsx')) {
      return 'Excel Document';
    } else {
      return 'Document';
    }
  }

  Future<void> _openInExternalApp() async {
    final attachmentUrl = widget.attachment.filePath;
    
    if (attachmentUrl == null || attachmentUrl.isEmpty) {
      SnackBarUtils.showError(context, message: 'No attachment URL found');
      return;
    }

    try {
      final uri = Uri.parse(attachmentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        SnackBarUtils.showError(context, message: 'Could not open attachment in external app');
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Error opening attachment: $e');
    }
  }

  Future<void> _deleteAttachment() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Attachment'),
          content: Text('Are you sure you want to delete "${widget.attachment.file.split('/').last}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        SnackBarUtils.showError(context, message: 'Authentication token not found');
        return;
      }
      
      final response = await ApiService.deleteAttachment(
        apiToken: token,
        meetingAttachmentId: widget.attachment.id,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (response != null && response['status'] == 1) {
        // Call the callback to update the parent screen
        widget.onAttachmentDeleted?.call();
        
        // Close the viewer
        Navigator.of(context).pop();
        
        SnackBarUtils.showSuccess(context, message: 'Attachment deleted successfully');
      } else {
        SnackBarUtils.showError(context, message: response?['message'] ?? 'Failed to delete attachment');
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      SnackBarUtils.showError(context, message: 'Error deleting attachment: $e');
    }
  }
}
