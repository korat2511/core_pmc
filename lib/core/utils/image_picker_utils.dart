import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;

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

    // Dismiss keyboard before showing dialog
    FocusScope.of(context).unfocus();
    
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
        // Dismiss keyboard before showing dialog
        FocusScope.of(context).unfocus();
        
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

  /// Get image dimensions
  static Future<Size?> getImageDimensions(File file) async {
    try {
      final Uint8List bytes = await file.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final int width = frameInfo.image.width;
      final int height = frameInfo.image.height;
      frameInfo.image.dispose();
      return width > 0 && height > 0
          ? Size(width.toDouble(), height.toDouble())
          : null;
    } catch (e) {
      debugPrint('Error getting image dimensions: $e');
      return null;
    }
  }

  /// Check if image dimensions are within limit
  static Future<bool> isImageDimensionValid(File file, {int maxWidth = 512, int maxHeight = 512}) async {
    try {
      final Size? dimensions = await getImageDimensions(file);
      if (dimensions == null) return false;
      return dimensions.width <= maxWidth && dimensions.height <= maxHeight;
    } catch (e) {
      debugPrint('Error validating image dimensions: $e');
      return false;
    }
  }

  /// Check if image aspect ratio is valid (for company logo: 3.8:1)
  static Future<bool> isImageAspectRatioValid(
    File file, {
    double targetRatio = 3.8,
    double tolerance = 0.1,
  }) async {
    try {
      final Size? dimensions = await getImageDimensions(file);
      if (dimensions == null) return false;
      
      if (dimensions.height <= 0) return false;
      
      final double aspectRatio = dimensions.width / dimensions.height;
      final double difference = (aspectRatio - targetRatio).abs();
      
      return difference <= tolerance;
    } catch (e) {
      debugPrint('Error validating image aspect ratio: $e');
      return false;
    }
  }

  /// Get image aspect ratio
  static Future<double?> getImageAspectRatio(File file) async {
    try {
      final Size? dimensions = await getImageDimensions(file);
      if (dimensions == null || dimensions.height <= 0) return null;
      return dimensions.width / dimensions.height;
    } catch (e) {
      debugPrint('Error getting image aspect ratio: $e');
      return null;
    }
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

  /// Compress image to target size (in KB) by reducing quality and dimensions
  static Future<File?> compressImageToSize(
    File file, {
    double maxSizeInKB = 512.0,
  }) async {
    try {
      final double currentSizeKB = getImageSizeInMB(file) * 1024;
      
      // If already under limit, return as is
      if (currentSizeKB <= maxSizeInKB) {
        return file;
      }

      // Read image bytes
      final Uint8List bytes = await file.readAsBytes();
      
      // Decode image using image package
      img.Image? decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) {
        debugPrint('Failed to decode image');
        return file;
      }

      // Get original dimensions
      int originalWidth = decodedImage.width;
      int originalHeight = decodedImage.height;

      // Calculate target dimensions based on size ratio
      // More aggressive scaling for larger files
      double scaleFactor = 1.0;
      if (currentSizeKB > maxSizeInKB * 10) {
        scaleFactor = 0.2; // Very large - reduce to 20%
      } else if (currentSizeKB > maxSizeInKB * 8) {
        scaleFactor = 0.25; // Very large - reduce to 25%
      } else if (currentSizeKB > maxSizeInKB * 5) {
        scaleFactor = 0.3; // Large - reduce to 30%
      } else if (currentSizeKB > maxSizeInKB * 3) {
        scaleFactor = 0.4; // Medium-large - reduce to 40%
      } else if (currentSizeKB > maxSizeInKB * 2) {
        scaleFactor = 0.6; // Medium - reduce to 60%
      } else {
        scaleFactor = 0.75; // Slightly over - reduce to 75%
      }

      int targetWidth = (originalWidth * scaleFactor).round();
      int targetHeight = (originalHeight * scaleFactor).round();

      // Resize image
      img.Image resizedImage = img.copyResize(
        decodedImage,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.linear,
      );

      // Try different quality levels iteratively
      List<int> qualityLevels = [70, 60, 50, 40, 30, 20];
      File? bestCompressedFile;
      double bestSize = double.infinity;

      for (int quality in qualityLevels) {
        // Encode as JPEG with quality
        final List<int> compressedBytes = img.encodeJpg(resizedImage, quality: quality);
        
        // Create temp file
        final String tempPath = '${file.path}_compressed_${DateTime.now().millisecondsSinceEpoch}_q$quality.jpg';
        final File tempFile = File(tempPath);
        await tempFile.writeAsBytes(compressedBytes);

        final double tempSizeKB = getImageSizeInMB(tempFile) * 1024;

        // If this is the best so far and under limit, keep it
        if (tempSizeKB <= maxSizeInKB && tempSizeKB < bestSize) {
          // Delete previous best if exists
          if (bestCompressedFile != null && bestCompressedFile.existsSync()) {
            try {
              await bestCompressedFile.delete();
            } catch (e) {
              debugPrint('Error deleting temp file: $e');
            }
          }
          bestCompressedFile = tempFile;
          bestSize = tempSizeKB;
        } else if (tempSizeKB < bestSize) {
          // Even if over limit, keep the smallest one
          if (bestCompressedFile != null && bestCompressedFile.existsSync()) {
            try {
              await bestCompressedFile.delete();
            } catch (e) {
              debugPrint('Error deleting temp file: $e');
            }
          }
          bestCompressedFile = tempFile;
          bestSize = tempSizeKB;
        } else {
          // This one is worse, delete it
          try {
            await tempFile.delete();
          } catch (e) {
            debugPrint('Error deleting temp file: $e');
          }
        }

        // If we found a good compression, we can stop early
        if (tempSizeKB <= maxSizeInKB) {
          break;
        }
      }

      if (bestCompressedFile != null) {
        final double finalSizeKB = getImageSizeInMB(bestCompressedFile) * 1024;
        if (finalSizeKB > maxSizeInKB) {
          debugPrint('Compressed image still ${finalSizeKB.toStringAsFixed(2)} KB, target: $maxSizeInKB KB');
          
          // If still too large, try even more aggressive compression
          if (finalSizeKB > maxSizeInKB * 2) {
            // Resize even more aggressively
            int targetWidth = (resizedImage.width * 0.5).round();
            int targetHeight = (resizedImage.height * 0.5).round();
            final img.Image ultraResized = img.copyResize(
              decodedImage,
              width: targetWidth,
              height: targetHeight,
              interpolation: img.Interpolation.linear,
            );
            
            // Try very low quality
            for (int quality in [10, 8, 5]) {
              final List<int> ultraBytes = img.encodeJpg(ultraResized, quality: quality);
              final String ultraPath = '${file.path}_ultra_compressed_${DateTime.now().millisecondsSinceEpoch}_q$quality.jpg';
              final File ultraFile = File(ultraPath);
              await ultraFile.writeAsBytes(ultraBytes);
              
              final double ultraSizeKB = getImageSizeInMB(ultraFile) * 1024;
              if (ultraSizeKB <= maxSizeInKB) {
                // Delete old best file
                if (bestCompressedFile != null && bestCompressedFile.existsSync()) {
                  try {
                    await bestCompressedFile.delete();
                  } catch (e) {
                    debugPrint('Error deleting temp file: $e');
                  }
                }
                debugPrint('Ultra compression successful: ${ultraSizeKB.toStringAsFixed(2)} KB');
                return ultraFile;
              } else if (ultraSizeKB < bestSize) {
                // Delete old best and keep this one
                if (bestCompressedFile != null && bestCompressedFile.existsSync()) {
                  try {
                    await bestCompressedFile.delete();
                  } catch (e) {
                    debugPrint('Error deleting temp file: $e');
                  }
                }
                bestCompressedFile = ultraFile;
                bestSize = ultraSizeKB;
              } else {
                // Delete this one, keep old best
                try {
                  await ultraFile.delete();
                } catch (e) {
                  debugPrint('Error deleting temp file: $e');
                }
              }
            }
          }
        } else {
          debugPrint('Successfully compressed image to ${finalSizeKB.toStringAsFixed(2)} KB');
        }
        return bestCompressedFile;
      }

      // Fallback: return resized image with lowest quality
      final List<int> fallbackBytes = img.encodeJpg(resizedImage, quality: 10);
      final String fallbackPath = '${file.path}_compressed_${DateTime.now().millisecondsSinceEpoch}_fallback.jpg';
      final File fallbackFile = File(fallbackPath);
      await fallbackFile.writeAsBytes(fallbackBytes);
      
      final double fallbackSizeKB = getImageSizeInMB(fallbackFile) * 1024;
      debugPrint('Using fallback compression: ${fallbackSizeKB.toStringAsFixed(2)} KB');
      
      // If fallback is still too large, try even smaller
      if (fallbackSizeKB > maxSizeInKB * 2) {
        int targetWidth = (resizedImage.width * 0.4).round();
        int targetHeight = (resizedImage.height * 0.4).round();
        final img.Image tinyResized = img.copyResize(
          decodedImage,
          width: targetWidth,
          height: targetHeight,
          interpolation: img.Interpolation.linear,
        );
        final List<int> tinyBytes = img.encodeJpg(tinyResized, quality: 5);
        final String tinyPath = '${file.path}_tiny_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final File tinyFile = File(tinyPath);
        await tinyFile.writeAsBytes(tinyBytes);
        
        // Delete fallback file
        try {
          await fallbackFile.delete();
        } catch (e) {
          debugPrint('Error deleting fallback file: $e');
        }
        
        debugPrint('Using tiny compression: ${getImageSizeInMB(tinyFile) * 1024} KB');
        return tinyFile;
      }
      
      return fallbackFile;
    } catch (e) {
      debugPrint('Error compressing image to size: $e');
      return file; // Return original on error
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

    // Dismiss keyboard before showing dialog
    FocusScope.of(context).unfocus();
    
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
