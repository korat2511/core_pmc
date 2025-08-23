import 'dart:io';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/site_album_model.dart';
import '../services/site_album_service.dart';

class FullScreenFolderImageViewer extends StatefulWidget {
  final List<SiteAlbumModel> folders;
  final int initialFolderIndex;
  final int initialImageIndex;
  final int siteId;
  final Function(int folderIndex, int imageIndex)? onImageDeleted;

  const FullScreenFolderImageViewer({
    super.key,
    required this.folders,
    required this.initialFolderIndex,
    required this.initialImageIndex,
    required this.siteId,
    this.onImageDeleted,
  });

  @override
  State<FullScreenFolderImageViewer> createState() => _FullScreenFolderImageViewerState();
}

class _FullScreenFolderImageViewerState extends State<FullScreenFolderImageViewer> {
  late PageController _pageController;
  late int _currentFolderIndex;
  late int _currentImageIndex;
  late int _totalImages;
  late int _currentImageInFolder;
  
  // Local copy of folders to manage state
  late List<SiteAlbumModel> _folders;

  @override
  void initState() {
    super.initState();
    // Create a deep copy of folders to manage state locally
    _folders = widget.folders.map((folder) => folder.copyWith()).toList();
    
    _currentFolderIndex = widget.initialFolderIndex;
    _currentImageIndex = widget.initialImageIndex;
    _calculateTotalImages();
    _calculateCurrentImageInFolder();
    
    // Calculate the global image index across all folders
    int globalImageIndex = 0;
    for (int i = 0; i < _currentFolderIndex; i++) {
      globalImageIndex += _folders[i].images.length;
    }
    globalImageIndex += _currentImageIndex;
    
    _pageController = PageController(initialPage: globalImageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _calculateTotalImages() {
    _totalImages = _folders.fold(0, (sum, folder) => sum + folder.images.length);
  }

  void _calculateCurrentImageInFolder() {
    _currentImageInFolder = _currentImageIndex + 1;
  }

  void _updateCurrentFolderAndImage(int pageIndex) {
    int remainingImages = pageIndex;
    _currentFolderIndex = 0;
    _currentImageIndex = 0;

    for (int i = 0; i < _folders.length; i++) {
      final folderImagesCount = _folders[i].images.length;
      if (remainingImages < folderImagesCount) {
        _currentFolderIndex = i;
        _currentImageIndex = remainingImages;
        break;
      }
      remainingImages -= folderImagesCount;
    }

    _calculateCurrentImageInFolder();
  }

  void _onPageChanged(int pageIndex) {
    setState(() {
      _updateCurrentFolderAndImage(pageIndex);
    });

  }

  void _deleteCurrentImage() async {
    // Get the current image
    final currentImage = _folders[_currentFolderIndex].images[_currentImageIndex];
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Image'),
          content: Text('Are you sure you want to delete "${currentImage.fileName}"?'),
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
      // Call the API to delete the image
      final albumService = SiteAlbumService();
      final response = await albumService.deleteAlbumImage(
        siteId: widget.siteId,
        imageId: currentImage.id,
      );

      // Hide loading indicator
      Navigator.of(context).pop();

      if (response.status == 1) {
        // Success - update the UI
        if (widget.onImageDeleted != null) {
          widget.onImageDeleted!(_currentFolderIndex, _currentImageIndex);
        }
        
        // Remove the image from the current folder
        _folders[_currentFolderIndex].images.removeAt(_currentImageIndex);
        
        // Recalculate total images
        _calculateTotalImages();
        
        // If no images left, close the viewer
        if (_totalImages == 0) {
          Navigator.of(context).pop();
          return;
        }
        
        // Handle navigation after deletion
        _handleNavigationAfterDeletion();
        
        _calculateCurrentImageInFolder();
        
        // Trigger UI rebuild
        setState(() {});
        
        // Calculate new page index
        int newPageIndex = 0;
        for (int i = 0; i < _currentFolderIndex; i++) {
          newPageIndex += _folders[i].images.length;
        }
        newPageIndex += _currentImageIndex;
        
        // Animate to the new position
        _pageController.animateToPage(
          newPageIndex,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );

        // Show success message
        SnackBarUtils.showSuccess(
          context,
          message: 'Image deleted successfully',
        );
      } else {
        // Show error message
        SnackBarUtils.showError(
          context,
          message: response.message,
        );
      }
    } catch (e) {
      // Hide loading indicator
      Navigator.of(context).pop();
      
      // Show error message
      SnackBarUtils.showError(
        context,
        message: 'Error deleting image: ${e.toString()}',
      );
    }
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _folders[_currentFolderIndex].albumName,
              style: AppTypography.titleMedium.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${_currentImageInFolder + _getTotalImagesBeforeCurrentFolder()} of $_totalImages',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.black.withOpacity(0.7),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: _deleteCurrentImage,
            tooltip: 'Delete image',
          ),
        ],
      ),
      body: _buildImagePageView(),
    );
  }

  Widget _buildImagePageView() {
    // Create a list of all images from all folders
    List<SiteAlbumImage> allImages = [];
    for (final folder in _folders) {
      allImages.addAll(folder.images);
    }




    if (allImages.isEmpty) {
      return Center(
        child: Text(
          'No images available',
          style: AppTypography.bodyLarge.copyWith(
            color: Colors.black,
          ),
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemCount: allImages.length,
      itemBuilder: (context, index) {
        final image = allImages[index];
        return _buildImageView(image);
      },
    );
  }

  Widget _buildImageView(SiteAlbumImage image) {
    // For images, use imagePath (full URL), for attachments use attachmentPath (full URL)
    final imagePath = image.isImage ? image.imagePath : image.attachmentPath;
    if (imagePath == null || imagePath.isEmpty) {
      return _buildErrorView();
    }


    return Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 3.0,
        child: _isLocalImage(imagePath)
            ? Image.file(
                File(imagePath),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {

                  return _buildErrorView();
                },
              )
            : Image.network(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {

                  return _buildErrorView();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildLoadingView();
                },
              ),
      ),
    );
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
            'Loading image...',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.black,
            ),
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
            Icons.broken_image,
            size: 64,
            color: Colors.black.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            'Failed to load image',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.black.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  bool _isLocalImage(String imagePath) {
    return imagePath.startsWith('/') ||
        imagePath.startsWith('file://') ||
        !imagePath.startsWith('http');
  }

  int _getTotalImagesBeforeCurrentFolder() {
    int total = 0;
    for (int i = 0; i < _currentFolderIndex; i++) {
      total += widget.folders[i].images.length;
    }
    return total;
  }

  void _handleNavigationAfterDeletion() {
    // If current folder is empty, try to move to another folder
    if (_folders[_currentFolderIndex].images.isEmpty) {
      // Try to move to next folder
      if (_currentFolderIndex < _folders.length - 1) {
        _currentFolderIndex++;
        _currentImageIndex = 0;
        return;
      }
      // Try to move to previous folder
      if (_currentFolderIndex > 0) {
        _currentFolderIndex--;
        _currentImageIndex = _folders[_currentFolderIndex].images.length - 1;
        return;
      }
      // No other folders available, this will be handled by the total images check
      return;
    }
    
    // If current image index is out of bounds, adjust it
    if (_currentImageIndex >= _folders[_currentFolderIndex].images.length) {
      // Move to the last image in current folder
      _currentImageIndex = _folders[_currentFolderIndex].images.length - 1;
    }
  }
}
