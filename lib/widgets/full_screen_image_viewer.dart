import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../models/task_detail_model.dart';
import '../models/unified_image_model.dart';
import '../models/api_response.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../core/utils/snackbar_utils.dart';

class FullScreenImageViewer extends StatefulWidget {
  final List<UnifiedImageModel> images;
  final int initialIndex;
  final Function(int)? onImageDeleted;
  final List<UnifiedImageModel> Function()? getCurrentImages; // Callback to get current images

  const FullScreenImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
    this.onImageDeleted,
    this.getCurrentImages,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}



class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  List<UnifiedImageModel> _currentImages = [];



  @override
  void didUpdateWidget(FullScreenImageViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.images != oldWidget.images) {
      setState(() {
        _currentImages = List.from(widget.images);
        if (_currentIndex >= _currentImages.length && _currentImages.isNotEmpty) {
          _currentIndex = _currentImages.length - 1;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _currentImages = List.from(widget.images);
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentImages = widget.getCurrentImages?.call() ?? _currentImages;

    if (_currentIndex >= currentImages.length && currentImages.isNotEmpty) {
      _currentIndex = currentImages.length - 1;
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header with close button, centered counter, and delete button
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  Spacer(),
                  // Centered counter
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      currentImages.isEmpty ? '0 / 0' : '${_currentIndex + 1} / ${currentImages.length}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Spacer(),
                  // Delete button (only show if user has permission)
                  GestureDetector(
                    onTap: currentImages.isEmpty ? null : () => _showDeleteConfirmation(),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: currentImages.isEmpty ? Colors.grey.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Image viewer
            Expanded(
              child: currentImages.isEmpty
                  ? Center(
                      child: Text(
                        'No images available',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      itemCount: currentImages.length,
                      itemBuilder: (context, index) {
                        final image = currentImages[index];
                  return GestureDetector(
                    onTap: () {
                      // Optional: Hide/show header on tap
                    },
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 3.0,
                      child: Center(
                        child: Image.network(
                          image.imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[800],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    color: Colors.white,
                                    size: 64,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Failed to load image',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[800],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom info with uploader name and date
            if (currentImages.isNotEmpty)
              Row(
                children: [
                  SizedBox(width: 20,),
                  Icon(
                    Icons.access_time,
                    color: Colors.white.withOpacity(0.7),
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    _formatDate(currentImages[_currentIndex].createdAt),
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];

      final month = months[date.month - 1];
      final day = date.day;
      final year = date.year;

      return '$month $day, $year';
    } catch (e) {
      return dateString;
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            'Delete Image',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this image? This action cannot be undone.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteImage();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorColor,
                foregroundColor: AppColors.textWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Delete',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteImage() async {
    // Get current images from callback or local state
    final currentImages = widget.getCurrentImages?.call() ?? _currentImages;
    if (currentImages.isEmpty) return;

    final currentImage = currentImages[_currentIndex];

    try {
      final String? apiToken = await LocalStorageService.getToken();
      if (apiToken == null) {
        SnackBarUtils.showError(context, message: 'Authentication token not found');
        return;
      }

      ApiResponse? response;

      // Call appropriate API based on image source
      if (currentImage.source == ImageSource.taskImage) {
        response = await ApiService.deleteTaskImage(
          apiToken: apiToken,
          imageId: currentImage.id,
        );
      } else if (currentImage.source == ImageSource.progressImage) {
        response = await ApiService.deleteTaskProgressImage(
          apiToken: apiToken,
          imageId: currentImage.id,
        );
      }

      if (response != null && response.status == 1) {
        SnackBarUtils.showSuccess(context, message: 'Image deleted successfully');

        // Notify parent about deletion
        if (widget.onImageDeleted != null) {
          widget.onImageDeleted!(_currentIndex);
        }

        // Force rebuild to get updated image list
        setState(() {});

        // Handle navigation after deletion
        _handleNavigationAfterDeletion();
      } else {
        SnackBarUtils.showError(context, message: response?.message ?? 'Failed to delete image');
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Failed to delete image: $e');
    }
  }

  void _handleNavigationAfterDeletion() {

    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {});


        final updatedImages = widget.getCurrentImages?.call() ?? _currentImages;
        final totalImages = updatedImages.length;

        if (totalImages == 0) {
          Navigator.of(context).pop();
        } else if (totalImages == 1) {
          Navigator.of(context).pop();
        } else if (_currentIndex >= totalImages) {
          _currentIndex = totalImages - 1;
          if (_pageController.hasClients) {
            _pageController.animateToPage(
              _currentIndex,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        } else {
          if (_pageController.hasClients) {
            _pageController.animateToPage(
              _currentIndex,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
      }
    });
  }

}
