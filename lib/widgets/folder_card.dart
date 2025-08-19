import 'package:flutter/material.dart';
import '../models/site_album_model.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';

class FolderCard extends StatelessWidget {
  final SiteAlbumModel folder;
  final VoidCallback? onTap;
  final bool isSelected;

  const FolderCard({
    Key? key,
    required this.folder,
    this.onTap,
    this.isSelected = false,
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
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
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
              // Folder Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getFolderColor(),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getFolderIcon(),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Folder Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Folder Name
                    Text(
                      folder.albumName,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Folder Info
                    Row(
                      children: [
                        // Item count
                        if (folder.totalItems > 0) ...[
                          Icon(
                            Icons.file_present,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${folder.totalItems} items',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        
                        // Subfolder count
                        if (folder.hasChildren) ...[
                          if (folder.totalItems > 0)
                            const SizedBox(width: 8),
                          Icon(
                            Icons.folder,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${folder.children.length} folders',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    

                  ],
                ),
              ),
              

              
              // Arrow icon
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getFolderColor() {
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

  IconData _getFolderIcon() {
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
}
