import 'package:flutter/material.dart';
import '../models/site_album_model.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';

class ContentItemCard extends StatelessWidget {
  final SiteAlbumImage item;
  final VoidCallback? onTap;

  const ContentItemCard({
    Key? key,
    required this.item,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Content Icon/Thumbnail
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getContentColor(),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: item.isImage && item.imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.imagePath!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              _getContentIcon(),
                              color: Colors.white,
                              size: 24,
                            );
                          },
                        ),
                      )
                    : Icon(
                        _getContentIcon(),
                        color: Colors.white,
                        size: 24,
                      ),
              ),
              
              const SizedBox(width: 12),
              
              // Content Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // File Name
                    Text(
                      item.fileName,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // File Type and Size
                    Row(
                      children: [
                        Icon(
                          _getContentIcon(),
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getContentTypeText(),
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (item.createdAt != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(item.createdAt!),
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action Icon
              Icon(
                Icons.open_in_new,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getContentColor() {
    if (item.isImage) {
      return Colors.blue.shade500;
    } else if (item.isPdf) {
      return Colors.red.shade500;
    } else if (item.isExcel) {
      return Colors.green.shade500;
    } else if (item.isWord) {
      return Colors.blue.shade600;
    } else {
      return Colors.grey.shade500;
    }
  }

  IconData _getContentIcon() {
    if (item.isImage) {
      return Icons.image;
    } else if (item.isPdf) {
      return Icons.picture_as_pdf;
    } else if (item.isExcel) {
      return Icons.table_chart;
    } else if (item.isWord) {
      return Icons.description;
    } else {
      return Icons.insert_drive_file;
    }
  }

  String _getContentTypeText() {
    if (item.isImage) {
      return 'Image';
    } else if (item.isPdf) {
      return 'PDF Document';
    } else if (item.isExcel) {
      return 'Excel Spreadsheet';
    } else if (item.isWord) {
      return 'Word Document';
    } else {
      return 'Document';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }
}
