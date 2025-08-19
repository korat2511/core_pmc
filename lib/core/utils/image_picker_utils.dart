import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class ImagePickerUtils {
  static final ImagePicker _picker = ImagePicker();

  /// Pick single image from gallery
  static Future<File?> pickImageFromGallery({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality ?? 80,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Pick single image from camera
  static Future<File?> pickImageFromCamera({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality ?? 80,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      return null;
    }
  }

  /// Pick multiple images from gallery
  static Future<List<File>> pickMultipleImagesFromGallery({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? maxImages,
  }) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality ?? 80,
      );
      
      if (maxImages != null && images.length > maxImages) {
        images.removeRange(maxImages, images.length);
      }
      
      return images.map((image) => File(image.path)).toList();
    } catch (e) {
      debugPrint('Error picking multiple images from gallery: $e');
      return [];
    }
  }

  /// Show image source selection dialog
  static Future<File?> showImageSourceDialog({
    required BuildContext context,
    bool chooseMultiple = false,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? maxImages,
  }) async {
    // Check if context is still mounted
    if (!context.mounted) {
      return null;
    }

    final ImageSource? result = await showDialog<ImageSource?>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.of(dialogContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(dialogContext).pop(ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (result == null || !context.mounted) {
      return null;
    }

    if (result == ImageSource.camera) {
      return await pickImageFromCamera(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
    } else if (result == ImageSource.gallery) {
      final files = await pickMultipleImagesFromGallery(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        maxImages: 1, // Single image for this dialog
      );
      return files.isNotEmpty ? files.first : null;
    }

    return null;
  }

  /// Pick images with custom options
  static Future<List<File>> pickImages({
    required BuildContext context,
    bool chooseMultiple = false,
    ImageSource? preferredSource,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? maxImages,
  }) async {
    List<File> selectedImages = [];

    // Check if context is still mounted
    if (!context.mounted) {
      return selectedImages;
    }

    if (preferredSource != null) {
      // Use preferred source directly
      if (chooseMultiple && preferredSource == ImageSource.gallery) {
        selectedImages = await pickMultipleImagesFromGallery(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: imageQuality,
          maxImages: maxImages,
        );
      } else if (!chooseMultiple) {
        final file = preferredSource == ImageSource.camera
            ? await pickImageFromCamera(
                maxWidth: maxWidth,
                maxHeight: maxHeight,
                imageQuality: imageQuality,
              )
            : await pickImageFromGallery(
                maxWidth: maxWidth,
                maxHeight: maxHeight,
                imageQuality: imageQuality,
              );
        if (file != null) {
          selectedImages.add(file);
        }
      }
    } else {
      // Show source selection dialog
      if (chooseMultiple) {
        // For multiple images, show custom dialog
        final result = await showDialog<ImageSource?>(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Select Image Source'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Camera'),
                    onTap: () => Navigator.of(dialogContext).pop(ImageSource.camera),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Gallery'),
                    onTap: () => Navigator.of(dialogContext).pop(ImageSource.gallery),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );

        if (result == ImageSource.camera) {
          // For camera, take single photo
          final file = await pickImageFromCamera(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            imageQuality: imageQuality,
          );
          if (file != null) {
            selectedImages.add(file);
          }
        } else if (result == ImageSource.gallery) {
          // For gallery, pick multiple images
          selectedImages = await pickMultipleImagesFromGallery(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            imageQuality: imageQuality,
            maxImages: maxImages,
          );
        }
      } else {
        // For single image, use existing dialog
        final file = await showImageSourceDialog(
          context: context,
          chooseMultiple: chooseMultiple,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: imageQuality,
          maxImages: maxImages,
        );
        if (file != null) {
          selectedImages.add(file);
        }
      }
    }

    return selectedImages;
  }

  /// Get image file size in MB
  static double getImageSizeInMB(File file) {
    try {
      final int bytes = file.lengthSync();
      return bytes / (1024 * 1024);
    } catch (e) {
      return 0.0;
    }
  }

  /// Check if image size is within limit
  static bool isImageSizeValid(File file, double maxSizeInMB) {
    final double sizeInMB = getImageSizeInMB(file);
    return sizeInMB <= maxSizeInMB;
  }

  /// Compress image if needed
  static Future<File?> compressImageIfNeeded(
    File file, {
    double maxSizeInMB = 5.0,
    int quality = 80,
  }) async {
    if (isImageSizeValid(file, maxSizeInMB)) {
      return file;
    }

    try {
      // For now, return the original file
      // In a real implementation, you would compress the image here
      // using packages like flutter_image_compress
      return file;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return null;
    }
  }

  /// Validate image file
  static bool isValidImageFile(File file) {
    try {
      final String extension = file.path.split('.').last.toLowerCase();
      return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
    } catch (e) {
      return false;
    }
  }

  /// Get image file extension
  static String getImageExtension(File file) {
    try {
      return file.path.split('.').last.toLowerCase();
    } catch (e) {
      return 'jpg';
    }
  }

  /// Convert file to base64 string (for API uploads)
  static Future<String?> fileToBase64(File file) async {
    try {
      final List<int> bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      debugPrint('Error converting file to base64: $e');
      return null;
    }
  }

  /// Pick documents/files for attachments
  static Future<List<File>> pickDocuments({
    int? maxFiles,
    List<String>? allowedExtensions,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions ?? ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'rtf'],
        allowMultiple: true,
        allowCompression: false,
      );

      if (result != null && result.files.isNotEmpty) {
        List<File> files = [];
        for (var platformFile in result.files) {
          if (platformFile.path != null) {
            files.add(File(platformFile.path!));
          }
        }
        
        if (maxFiles != null && files.length > maxFiles) {
          files = files.take(maxFiles).toList();
        }
        
        return files;
      }
      return [];
    } catch (e) {
      debugPrint('Error picking documents: $e');
      return [];
    }
  }

  /// Show document picker with source selection
  static Future<List<File>> pickDocumentsWithSource({
    required BuildContext context,
    int? maxFiles,
    List<String>? allowedExtensions,
  }) async {
    // Check if context is still mounted
    if (!context.mounted) {
      return [];
    }

    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Select Document Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.folder),
                title: const Text('File Manager'),
                subtitle: const Text('Select from device storage'),
                onTap: () => Navigator.of(dialogContext).pop('file_manager'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (result == 'file_manager') {
      return await pickDocuments(
        maxFiles: maxFiles,
        allowedExtensions: allowedExtensions,
      );
    }

    return [];
  }
}
