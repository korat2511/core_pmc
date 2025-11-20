import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/navigation_utils.dart';
import '../models/site_gallery_image_model.dart';
import '../models/api_response.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/shimmer_widget.dart';
import 'site_gallery_full_screen_viewer.dart';

class SiteGalleryScreen extends StatefulWidget {
  final int siteId;
  final String siteName;

  const SiteGalleryScreen({
    super.key,
    required this.siteId,
    required this.siteName,
  });

  @override
  State<SiteGalleryScreen> createState() => _SiteGalleryScreenState();
}

class _SiteGalleryScreenState extends State<SiteGalleryScreen> {
  final ScrollController _scrollController = ScrollController();
  List<SiteGalleryImageModel> _images = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;
  static const int _perPage = 20;

  @override
  void initState() {
    super.initState();
    _loadGalleryImages();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Auto-load when user scrolls to 90% of the list
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9) {
      if (!_isLoadingMore && _hasMore) {
        _loadMoreImages();
      }
    }
  }

  Future<void> _loadGalleryImages({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _images = [];
      });
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String? apiToken = await LocalStorageService.getToken();
      if (apiToken == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Authentication token not found';
        });
        return;
      }

      final ApiResponse<List<SiteGalleryImageModel>> response =
          await ApiService.getSiteGallery(
        apiToken: apiToken,
        siteId: widget.siteId,
        page: 1,
        perPage: _perPage,
      );

      if (response.status == 1) {
        final newImages = response.data ?? [];
        setState(() {
          _images = newImages;
          _isLoading = false;
          _currentPage = 1;
          // If we got a full page, there might be more
          _hasMore = newImages.length >= _perPage;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response.message.isNotEmpty 
              ? response.message 
              : 'Failed to load gallery images';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading gallery: $e';
      });
    }
  }

  Future<void> _loadMoreImages() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final String? apiToken = await LocalStorageService.getToken();
      if (apiToken == null) {
        setState(() {
          _isLoadingMore = false;
        });
        return;
      }

      final int nextPage = _currentPage + 1;
      final ApiResponse<List<SiteGalleryImageModel>> response =
          await ApiService.getSiteGallery(
        apiToken: apiToken,
        siteId: widget.siteId,
        page: nextPage,
        perPage: _perPage,
      );

      if (response.status == 1) {
        final newImages = response.data ?? [];
        setState(() {
          if (newImages.isNotEmpty) {
            _images.addAll(newImages);
            _currentPage = nextPage;
            // If we got a full page, there might be more
            _hasMore = newImages.length >= _perPage;
          } else {
            _hasMore = false;
          }
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Site Gallery',
        showDrawer: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildShimmerGrid();
    }

    if (_errorMessage != null) {
      return Center(
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
              _errorMessage!,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadGalleryImages,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.textWhite,
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_images.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'No images found',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Images from site, tasks, and progress will appear here',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadGalleryImages(refresh: true),
      color: AppColors.primaryColor,
      child: _buildGalleryGrid(),
    );
  }

  Widget _buildGalleryGrid() {
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(2),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
              childAspectRatio: 1.0,
            ),
            itemCount: _images.length,
            itemBuilder: (context, index) {
        final image = _images[index];
        return GestureDetector(
          onTap: () {
            NavigationUtils.push(
              context,
              SiteGalleryFullScreenViewer(
                images: _images,
                initialIndex: index,
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  image.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.borderColor,
                      child: Icon(
                        Icons.broken_image,
                        color: AppColors.textSecondary,
                        size: 32,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return ShimmerWidget(
                      width: double.infinity,
                      height: double.infinity,
                    );
                  },
                ),
                // Gradient overlay at bottom for better visibility
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
            },
          ),
        ),
        // Load More Button or Loading Indicator
        if (_hasMore || _isLoadingMore)
          Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: _isLoadingMore
                ? Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    child: ShimmerWidget(
                      width: double.infinity,
                      height: 48,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _loadMoreImages,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.textWhite,
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Load More',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
      ],
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(2),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1.0,
      ),
      itemCount: 20, // Show 20 shimmer placeholders
      itemBuilder: (context, index) {
        return ShimmerWidget(
          width: double.infinity,
          height: double.infinity,
        );
      },
    );
  }
}

