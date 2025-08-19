import 'dart:io';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/image_picker_utils.dart';

class CustomImagePicker extends StatelessWidget {
  final List<File> selectedImages;
  final Function(List<File>) onImagesSelected;
  final bool chooseMultiple;
  final int? maxImages;
  final double? maxWidth;
  final double? maxHeight;
  final int? imageQuality;
  final double maxSizeInMB;
  final String? title;
  final String? subtitle;
  final bool showPreview;
  final VoidCallback? onTap;

  const CustomImagePicker({
    super.key,
    required this.selectedImages,
    required this.onImagesSelected,
    this.chooseMultiple = false,
    this.maxImages,
    this.maxWidth,
    this.maxHeight,
    this.imageQuality,
    this.maxSizeInMB = 5.0,
    this.title,
    this.subtitle,
    this.showPreview = true,
    this.onTap,
  });

  Future<void> _pickImages(BuildContext context) async {
    final List<File> images = await ImagePickerUtils.pickImages(
      context: context,
      chooseMultiple: chooseMultiple,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
      maxImages: maxImages,
    );

    if (images.isNotEmpty) {
      // Validate and filter images
      List<File> validImages = [];
      for (File image in images) {
        if (ImagePickerUtils.isValidImageFile(image)) {
          if (ImagePickerUtils.isImageSizeValid(image, maxSizeInMB)) {
            validImages.add(image);
          } else {
            // Show size warning
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Image ${image.path.split('/').last} is too large. Max size: ${maxSizeInMB}MB',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        } else {
          // Show format warning
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Invalid image format: ${image.path.split('/').last}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }

      if (validImages.isNotEmpty) {
        onImagesSelected(validImages);
      }
    }
  }

  Widget _buildImagePreview(BuildContext context, File image, int index) {
    return Container(
      margin: EdgeInsets.only(
        right: ResponsiveUtils.responsiveSpacing(
          context,
          mobile: 8,
          tablet: 12,
          desktop: 16,
        ),
      ),
      child: Stack(
        children: [
          Container(
                         width: ResponsiveUtils.responsiveFontSize(
               context,
               mobile: 80,
               tablet: 100,
               desktop: 120,
             ),
             height: ResponsiveUtils.responsiveFontSize(
               context,
               mobile: 80,
               tablet: 100,
               desktop: 120,
             ),
             decoration: BoxDecoration(
               borderRadius: BorderRadius.circular(
                 ResponsiveUtils.responsiveSpacing(
                   context,
                   mobile: 8,
                   tablet: 12,
                   desktop: 16,
                 ),
               ),
               border: Border.all(
                 color: AppColors.borderColor,
                 width: 1,
               ),
             ),
             child: ClipRRect(
               borderRadius: BorderRadius.circular(
                 ResponsiveUtils.responsiveSpacing(
                   context,
                   mobile: 8,
                   tablet: 12,
                   desktop: 16,
                 ),
               ),
               child: Image.file(
                 image,
                 fit: BoxFit.cover,
                 errorBuilder: (context, error, stackTrace) {
                   return Container(
                     color: AppColors.surfaceColor,
                     child: Icon(
                       Icons.broken_image,
                       color: AppColors.textSecondary,
                       size: ResponsiveUtils.responsiveFontSize(
                         context,
                         mobile: 24,
                         tablet: 28,
                         desktop: 32,
                       ),
                     ),
                   );
                 },
               ),
             ),
           ),
           if (chooseMultiple)
             Positioned(
               top: 4,
               right: 4,
               child: GestureDetector(
                 onTap: () {
                   final List<File> newImages = List.from(selectedImages);
                   newImages.removeAt(index);
                   onImagesSelected(newImages);
                 },
                 child: Container(
                   padding: EdgeInsets.all(
                     ResponsiveUtils.responsiveSpacing(
                       context,
                       mobile: 2,
                       tablet: 4,
                       desktop: 6,
                     ),
                   ),
                   decoration: BoxDecoration(
                     color: AppColors.errorColor,
                     shape: BoxShape.circle,
                   ),
                   child: Icon(
                     Icons.close,
                     color: AppColors.textWhite,
                     size: ResponsiveUtils.responsiveFontSize(
                       context,
                       mobile: 12,
                       tablet: 14,
                       desktop: 16,
                     ),
                   ),
                 ),
               ),
             ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _pickImages(context),
      child: Container(
        width: ResponsiveUtils.responsiveFontSize(
          context,
          mobile: 80,
          tablet: 100,
          desktop: 120,
        ),
        height: ResponsiveUtils.responsiveFontSize(
          context,
          mobile: 80,
          tablet: 100,
          desktop: 120,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 8,
              tablet: 12,
              desktop: 16,
            ),
          ),
          border: Border.all(
            color: AppColors.borderColor,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              color: AppColors.primaryColor,
              size: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 24,
                tablet: 28,
                desktop: 32,
              ),
            ),
            SizedBox(
              height: ResponsiveUtils.responsiveSpacing(
                context,
                mobile: 4,
                tablet: 6,
                desktop: 8,
              ),
            ),
            Text(
              'Add Image',
              style: AppTypography.bodySmall.copyWith(
                fontSize: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 10,
                  tablet: 12,
                  desktop: 14,
                ),
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: AppTypography.titleMedium.copyWith(
              fontSize: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 16,
                tablet: 18,
                desktop: 20,
              ),
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            height: ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 8,
              tablet: 12,
              desktop: 16,
            ),
          ),
        ],
        if (subtitle != null) ...[
          Text(
            subtitle!,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 12,
                tablet: 14,
                desktop: 16,
              ),
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(
            height: ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 12,
              tablet: 16,
              desktop: 20,
            ),
          ),
        ],
        if (showPreview && selectedImages.isNotEmpty) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                                 ...selectedImages.asMap().entries.map(
                   (entry) => _buildImagePreview(context, entry.value, entry.key),
                 ),
                if (chooseMultiple && (maxImages == null || selectedImages.length < maxImages!))
                  _buildAddButton(context),
              ],
            ),
          ),
          SizedBox(
            height: ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 12,
              tablet: 16,
              desktop: 20,
            ),
          ),
        ] else ...[
          _buildAddButton(context),
        ],
        if (maxImages != null && chooseMultiple) ...[
          SizedBox(
            height: ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 8,
              tablet: 12,
              desktop: 16,
            ),
          ),
          Text(
            '${selectedImages.length}/$maxImages images selected',
            style: AppTypography.bodySmall.copyWith(
              fontSize: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 10,
                tablet: 12,
                desktop: 14,
              ),
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
