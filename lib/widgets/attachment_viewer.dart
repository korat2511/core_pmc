import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/unified_attachment_model.dart';
import '../services/api_service.dart';
import 'file_viewer.dart';

class AttachmentViewer extends StatefulWidget {
  final List<UnifiedAttachmentModel> attachments;
  final int initialIndex;
  final Function(int)? onAttachmentDeleted;

  const AttachmentViewer({
    super.key,
    required this.attachments,
    required this.initialIndex,
    this.onAttachmentDeleted,
  });

  @override
  State<AttachmentViewer> createState() => _AttachmentViewerState();
}

class _AttachmentViewerState extends State<AttachmentViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / ${widget.attachments.length}',
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Delete button
          if (widget.onAttachmentDeleted != null)
            IconButton(
              onPressed: _isDeleting ? null : _deleteCurrentAttachment,
              icon: _isDeleting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.delete, color: Colors.white),
            ),
          // Close button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
      body: widget.attachments.isEmpty
          ? _buildEmptyState()
          : PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: widget.attachments.length,
              itemBuilder: (context, index) {
                final attachment = widget.attachments[index];
                return _buildAttachmentView(attachment);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.attach_file,
            size: 64,
            color: Colors.white.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            'No attachments available',
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentView(UnifiedAttachmentModel attachment) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // File Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _getAttachmentColor(attachment),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getAttachmentIcon(attachment),
                size: 60,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 24),

            // File Name
            Text(
              attachment.fileName,
              style: AppTypography.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),

            // File Extension
            Text(
              attachment.fileExtension.toUpperCase(),
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 16),

            // File Info
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Source', _getSourceText(attachment.source)),
                  SizedBox(height: 8),
                  _buildInfoRow('Created', _formatDate(attachment.createdAt)),
                  if (attachment.updatedAt != attachment.createdAt) ...[
                    SizedBox(height: 8),
                    _buildInfoRow('Updated', _formatDate(attachment.updatedAt)),
                  ],
                ],
              ),
            ),
            SizedBox(height: 32),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Download/Open Button
                ElevatedButton.icon(
                  onPressed: () => _openAttachment(attachment),
                  icon: Icon(Icons.open_in_new),
                  label: Text('Open'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(width: 16),

                // Share Button
                ElevatedButton.icon(
                  onPressed: () => _shareAttachment(attachment),
                  icon: Icon(Icons.share),
                  label: Text('Share'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getAttachmentColor(UnifiedAttachmentModel attachment) {
    // Use file extension directly for more reliable detection
    final extension = attachment.fileExtension.toLowerCase();
    
    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'txt':
      case 'rtf':
        return Colors.grey;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        return Colors.purple;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
        return Colors.red;
      case 'mp3':
      case 'wav':
      case 'aac':
        return Colors.blue;
      case 'zip':
      case 'rar':
      case '7z':
        return Colors.orange;
      default:
        return AppColors.primaryColor;
    }
  }

  IconData _getAttachmentIcon(UnifiedAttachmentModel attachment) {
    // Debug logging
    print('AttachmentViewer icon debug: ${attachment.debugInfo}');
    print('isPdf: ${attachment.isPdf}, fileExtension: ${attachment.fileExtension}');
    
    // Use file extension directly for more reliable detection
    final extension = attachment.fileExtension.toLowerCase();
    
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
      case 'rtf':
        return Icons.text_snippet;
      case 'dwg':
        return Icons.architecture;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'aac':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      default:
        print('Using default icon for extension: $extension');
        return Icons.insert_drive_file;
    }
  }

  String _getSourceText(AttachmentSource source) {
    switch (source) {
      case AttachmentSource.taskAttachment:
        return 'Task Attachment';
      case AttachmentSource.progressAttachment:
        return 'Progress Attachment';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _openAttachment(UnifiedAttachmentModel attachment) async {
    final extension = attachment.fileExtension.toLowerCase();
    
    // Check if file type is supported for inline viewing
    final supportedExtensions = ['pdf', 'doc', 'docx', 'dwg', 'jpg', 'jpeg', 'png', 'gif', 'bmp'];
    
    if (supportedExtensions.contains(extension)) {
      // Open in FileViewer for inline viewing
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FileViewer(
            fileUrl: attachment.attachmentPath,
            fileName: attachment.fileName,
            fileExtension: attachment.fileExtension,
          ),
        ),
      );
    } else {
      // Open in external app for unsupported file types
      try {
        // Debug logging
        print('Opening attachment: ${attachment.debugInfo}');
        
        String urlString = attachment.attachmentPath;
        
        // If the path doesn't start with http/https, assume it's a relative URL and prepend the base URL
        if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
          // Remove leading slash if present
          if (urlString.startsWith('/')) {
            urlString = urlString.substring(1);
          }
          // Prepend the base URL
          urlString = '${ApiService.baseUrl}/$urlString';
        }
        
        print('Final URL: $urlString');
        
        final url = Uri.parse(urlString);
        print('Parsed URL: $url');
        
        if (await canLaunchUrl(url)) {
          print('Can launch URL, attempting to open...');
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          print('Cannot launch URL: $url');
          SnackBarUtils.showError(
            context,
            message: 'Could not open ${attachment.fileName}. Please check if you have an app installed to open ${attachment.fileExtension.toUpperCase()} files.',
          );
        }
      } catch (e) {
        print('Error opening attachment: $e');
        SnackBarUtils.showError(
          context,
          message: 'Error opening attachment: $e',
        );
      }
    }
  }

  Future<void> _shareAttachment(UnifiedAttachmentModel attachment) async {
    try {
      String urlString = attachment.attachmentPath;
      
      // If the path doesn't start with http/https, assume it's a relative URL and prepend the base URL
      if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
        // Remove leading slash if present
        if (urlString.startsWith('/')) {
          urlString = urlString.substring(1);
        }
        // Prepend the base URL
        urlString = '${ApiService.baseUrl}/$urlString';
      }
      
      final url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        SnackBarUtils.showError(
          context,
          message: 'Could not share ${attachment.fileName}',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Error sharing attachment: $e',
      );
    }
  }

  Future<void> _deleteCurrentAttachment() async {
    if (widget.onAttachmentDeleted == null) return;

    final attachment = widget.attachments[_currentIndex];
    
    setState(() {
      _isDeleting = true;
    });

    try {
      // Call the deletion callback
      widget.onAttachmentDeleted!(_currentIndex);

      // If this was the last attachment, close the viewer
      if (widget.attachments.length == 1) {
        Navigator.of(context).pop();
      } else {
        // Move to next attachment or previous if this was the last one
        final newIndex = _currentIndex >= widget.attachments.length - 1
            ? _currentIndex - 1
            : _currentIndex;
        
        if (newIndex >= 0) {
          setState(() {
            _currentIndex = newIndex;
          });
          _pageController.animateToPage(
            newIndex,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Error deleting attachment: $e',
      );
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }
}
