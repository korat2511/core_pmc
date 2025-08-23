// ignore_for_file: unused_import

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/site_album_model.dart';

import '../services/site_album_service.dart';
import '../widgets/folder_card.dart';
import '../widgets/content_item_card.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/dismiss_keyboard.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/snackbar_utils.dart';
import '../services/session_manager.dart';
import '../core/utils/navigation_utils.dart';
import '../core/utils/image_picker_utils.dart';
import '../widgets/full_screen_folder_image_viewer.dart';
import '../widgets/full_screen_attachment_viewer.dart';

// Model for uploading items
class UploadingItem {
  final String fileName;
  final String filePath;
  final bool isImage;
  final DateTime uploadStartTime;
  final String? errorMessage;
  final bool isUploading;

  UploadingItem({
    required this.fileName,
    required this.filePath,
    required this.isImage,
    required this.uploadStartTime,
    this.errorMessage,
    this.isUploading = true,
  });

  UploadingItem copyWith({
    String? fileName,
    String? filePath,
    bool? isImage,
    DateTime? uploadStartTime,
    String? errorMessage,
    bool? isUploading,
  }) {
    return UploadingItem(
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      isImage: isImage ?? this.isImage,
      uploadStartTime: uploadStartTime ?? this.uploadStartTime,
      errorMessage: errorMessage ?? this.errorMessage,
      isUploading: isUploading ?? this.isUploading,
    );
  }
}

class SiteAlbumScreen extends StatefulWidget {
  final int siteId;
  final String siteName;

  const SiteAlbumScreen({
    Key? key,
    required this.siteId,
    required this.siteName,
  }) : super(key: key);

  @override
  State<SiteAlbumScreen> createState() => _SiteAlbumScreenState();
}

class _SiteAlbumScreenState extends State<SiteAlbumScreen> {
  final SiteAlbumService _albumService = SiteAlbumService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _folderNameController = TextEditingController();
  final TextEditingController _editFolderNameController =
      TextEditingController();

  List<SiteAlbumModel> _displayedFolders = [];
  List<SiteAlbumModel> _folderPath = [];
  SiteAlbumModel? _currentFolder;
  String _searchQuery = '';
  bool _isAddingFolder = false;
  bool _isEditingFolder = false;
  bool _isDeletingFolder = false;
  bool _isUploadingImages = false;
  bool _isUploadingAttachments = false;

  // List to track uploading items
  List<UploadingItem> _uploadingItems = [];

  // Timer for upload progress simulation
  Timer? _uploadProgressTimer;

  @override
  void initState() {
    super.initState();
    _clearOldUploadingItems();
    _loadSiteAlbums();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _folderNameController.dispose();
    _editFolderNameController.dispose();
    _uploadProgressTimer?.cancel();
    super.dispose();
  }

  // Clear old uploading items (older than 5 minutes)
  void _clearOldUploadingItems() {
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
    setState(() {
      _uploadingItems.removeWhere(
        (item) =>
            item.uploadStartTime.isBefore(fiveMinutesAgo) && !item.isUploading,
      );
    });
  }

  Future<void> _loadSiteAlbums() async {
    final success = await _albumService.getSiteAlbumList(widget.siteId);

    if (success) {
      setState(() {
        _displayedFolders = _albumService.mainFolders;
        _currentFolder = null;
        _folderPath.clear();
      });
    } else {
      if (mounted) {
        // Check for session expiration
        if (_albumService.errorMessage?.contains('Session expired') == true) {
          await SessionManager.handleSessionExpired(context);
        } else {
          SnackBarUtils.showError(
            context,
            message: _albumService.errorMessage ?? 'Failed to load albums',
          );
        }
      }
    }
  }

  Future<void> _refreshWithContext() async {
    // Store current context
    final currentFolderId = _currentFolder?.id;
    final currentFolderPath = List<int>.from(_folderPath.map((f) => f.id));

    final success = await _albumService.getSiteAlbumList(widget.siteId);

    if (success) {
      setState(() {
        if (currentFolderId != null) {
          // Restore the folder context
          _currentFolder = _albumService.getFolderById(currentFolderId);
          if (_currentFolder != null) {
            _displayedFolders = _currentFolder!.children;

            // Restore the folder path
            _folderPath.clear();
            for (final folderId in currentFolderPath) {
              final folder = _albumService.getFolderById(folderId);
              if (folder != null) {
                _folderPath.add(folder);
              }
            }
          } else {
            // If current folder not found, go back to main folders
            _displayedFolders = _albumService.mainFolders;
            _currentFolder = null;
            _folderPath.clear();
          }
        } else {
          // If no current folder, stay at main folders
          _displayedFolders = _albumService.mainFolders;
          _currentFolder = null;
          _folderPath.clear();
        }
      });
    } else {
      if (mounted) {
        // Check for session expiration
        if (_albumService.errorMessage?.contains('Session expired') == true) {
          await SessionManager.handleSessionExpired(context);
        } else {
          SnackBarUtils.showError(
            context,
            message: _albumService.errorMessage ?? 'Failed to load albums',
          );
        }
      }
    }
  }

  void _navigateToFolder(SiteAlbumModel folder) {
    setState(() {
      if (_currentFolder == null) {
        // Navigating from root to a main folder
        _currentFolder = folder;
        _folderPath = [folder];
        _displayedFolders = folder.children;
      } else {
        // Navigating to a subfolder
        _folderPath.add(folder);
        _currentFolder = folder;
        _displayedFolders = folder.children;
      }
    });
  }

  void _navigateBack() {
    // Clear old uploading items when navigating
    _clearOldUploadingItems();

    if (_folderPath.isEmpty) {
      // Go back to home
      Navigator.of(context).pop();
    } else {
      setState(() {
        _folderPath.removeLast();
        if (_folderPath.isEmpty) {
          // Back to root
          _currentFolder = null;
          _displayedFolders = _albumService.mainFolders;
        } else {
          // Back to parent folder
          _currentFolder = _folderPath.last;
          _displayedFolders = _currentFolder!.children;
        }
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        if (_currentFolder == null) {
          _displayedFolders = _albumService.mainFolders;
        } else {
          _displayedFolders = _currentFolder!.children;
        }
      } else {
        // Search in current context
        if (_currentFolder == null) {
          // Search in main folders
          _displayedFolders = _albumService.searchFolders(query);
        } else {
          // Search in current folder's children and content
          final matchingFolders = _currentFolder!.children
              .where(
                (folder) => folder.albumName.toLowerCase().contains(
                  query.toLowerCase(),
                ),
              )
              .toList();

          final matchingContent = _currentFolder!.images
              .where(
                (item) =>
                    item.fileName.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();

          // For now, we'll show matching folders. In a more advanced implementation,
          // we could show both folders and content items in search results
          _displayedFolders = matchingFolders;

          // If no folders match but content does, we could show a special view
          if (matchingFolders.isEmpty && matchingContent.isNotEmpty) {
            // TODO: Show content search results
            SnackBarUtils.showInfo(
              context,
              message: 'Found ${matchingContent.length} matching files',
            );
          }
        }
      }
    });
  }

  void _viewFolderContent(SiteAlbumModel folder) async {
    // Clear old uploading items when navigating
    _clearOldUploadingItems();

    // Navigate to folder and show its contents
    setState(() {
      _currentFolder = folder;

      // Build the folder path properly
      if (_folderPath.isEmpty) {
        // First folder - add it to path
        _folderPath = [folder];
      } else {
        // Check if this folder is already in the path
        final existingIndex = _folderPath.indexWhere((f) => f.id == folder.id);
        if (existingIndex != -1) {
          // Folder already in path - navigate to that level
          _folderPath = _folderPath.sublist(0, existingIndex + 1);
        } else {
          // New folder - add to path
          _folderPath.add(folder);
        }
      }

      _displayedFolders = folder.children;
    });

    // Refresh the folder data to ensure we have the latest content
    await _refreshCurrentFolder();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: CustomAppBar(
        title: _getAppBarTitle(),
        showBackButton: true,
        onBackPressed: _handleBackButton,
      ),
      floatingActionButton: _currentFolder != null
          ? FloatingActionButton.extended(
              onPressed: () => _showUploadOptions(),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Upload',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
      body: DismissKeyboard(
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: CustomSearchBar(
                hintText: _currentFolder == null
                    ? 'Search folders...'
                    : 'Search folders and files...',
                onChanged: _onSearchChanged,
                controller: _searchController,
              ),
            ),

            // Breadcrumb
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Text(
                    'Path: ',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Home option
                          GestureDetector(
                            onTap: () {
                              // Clear old uploading items when going home
                              _clearOldUploadingItems();
                              // Navigate back to home (main albums screen)
                              setState(() {
                                _currentFolder = null;
                                _folderPath.clear();
                                _displayedFolders = _albumService.mainFolders;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _folderPath.isEmpty
                                    ? AppColors.primary
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Home',
                                style: AppTypography.bodySmall.copyWith(
                                  color: _folderPath.isEmpty
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          // Folder path
                          if (_folderPath.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            for (int i = 0; i < _folderPath.length; i++) ...[
                              if (i > 0) ...[
                                const Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      // Clear old uploading items when navigating
                                      _clearOldUploadingItems();
                                      // Navigate to this folder in the path
                                      setState(() {
                                        _folderPath = _folderPath.sublist(
                                          0,
                                          i + 1,
                                        );
                                        _currentFolder = _folderPath.last;
                                        _displayedFolders =
                                            _currentFolder!.children;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: i == _folderPath.length - 1
                                            ? AppColors.primary
                                            : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _folderPath[i].albumName,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: i == _folderPath.length - 1
                                              ? Colors.white
                                              : Colors.grey.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),

                                  if (i == _folderPath.length - 1 &&
                                      _folderPath[i].parentId != null) ...[
                                    const SizedBox(width: 4),
                                    // Edit button
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1,
                                        ),
                                      ),
                                      child: GestureDetector(
                                        onTap: () => _showEditFolderDialog(
                                          _folderPath[i],
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 4),
                                    // Delete button
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1,
                                        ),
                                      ),
                                      child: GestureDetector(
                                        onTap: _isDeletingFolder
                                            ? null
                                            : () =>
                                                  _deleteFolder(_folderPath[i]),
                                        child: _isDeletingFolder
                                            ? const SizedBox(
                                                width: 12,
                                                height: 12,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                            : const Icon(
                                                Icons.delete,
                                                size: 12,
                                                color: Colors.white,
                                              ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content List
            Expanded(
              child: _albumService.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContentList(),
            ),
          ],
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    if (_currentFolder != null) {
      return '${_currentFolder!.albumName} (${_currentFolder!.totalItems} items)';
    } else {
      return 'Site Albums';
    }
  }

  Widget _buildContentList() {
    if (_currentFolder != null) {
      // Show both subfolders and content items
      final subfolders = _currentFolder!.children;
      final contentItems = _currentFolder!.images;

      // Filter uploading items for current folder
      final uploadingItems = _uploadingItems
          .where((item) => item.isUploading || item.errorMessage != null)
          .toList();

      if (subfolders.isEmpty &&
          contentItems.isEmpty &&
          uploadingItems.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: _refreshWithContext,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            // Show subfolders first
            if (subfolders.isNotEmpty) ...[
              // Subfolders section header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Text(
                  'Folders (${subfolders.length})',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              // Subfolder grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: subfolders.length,
                itemBuilder: (context, index) {
                  final folder = subfolders[index];
                  return _buildGridFolderCard(folder);
                },
              ),
            ],

            // Show uploading items
            if (uploadingItems.isNotEmpty) ...[
              // Uploading section header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Text(
                  'Uploading (${uploadingItems.length})',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
              // Uploading items grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: uploadingItems.length,
                itemBuilder: (context, index) {
                  final item = uploadingItems[index];
                  return _buildUploadingItemCard(item);
                },
              ),
            ],

            // Show content items
            if (contentItems.isNotEmpty) ...[
              // Content section header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Text(
                  'Files (${contentItems.length})',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              // Content item grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: contentItems.length,
                itemBuilder: (context, index) {
                  final item = contentItems[index];
                  return _buildGridContentCard(item);
                },
              ),
            ],
          ],
        ),
      );
    } else {
      // Show main folders
      if (_displayedFolders.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: _refreshWithContext,
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _displayedFolders.length,
          itemBuilder: (context, index) {
            final folder = _displayedFolders[index];
            return _buildGridFolderCard(folder);
          },
        ),
      );
    }
  }

  Widget _buildGridFolderCard(SiteAlbumModel folder) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        _viewFolderContent(folder);
      },
      onLongPress: null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Folder Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _getFolderColor(folder),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getFolderIcon(folder),
                  color: Colors.white,
                  size: 18,
                ),
              ),

              const SizedBox(height: 6),

              // Folder Name
              Flexible(
                child: Text(
                  folder.albumName,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadingItemCard(UploadingItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: item.errorMessage != null
              ? Colors.red.shade300
              : Colors.orange.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // File Icon with overlay
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: item.errorMessage != null
                        ? Colors.red.shade500
                        : (item.isImage
                              ? Colors.blue.shade500
                              : Colors.orange.shade500),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        item.isImage ? Icons.image : Icons.description,
                        color: Colors.white,
                        size: 14,
                      ),
                      if (item.isUploading)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade600,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const SizedBox(
                              width: 8,
                              height: 8,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // File Name
                Flexible(
                  child: Text(
                    item.fileName,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                      color: item.errorMessage != null
                          ? Colors.red.shade700
                          : Colors.black87,
                      fontSize: 9,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Status text
                if (item.errorMessage != null)
                  Text(
                    'Failed',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.red.shade600,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Text(
                    'Uploading...',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.orange.shade600,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),

          // Error overlay with retry button
          if (item.errorMessage != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  _retryUpload(item);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade50.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.refresh,
                      color: Colors.red.shade600,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGridContentCard(SiteAlbumImage item) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        if (item.isImage) {
          _openFullScreenViewer(item);
        } else {
          _openFullScreenAttachmentViewer(item);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: item.isImage && item.imagePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imagePath!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildAttachmentCard(item);
                  },
                ),
              )
            : _buildAttachmentCard(item),
      ),
    );
  }

  Widget _buildAttachmentCard(SiteAlbumImage item) {
    return Container(
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // File Icon
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _getContentColor(item),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(_getContentIcon(item), color: Colors.white, size: 14),
          ),

          const SizedBox(height: 4),

          // File Name
          Flexible(
            child: Text(
              item.fileName,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getFolderColor(SiteAlbumModel folder) {
    if (folder.hasOnlyImages) {
      return Colors.blue.shade500;
    } else if (folder.hasOnlyAttachments) {
      return Colors.orange.shade500;
    } else if (folder.hasMixedContent) {
      return Colors.purple.shade500;
    } else if (folder.hasChildren) {
      return Colors.green.shade500;
    } else {
      return Colors.grey.shade500;
    }
  }

  IconData _getFolderIcon(SiteAlbumModel folder) {
    if (folder.hasOnlyImages) {
      return Icons.image;
    } else if (folder.hasOnlyAttachments) {
      return Icons.description;
    } else if (folder.hasMixedContent) {
      return Icons.folder_special;
    } else if (folder.hasChildren) {
      return Icons.folder_open;
    } else {
      return Icons.folder;
    }
  }

  Color _getContentColor(SiteAlbumImage item) {
    if (item.isImage) {
      return Colors.blue.shade500;
    } else if (item.isPdf) {
      return Colors.red.shade500;
    } else if (item.isExcel) {
      return Colors.green.shade500;
    } else if (item.isWord) {
      return Colors.blue.shade600;
    } else if (item.isDwg) {
      return Colors.orange.shade600;
    } else {
      return Colors.grey.shade500;
    }
  }

  IconData _getContentIcon(SiteAlbumImage item) {
    if (item.isImage) {
      return Icons.image;
    } else if (item.isPdf) {
      return Icons.picture_as_pdf;
    } else if (item.isExcel) {
      return Icons.table_chart;
    } else if (item.isWord) {
      return Icons.description;
    } else if (item.isDwg) {
      return Icons.architecture;
    } else {
      return Icons.insert_drive_file;
    }
  }

  String _getContentTypeText(SiteAlbumImage item) {
    if (item.isImage) {
      return 'Image';
    } else if (item.isPdf) {
      return 'PDF';
    } else if (item.isExcel) {
      return 'Excel';
    } else if (item.isWord) {
      return 'Word';
    } else if (item.isDwg) {
      return 'AutoCAD';
    } else {
      return 'Document';
    }
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    if (_searchQuery.isNotEmpty) {
      message = 'No folders found matching "$_searchQuery"';
      icon = Icons.search_off;
    } else if (_currentFolder != null) {
      message = 'This folder is empty';
      icon = Icons.folder_open;
    } else {
      message = 'No albums found for this site';
      icon = Icons.folder;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTypography.bodyLarge.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showEditFolderDialog(SiteAlbumModel folder) {
    _editFolderNameController.text = folder.albumName;

    showDialogWithKeyboardDismissal(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Edit Folder Name'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _editFolderNameController,
                decoration: const InputDecoration(
                  labelText: 'Folder Name',
                  border: OutlineInputBorder(),
                ),
                autofocus: false,
                onSubmitted: (value) {
                  _editFolder(folder, dialogContext);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isEditingFolder
                  ? null
                  : () {
                      _editFolder(folder, dialogContext);
                    },
              child: _isEditingFolder
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAddFolderDialog() {
    _folderNameController.clear();

    showDialogWithKeyboardDismissal(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Add New Folder',
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Create a new folder in "${_currentFolder!.albumName}"',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _folderNameController,
                decoration: InputDecoration(
                  labelText: 'Folder Name',
                  hintText: 'Enter folder name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.folder),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addFolder(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Cancel',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _isAddingFolder
                  ? null
                  : () => _addFolder(dialogContext),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: _isAddingFolder
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadImages() async {
    if (_currentFolder == null) return;

    // Check if current folder can contain images
    if (!_albumService.canContainImages(_currentFolder!.id)) {
      SnackBarUtils.showError(
        context,
        message:
            'This folder cannot contain images. Only "3d Images" and "Site Marking Data" folders can contain images.',
      );
      return;
    }

    try {
      final files = await ImagePickerUtils.pickImages(
        context: context,
        chooseMultiple: true,
        maxImages: 10,
      );

      if (files.isEmpty) return;

      // Add placeholders immediately
      setState(() {
        _isUploadingImages = true;
        for (final file in files) {
          _uploadingItems.add(
            UploadingItem(
              fileName: file.path.split('/').last,
              filePath: file.path,
              isImage: true,
              uploadStartTime: DateTime.now(),
            ),
          );
        }
      });

      final response = await _albumService.saveImages(
        siteId: widget.siteId,
        subAlbumId: _currentFolder!.id,
        images: files,
      );

      if (response.status == 1) {
        // Remove uploading placeholders
        setState(() {
          _uploadingItems.removeWhere(
            (item) =>
                item.isImage && files.any((file) => file.path == item.filePath),
          );
        });

        // Refresh the current folder data
        await _refreshCurrentFolder();

        SnackBarUtils.showSuccess(
          context,
          message: 'Images uploaded successfully!',
        );
      } else {
        // Mark uploads as failed
        setState(() {
          for (final file in files) {
            final index = _uploadingItems.indexWhere(
              (item) => item.filePath == file.path,
            );
            if (index != -1) {
              _uploadingItems[index] = _uploadingItems[index].copyWith(
                errorMessage: response.message,
                isUploading: false,
              );
            }
          }
        });

        SnackBarUtils.showError(context, message: response.message);
      }
    } catch (e) {
      // Mark all uploads as failed
      setState(() {
        for (int i = 0; i < _uploadingItems.length; i++) {
          if (_uploadingItems[i].isImage) {
            _uploadingItems[i] = _uploadingItems[i].copyWith(
              errorMessage: e.toString(),
              isUploading: false,
            );
          }
        }
      });

      SnackBarUtils.showError(
        context,
        message: 'Error uploading images: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isUploadingImages = false;
      });
    }
  }

  void _showUploadOptions() {
    if (_currentFolder == null) return;

    final canUploadImages = _albumService.canContainImages(_currentFolder!.id);
    final canUploadAttachments = _albumService.canContainAttachments(
      _currentFolder!.id,
    );

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Upload Options',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (canUploadImages) ...[
                ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text('Upload Images'),
                  subtitle: const Text('Add images to this folder'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _uploadImages();
                  },
                ),
              ],
              if (canUploadAttachments) ...[
                ListTile(
                  leading: const Icon(Icons.attach_file),
                  title: const Text('Upload Attachments'),
                  subtitle: const Text('Add documents to this folder'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _uploadAttachments();
                  },
                ),
              ],
              if (!canUploadImages && !canUploadAttachments) ...[
                const ListTile(
                  leading: Icon(Icons.info),
                  title: Text('No Upload Available'),
                  subtitle: Text('This folder type does not support uploads'),
                ),
              ],
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.create_new_folder),
                title: const Text('Create New Folder'),
                subtitle: const Text('Add a subfolder to this folder'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAddFolderDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadAttachments() async {
    if (_currentFolder == null) return;

    // Check if current folder can contain attachments
    if (!_albumService.canContainAttachments(_currentFolder!.id)) {
      SnackBarUtils.showError(
        context,
        message:
            'This folder cannot contain attachments. Only "Drawings", "Quotation", and "Agreement" folders can contain attachments.',
      );
      return;
    }

    try {
      final files = await ImagePickerUtils.pickDocumentsWithSource(
        context: context,
        maxFiles: 10,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'rtf', 'dwg'],
      );

      if (files.isEmpty) return;

      // Add placeholders immediately
      setState(() {
        _isUploadingAttachments = true;
        for (final file in files) {
          _uploadingItems.add(
            UploadingItem(
              fileName: file.path.split('/').last,
              filePath: file.path,
              isImage: false,
              uploadStartTime: DateTime.now(),
            ),
          );
        }
      });

      final response = await _albumService.saveAttachments(
        siteId: widget.siteId,
        subAlbumId: _currentFolder!.id,
        attachments: files,
      );

      if (response.status == 1) {
        // Remove uploading placeholders
        setState(() {
          _uploadingItems.removeWhere(
            (item) =>
                !item.isImage &&
                files.any((file) => file.path == item.filePath),
          );
        });

        // Refresh the current folder data
        await _refreshCurrentFolder();

        SnackBarUtils.showSuccess(
          context,
          message: 'Documents uploaded successfully!',
        );
      } else {
        // Mark uploads as failed
        setState(() {
          for (final file in files) {
            final index = _uploadingItems.indexWhere(
              (item) => item.filePath == file.path,
            );
            if (index != -1) {
              _uploadingItems[index] = _uploadingItems[index].copyWith(
                errorMessage: response.message,
                isUploading: false,
              );
            }
          }
        });

        SnackBarUtils.showError(context, message: response.message);
      }
    } catch (e) {
      // Mark all uploads as failed
      setState(() {
        for (int i = 0; i < _uploadingItems.length; i++) {
          if (!_uploadingItems[i].isImage) {
            _uploadingItems[i] = _uploadingItems[i].copyWith(
              errorMessage: e.toString(),
              isUploading: false,
            );
          }
        }
      });

      SnackBarUtils.showError(
        context,
        message: 'Error uploading documents: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isUploadingAttachments = false;
      });
    }
  }

  Future<void> _deleteFolder(SiteAlbumModel folder) async {
    // Check if it's a main folder (cannot be deleted)
    if (folder.parentId == null) {
      SnackBarUtils.showError(
        context,
        message: 'Main folders cannot be deleted',
      );
      return;
    }

    // Get folder statistics for warning message
    final folderStats = _albumService.getFolderStats(folder.id);
    final subfolderCount = folderStats['subfolders'] ?? 0;
    final imageCount = folderStats['images'] ?? 0;
    final attachmentCount = folderStats['attachments'] ?? 0;
    final totalItems = folderStats['totalItems'] ?? 0;

    // Build warning message
    String warningMessage =
        'Are you sure you want to delete "${folder.albumName}"?\n\n';
    warningMessage += 'This will permanently delete:\n';

    if (subfolderCount > 0) {
      warningMessage +=
          '• $subfolderCount subfolder${subfolderCount > 1 ? 's' : ''}\n';
    }
    if (imageCount > 0) {
      warningMessage += '• $imageCount image${imageCount > 1 ? 's' : ''}\n';
    }
    if (attachmentCount > 0) {
      warningMessage +=
          '• $attachmentCount attachment${attachmentCount > 1 ? 's' : ''}\n';
    }
    if (totalItems == 0) {
      warningMessage += '• Empty folder\n';
    }

    warningMessage += '\nThis action cannot be undone.';

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Folder'),
          content: Text(warningMessage),
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

    setState(() {
      _isDeletingFolder = true;
    });

    try {
      final response = await _albumService.deleteFolder(albumId: folder.id);

      if (response.status == 1) {
        // Refresh the entire album list to get updated data
        await _albumService.getSiteAlbumList(widget.siteId);

        // Navigate back to parent folder or home
        if (_folderPath.length > 1) {
          // Go back to parent folder
          setState(() {
            _folderPath.removeLast();
            _currentFolder = _folderPath.last;
            // Get fresh data for the current folder
            final updatedCurrentFolder = _albumService.getFolderById(
              _currentFolder!.id,
            );
            if (updatedCurrentFolder != null) {
              _currentFolder = updatedCurrentFolder;
              _displayedFolders = _currentFolder!.children;
            }
          });
        } else {
          // Go back to home
          setState(() {
            _currentFolder = null;
            _folderPath.clear();
            _displayedFolders = _albumService.mainFolders;
          });
        }

        SnackBarUtils.showSuccess(
          context,
          message: 'Folder deleted successfully!',
        );
      } else {
        SnackBarUtils.showError(context, message: response.message);
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Error deleting folder: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isDeletingFolder = false;
      });
    }
  }

  Future<void> _editFolder(
    SiteAlbumModel folder, [
    BuildContext? dialogContext,
  ]) async {
    final newName = _editFolderNameController.text.trim();

    if (newName.isEmpty) {
      SnackBarUtils.showError(context, message: 'Please enter a folder name');
      return;
    }

    if (newName == folder.albumName) {
      // No change, just close dialog
      if (dialogContext != null) {
        Navigator.of(dialogContext).pop();
      } else {
        Navigator.of(context).pop();
      }
      return;
    }

    setState(() {
      _isEditingFolder = true;
    });

    try {
      final response = await _albumService.editFolder(
        albumId: folder.id,
        newName: newName,
      );

      if (response.status == 1) {
        // Close dialog using the dialog context if provided
        if (dialogContext != null) {
          FocusScope.of(context).unfocus();
          Navigator.of(dialogContext).pop();
        } else {
          FocusScope.of(context).unfocus();
          Navigator.of(context).pop();
        }

        // Refresh the current folder to show updated data
        await _refreshCurrentFolder();

        // Show success message after dialog is closed
        if (mounted) {
          SnackBarUtils.showSuccess(
            context,
            message: 'Folder renamed successfully!',
          );
        }
      } else {
        // Show error message after dialog is closed
        if (dialogContext != null) {
          Navigator.of(dialogContext).pop();
        }
        if (mounted) {
          SnackBarUtils.showError(context, message: response.message);
        }
      }
    } catch (e) {
      // Close dialog if there's an error
      if (dialogContext != null) {
        Navigator.of(dialogContext).pop();
      }
      if (mounted) {
        SnackBarUtils.showError(
          context,
          message: 'Error renaming folder: ${e.toString()}',
        );
      }
    } finally {
      setState(() {
        _isEditingFolder = false;
      });
    }
  }

  Future<void> _addFolder([BuildContext? dialogContext]) async {
    final folderName = _folderNameController.text.trim();

    if (folderName.isEmpty) {
      SnackBarUtils.showError(context, message: 'Please enter a folder name');
      return;
    }

    setState(() {
      _isAddingFolder = true;
    });

    try {
      final response = await _albumService.saveSubFolder(
        siteId: widget.siteId,
        parentId: _currentFolder!.id,
        albumName: folderName,
      );

      if (response.status == 1) {
        // Close dialog using the dialog context if provided
        if (dialogContext != null) {
          FocusScope.of(context).unfocus();
          Navigator.of(dialogContext).pop();
        } else {
          FocusScope.of(context).unfocus();
          Navigator.of(context).pop();
        }

        // Refresh the entire album list to get updated data
        await _refreshCurrentFolder();

        // Show success message after dialog is closed
        if (mounted) {
          SnackBarUtils.showSuccess(
            context,
            message: 'Folder created successfully!',
          );
        }
      } else {
        // Show error message after dialog is closed
        if (dialogContext != null) {
          Navigator.of(dialogContext).pop();
        }
        if (mounted) {
          SnackBarUtils.showError(context, message: response.message);
        }
      }
    } catch (e) {
      // Close dialog if there's an error
      if (dialogContext != null) {
        Navigator.of(dialogContext).pop();
      }
      if (mounted) {
        SnackBarUtils.showError(
          context,
          message: 'Error creating folder: ${e.toString()}',
        );
      }
    } finally {
      setState(() {
        _isAddingFolder = false;
      });
    }
  }

  Future<void> _refreshCurrentFolder() async {
    // Reload the entire album list
    final success = await _albumService.getSiteAlbumList(widget.siteId);

    if (success) {
      setState(() {
        if (_currentFolder != null) {
          // Update the current folder reference with fresh data
          final updatedCurrentFolder = _albumService.getFolderById(
            _currentFolder!.id,
          );
          if (updatedCurrentFolder != null) {
            _currentFolder = updatedCurrentFolder;
            _displayedFolders = _currentFolder!.children;

            // Update folder path with fresh data but preserve the current structure
            _updateFolderPath();
          }
        } else {
          _displayedFolders = _albumService.mainFolders;
        }
      });
    }
  }

  void _updateFolderPath() {
    if (_currentFolder != null) {
      _folderPath = _albumService.getFolderPath(_currentFolder!.id);
    }
  }

  // Helper method to close dialog and dismiss keyboard
  void _closeDialogAndDismissKeyboard(BuildContext? dialogContext) {
    FocusScope.of(context).unfocus();
    if (dialogContext != null) {
      Navigator.of(dialogContext).pop();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _retryUpload(UploadingItem item) async {
    // Remove the failed item from the list
    setState(() {
      _uploadingItems.removeWhere(
        (uploadingItem) => uploadingItem.filePath == item.filePath,
      );
    });

    // Re-upload the file
    if (item.isImage) {
      // For images, we need to recreate the file from the path
      // This is a simplified retry - in a real app you might want to store the actual file
      SnackBarUtils.showInfo(
        context,
        message: 'Please select the file again to retry upload',
      );
    } else {
      // For attachments, same approach
      SnackBarUtils.showInfo(
        context,
        message: 'Please select the file again to retry upload',
      );
    }
  }

  void _openFullScreenViewer(SiteAlbumImage item) {
    if (!item.isImage) {
      // For non-image files, show a message or open in external app
      SnackBarUtils.showInfo(
        context,
        message: 'Opening ${item.fileName} in external app...',
      );
      return;
    }

    // Get folders with the same parent ID as the current folder
    List<SiteAlbumModel> foldersWithSameParent = [];

    if (_currentFolder != null) {
      final currentParentId = _currentFolder!.parentId;

      if (currentParentId != null) {
        // Get all folders with the same parent ID that have images
        foldersWithSameParent = _albumService.allAlbums
            .where(
              (folder) =>
                  folder.parentId == currentParentId &&
                  folder.images.isNotEmpty,
            )
            .toList();
      } else {
        // If current folder is a main folder (no parent), show only the current folder
        if (_currentFolder!.images.isNotEmpty) {
          foldersWithSameParent = [_currentFolder!];
        }
      }
    } else {
      // If no current folder, this shouldn't happen but handle gracefully
      SnackBarUtils.showError(context, message: 'No folder context found');
      return;
    }

    if (foldersWithSameParent.isEmpty) {
      SnackBarUtils.showError(context, message: 'No images found');
      return;
    }

    // Find the folder and image index
    int folderIndex = -1;
    int imageIndex = -1;

    for (int i = 0; i < foldersWithSameParent.length; i++) {
      final folder = foldersWithSameParent[i];
      final imageIndexInFolder = folder.images.indexWhere(
        (img) => img.id == item.id,
      );
      if (imageIndexInFolder != -1) {
        folderIndex = i;
        imageIndex = imageIndexInFolder;
        break;
      }
    }

    if (folderIndex == -1 || imageIndex == -1) {
      SnackBarUtils.showError(
        context,
        message: 'Image not found in any folder',
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenFolderImageViewer(
          folders: foldersWithSameParent,
          initialFolderIndex: folderIndex,
          initialImageIndex: imageIndex,
          siteId: widget.siteId,
          onImageDeleted: _handleImageDeleted,
        ),
      ),
    );
  }

  void _handleImageDeleted(int folderIndex, int imageIndex) {
    // Refresh the current folder to reflect the deletion
    _refreshCurrentFolder();

    SnackBarUtils.showSuccess(context, message: 'Image deleted successfully');
  }

  void _openFullScreenAttachmentViewer(SiteAlbumImage item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenAttachmentViewer(
          attachment: item,
          siteId: widget.siteId,
          onAttachmentDeleted: () {
            // Refresh the current folder to reflect the deletion
            _refreshCurrentFolder();
          },
        ),
      ),
    );
  }

  void _handleBackButton() {
    // Clear old uploading items when navigating
    _clearOldUploadingItems();

    if (_folderPath.isNotEmpty) {
      // Remove the current folder from the path
      _folderPath.removeLast();

      if (_folderPath.isNotEmpty) {
        // Navigate to the previous folder in the path
        final previousFolder = _folderPath.last;
        setState(() {
          _currentFolder = previousFolder;
          _displayedFolders = previousFolder.children;
        });

        // Refresh the folder data
        _refreshCurrentFolder();
      } else {
        // Navigate back to home (main albums screen)
        setState(() {
          _currentFolder = null;
          _displayedFolders = _albumService.mainFolders;
        });
      }
    } else {
      // If no folder path, just pop the screen
      Navigator.of(context).pop();
    }
  }
}
