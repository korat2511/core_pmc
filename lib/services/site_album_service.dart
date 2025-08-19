import 'dart:io';
import '../models/site_album_model.dart';
import '../models/site_album_response.dart';
import '../models/api_response.dart';
import 'api_service.dart';
import 'session_manager.dart';

class SiteAlbumService {
  List<SiteAlbumModel> _allAlbums = [];
  List<SiteAlbumModel> _mainFolders = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<SiteAlbumModel> get allAlbums => _allAlbums;
  List<SiteAlbumModel> get mainFolders => _mainFolders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch site album list
  Future<bool> getSiteAlbumList(int siteId) async {
    try {
      _isLoading = true;
      _errorMessage = null;

      final response = await ApiService.getSiteAlbumList(siteId);
      
      if (response.status == 1) {
        _allAlbums = response.siteAlbum;
        _organizeAlbums();
        return true;
      } else {
        // Check for session expiration
        if (response.status == 401 || SessionManager.isSessionExpired(response.message)) {
          _errorMessage = 'Session expired. Please login again.';
          return false;
        }
        
        _errorMessage = response.message;
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
    }
  }

  // Organize albums into main folders and subfolders
  void _organizeAlbums() {
    // Get main folders (parent_id is null)
    _mainFolders = _allAlbums.where((album) => album.isMainFolder).toList();
    
    // Sort main folders by name
    _mainFolders.sort((a, b) => a.albumName.compareTo(b.albumName));
  }

  // Get subfolders for a specific parent folder
  List<SiteAlbumModel> getSubFolders(int parentId) {
    return _allAlbums
        .where((album) => album.parentId == parentId)
        .toList()
      ..sort((a, b) => a.albumName.compareTo(b.albumName));
  }

  // Get folder by ID
  SiteAlbumModel? getFolderById(int id) {
    try {
      return _allAlbums.firstWhere((album) => album.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get folder path (breadcrumb)
  List<SiteAlbumModel> getFolderPath(int folderId) {
    final path = <SiteAlbumModel>[];
    var currentFolder = getFolderById(folderId);
    
    while (currentFolder != null) {
      path.insert(0, currentFolder);
      if (currentFolder.parentId != null) {
        currentFolder = getFolderById(currentFolder.parentId!);
      } else {
        break;
      }
    }
    
    return path;
  }

  // Get all images in a folder (including subfolders)
  List<SiteAlbumImage> getAllImagesInFolder(int folderId, {bool includeSubfolders = true}) {
    final folder = getFolderById(folderId);
    if (folder == null) return [];

    final images = <SiteAlbumImage>[];
    
    // Add images from current folder
    images.addAll(folder.images);
    
    // Add images from subfolders if requested
    if (includeSubfolders) {
      for (final child in folder.children) {
        images.addAll(getAllImagesInFolder(child.id, includeSubfolders: true));
      }
    }
    
    return images;
  }

  // Get all attachments in a folder (including subfolders)
  List<SiteAlbumImage> getAllAttachmentsInFolder(int folderId, {bool includeSubfolders = true}) {
    final allImages = getAllImagesInFolder(folderId, includeSubfolders: includeSubfolders);
    return allImages.where((img) => img.isAttachment).toList();
  }

  // Search folders by name
  List<SiteAlbumModel> searchFolders(String query) {
    if (query.isEmpty) return _mainFolders;
    
    final lowercaseQuery = query.toLowerCase();
    return _allAlbums
        .where((album) => album.albumName.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  // Search content items by filename
  List<SiteAlbumImage> searchContentItems(String query, {int? folderId}) {
    if (query.isEmpty) return [];
    
    final lowercaseQuery = query.toLowerCase();
    List<SiteAlbumImage> allContent = [];
    
    if (folderId != null) {
      // Search in specific folder
      final folder = getFolderById(folderId);
      if (folder != null) {
        allContent.addAll(folder.images);
      }
    } else {
      // Search in all folders
      for (final album in _allAlbums) {
        allContent.addAll(album.images);
      }
    }
    
    return allContent
        .where((item) => item.fileName.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  // Get folder statistics
  Map<String, int> getFolderStats(int folderId) {
    final folder = getFolderById(folderId);
    if (folder == null) return {};

    final allImages = getAllImagesInFolder(folderId);
    
    return {
      'totalItems': allImages.length,
      'images': allImages.where((img) => img.isImage).length,
      'attachments': allImages.where((img) => img.isAttachment).length,
      'subfolders': folder.children.length,
    };
  }

  // Save sub-folder
  Future<ApiResponse<Map<String, dynamic>>> saveSubFolder({
    required int siteId,
    required int parentId,
    required String albumName,
  }) async {
    try {
      final response = await ApiService.saveSiteSubAlbum(
        siteId: siteId,
        parentId: parentId,
        albumName: albumName,
      );
      
      if (response.status == 1) {
        // Refresh the album list to include the new folder
        await getSiteAlbumList(siteId);
        
        // Re-organize albums after refresh
        _organizeAlbums();
      }
      
      return response;
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to save sub-folder: ${e.toString()}',
        data: null,
      );
    }
  }

  // Clear data
  void clear() {
    _allAlbums.clear();
    _mainFolders.clear();
    _errorMessage = null;
  }

  // Edit folder name
  Future<ApiResponse<Map<String, dynamic>>> editFolder({
    required int albumId,
    required String newName,
  }) async {
    try {
      final response = await ApiService.editSiteAlbum(
        albumId: albumId,
        albumName: newName,
      );
      
      if (response.status == 1) {
        // Update the folder name in local data
        final folder = _allAlbums.firstWhere(
          (album) => album.id == albumId,
          orElse: () => throw Exception('Folder not found'),
        );
        
        // Update the folder name
        final updatedFolder = folder.copyWith(albumName: newName);
        
        // Replace the folder in the list
        final index = _allAlbums.indexWhere((album) => album.id == albumId);
        if (index != -1) {
          _allAlbums[index] = updatedFolder;
        }
        
        // Update in main folders if it's a main folder
        final mainIndex = _mainFolders.indexWhere((album) => album.id == albumId);
        if (mainIndex != -1) {
          _mainFolders[mainIndex] = updatedFolder;
        }
        
        // Update in children if it's a subfolder
        for (int i = 0; i < _allAlbums.length; i++) {
          final childrenIndex = _allAlbums[i].children.indexWhere((child) => child.id == albumId);
          if (childrenIndex != -1) {
            _allAlbums[i].children[childrenIndex] = updatedFolder;
            break;
          }
        }
      }
      
      return response;
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        status: 0,
        message: 'Error editing folder: ${e.toString()}',
        data: {},
      );
    }
  }

  // Delete folder
  Future<ApiResponse<Map<String, dynamic>>> deleteFolder({
    required int albumId,
  }) async {
    try {
      final response = await ApiService.deleteSiteAlbum(
        albumId: albumId,
      );
      
      if (response.status == 1) {
        // Remove the folder from local data
        _allAlbums.removeWhere((album) => album.id == albumId);
        
        // Re-organize albums after deletion
        _organizeAlbums();
      }
      
      return response;
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        status: 0,
        message: 'Error deleting folder: ${e.toString()}',
        data: {},
      );
    }
  }

  // Save images to folder
  Future<ApiResponse<Map<String, dynamic>>> saveImages({
    required int siteId,
    required int subAlbumId,
    required List<File> images,
  }) async {
    try {
      final response = await ApiService.saveImage(
        subAlbumId: subAlbumId,
        images: images,
      );
      
      if (response.status == 1) {
        // Refresh the album list to get updated data
        await getSiteAlbumList(siteId);
      }
      
      return response;
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        status: 0,
        message: 'Error saving images: ${e.toString()}',
        data: {},
      );
    }
  }

  // Save attachments to folder
  Future<ApiResponse<Map<String, dynamic>>> saveAttachments({
    required int siteId,
    required int subAlbumId,
    required List<File> attachments,
  }) async {
    try {
      final response = await ApiService.saveAttachment(
        subAlbumId: subAlbumId,
        attachments: attachments,
      );
      
      if (response.status == 1) {
        // Refresh the album list to get updated data
        await getSiteAlbumList(siteId);
      }
      
      return response;
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        status: 0,
        message: 'Error saving attachments: ${e.toString()}',
        data: {},
      );
    }
  }

  // Check if folder can contain images
  bool canContainImages(int folderId) {
    final folder = getFolderById(folderId);
    if (folder == null) return false;
    
    // Check if it's a main folder that can contain images
    if (folder.isMainFolder) {
      final folderName = folder.albumName.toLowerCase();
      return folderName.contains('3d') || 
             folderName.contains('image') || 
             folderName.contains('site marking') ||
             folderName.contains('marking');
    }
    
    // For subfolders, check the parent folder
    if (folder.parentId != null) {
      return canContainImages(folder.parentId!);
    }
    
    return false;
  }

  // Check if folder can contain attachments
  bool canContainAttachments(int folderId) {
    final folder = getFolderById(folderId);
    if (folder == null) return false;
    
    // Check if it's a main folder that can contain attachments
    if (folder.isMainFolder) {
      final folderName = folder.albumName.toLowerCase();
      return folderName.contains('drawing') || 
             folderName.contains('quotation') || 
             folderName.contains('agreement');
    }
    
    // For subfolders, check the parent folder
    if (folder.parentId != null) {
      return canContainAttachments(folder.parentId!);
    }
    
    return false;
  }
}
