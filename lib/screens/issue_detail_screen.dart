import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../models/site_model.dart';
import '../models/issue_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/dismiss_keyboard.dart';
import '../widgets/full_screen_image_viewer.dart';
import '../models/unified_image_model.dart' as unified;
import 'package:intl/intl.dart';

class IssueDetailScreen extends StatefulWidget {
  final int issueId;
  final SiteModel site;

  const IssueDetailScreen({
    super.key,
    required this.issueId,
    required this.site,
  });

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
  Issue? _issue;
  bool _isLoading = true;
  bool _isAddingComment = false;

  // Comment input
  final TextEditingController _commentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  List<File> _commentImages = [];

  // Current user
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadIssueDetail();
  }

  Future<void> _loadCurrentUser() async {
    final user = AuthService.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.id;
      });
    }
  }

  Future<void> _loadIssueDetail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        SnackBarUtils.showError(context, message: 'Authentication token not found');
        return;
      }

      final response = await ApiService.getIssueDetail(
        apiToken: token,
        issueId: widget.issueId,
      );

      if (response.status == 1 && response.data != null) {
        setState(() {
          _issue = Issue.fromJson(response.data as Map<String, dynamic>);
        });
      } else {
        SnackBarUtils.showError(
          context,
          message: response.message ?? 'Failed to load issue details',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Error loading issue details: $e',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addComment() async {
      if ((_commentController.text.trim().isEmpty) && _commentImages.isEmpty) {
      SnackBarUtils.showError(context, message: 'Please enter a comment or add an image');
      return;
    }

    if (_issue == null) return;

    // Check permission - only creator or assigned user can comment
    if (_issue!.createdBy != _currentUserId &&
        _issue!.assignedTo != _currentUserId) {
      SnackBarUtils.showError(
        context,
        message: 'You do not have permission to comment on this issue',
      );
      return;
    }

    setState(() {
      _isAddingComment = true;
    });

    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        SnackBarUtils.showError(context, message: 'Authentication token not found');
        return;
      }

      final response = await ApiService.addIssueComment(
        apiToken: token,
        issueId: widget.issueId,
        comment: _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : null,
        images: _commentImages,
      );

      if (response.status == 1) {
        _commentController.clear();
        setState(() {
          _commentImages = [];
        });
        _loadIssueDetail(); // Reload to get new comment
        SnackBarUtils.showSuccess(context, message: 'Comment added successfully');
      } else {
        SnackBarUtils.showError(
          context,
          message: response.message ?? 'Failed to add comment',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Error adding comment: $e',
      );
    } finally {
      setState(() {
        _isAddingComment = false;
      });
    }
  }

  Future<void> _pickCommentImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _commentImages.addAll(images.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Error picking images: $e');
    }
  }

  void _removeCommentImage(int index) {
    setState(() {
      _commentImages.removeAt(index);
    });
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_issue == null) return;

    // Check permission
    if (_issue!.createdBy != _currentUserId &&
        _issue!.assignedTo != _currentUserId) {
      SnackBarUtils.showError(
        context,
        message: 'You do not have permission to update this issue status',
      );
      return;
    }

    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        SnackBarUtils.showError(context, message: 'Authentication token not found');
        return;
      }

      final response = await ApiService.updateIssueStatus(
        apiToken: token,
        issueId: widget.issueId,
        status: newStatus,
      );

      if (response.status == 1) {
        _loadIssueDetail(); // Reload to get updated status
        SnackBarUtils.showSuccess(context, message: 'Status updated successfully');
      } else {
        SnackBarUtils.showError(
          context,
          message: response.message ?? 'Failed to update status',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Error updating status: $e',
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AppColors.errorColor;
      case 'working':
        return AppColors.warningColor;
      case 'qc':
        return AppColors.infoColor;
      case 'solved':
        return AppColors.successColor;
      case 'done':
        return Colors.green;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getLinkTypeLabel(String linkType) {
    switch (linkType) {
      case 'from_task':
        return 'Task';
      case 'from_site':
        return 'Site';
      case 'from_material':
        return 'Material';
      case 'other':
        return 'Other';
      default:
        return linkType;
    }
  }

  bool _canComment() {
    if (_issue == null || _currentUserId == null) return false;
    return _issue!.createdBy == _currentUserId ||
        _issue!.assignedTo == _currentUserId;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DismissKeyboard(
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Issue Details',
          showDrawer: false,
          showBackButton: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _issue == null
                ? const Center(child: Text('Issue not found'))
                : Column(
                    children: [
                      // Issue Details
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status and Source
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(_issue!.status)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _issue!.status,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: _getStatusColor(_issue!.status),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _getLinkTypeLabel(_issue!.linkType),
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Status Update Section (if can update)
                              if (_canComment()) ...[
                                _buildStatusUpdateSection(),
                                const SizedBox(height: 24),
                              ],

                              // Description
                              Text(
                                'Description',
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _issue!.description,
                                style: AppTypography.bodyLarge,
                              ),
                              const SizedBox(height: 24),

                              // Details Grid
                              _buildDetailRow(
                                'Assigned To',
                                _issue!.assignedUser?['full_name'] ?? 
                                (_issue!.assignedUser?['first_name'] != null 
                                  ? '${_issue!.assignedUser?['first_name']} ${_issue!.assignedUser?['last_name'] ?? ''}'.trim()
                                  : 'Not assigned'),
                              ),
                              if (_issue!.dueDate != null)
                                _buildDetailRow(
                                  'Due Date',
                                  DateFormat('MMM dd, yyyy').format(_issue!.dueDate!),
                                ),
                              if (_issue!.tag != null)
                                _buildDetailRow(
                                  'Tag',
                                  _issue!.tag!['name'] ?? '',
                                ),
                              _buildDetailRow(
                                'Created By',
                                _issue!.createdUser?['full_name'] ?? 
                                (_issue!.createdUser?['first_name'] != null 
                                  ? '${_issue!.createdUser?['first_name']} ${_issue!.createdUser?['last_name'] ?? ''}'.trim()
                                  : 'Unknown'),
                              ),
                              _buildDetailRow(
                                'Created On',
                                DateFormat('MMM dd, yyyy hh:mm a')
                                    .format(_issue!.createdAt),
                              ),

                              // Attachments
                              if (_issue!.attachments != null &&
                                  _issue!.attachments!.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                Text(
                                  'Attachments',
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _issue!.attachments!.map((attachment) {
                                    final url = attachment['attachment_path'] ??
                                        attachment['attachment'];
                                    return GestureDetector(
                                      onTap: () {
                                        if (attachment['type'] == 'image') {
                                          NavigationUtils.push(
                                            context,
                                            FullScreenImageViewer(
                                              images: [
                                                unified.UnifiedImageModel(
                                                  id: attachment['id'] ?? 0,
                                                  imagePath: url,
                                                  createdAt: attachment['created_at'] ?? DateTime.now().toIso8601String(),
                                                  updatedAt: attachment['updated_at'] ?? DateTime.now().toIso8601String(),
                                                  source: unified.ImageSource.taskImage,
                                                ),
                                              ],
                                              initialIndex: 0,
                                            ),
                                          );
                                        }
                                      },
                                      child: Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.grey.withOpacity(0.3),
                                          ),
                                        ),
                                        child: attachment['type'] == 'image'
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  url,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (context, error, stackTrace) {
                                                    return const Icon(
                                                      Icons.broken_image,
                                                    );
                                                  },
                                                ),
                                              )
                                            : const Icon(Icons.insert_drive_file),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],

                              // Comments Section
                              const SizedBox(height: 24),
                              Text(
                                'Comments',
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildCommentsSection(),
                            ],
                          ),
                        ),
                      ),

                      // Comment Input (only if can comment)
                      if (_canComment()) _buildCommentInput(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    if (_issue!.comments == null || _issue!.comments!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No comments yet',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Column(
      children: _issue!.comments!.map((commentData) {
        final comment = IssueComment.fromJson(commentData);
        final user = comment.user;
        final userName = user?['full_name'] ?? 
            (user?['first_name'] != null 
              ? '${user?['first_name']} ${user?['last_name'] ?? ''}'.trim()
              : 'Unknown');
        final isCurrentUser = user?['id'] == _currentUserId;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: isCurrentUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!isCurrentUser) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryColor,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? AppColors.primaryColor.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isCurrentUser
                              ? AppColors.primaryColor
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (comment.comment != null &&
                          comment.comment!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          comment.comment!,
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                      if (comment.images != null &&
                          comment.images!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: comment.images!.map((imageData) {
                            final imageUrl = imageData['image_path'] ??
                                imageData['image'];
                            return GestureDetector(
                              onTap: () {
                                NavigationUtils.push(
                                  context,
                                  FullScreenImageViewer(
                                    images: [
                                      unified.UnifiedImageModel(
                                        id: imageData['id'] ?? 0,
                                        imagePath: imageUrl,
                                        createdAt: imageData['created_at'] ?? DateTime.now().toIso8601String(),
                                        updatedAt: imageData['updated_at'] ?? DateTime.now().toIso8601String(),
                                        source: unified.ImageSource.taskImage,
                                      ),
                                    ],
                                    initialIndex: 0,
                                  ),
                                );
                              },
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.broken_image);
                                    },
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, hh:mm a').format(comment.createdAt),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isCurrentUser) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryColor,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Selected Images
          if (_commentImages.isNotEmpty)
            Container(
              height: 80,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _commentImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _commentImages[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => _removeCommentImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          // Input Row
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.image),
                onPressed: _pickCommentImages,
                color: AppColors.primaryColor,
              ),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: AppColors.primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _addComment(),
                ),
              ),
              IconButton(
                icon: _isAddingComment
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                onPressed: _isAddingComment ? null : _addComment,
                color: AppColors.primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusUpdateSection() {
    final currentStatus = _issue!.status;
    final statuses = ['Open', 'working', 'QC', 'solved', 'done'];
    final currentIndex = statuses.indexOf(currentStatus);
    
    // Get next available status (step by step)
    List<String> availableStatuses = [];
    if (currentIndex == -1 || currentIndex == 0) {
      // If Open or unknown, can go to working
      availableStatuses = ['working'];
    } else if (currentIndex == 1) {
      // If working, can go to QC
      availableStatuses = ['QC'];
    } else if (currentIndex == 2) {
      // If QC, can go to solved
      availableStatuses = ['solved'];
    } else if (currentIndex == 3) {
      // If solved, can go to done
      availableStatuses = ['done'];
    } else {
      // If done, no next status
      availableStatuses = [];
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Update Status',
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Current Status
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(currentStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStatusColor(currentStatus),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: _getStatusColor(currentStatus),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currentStatus,
                        style: AppTypography.bodyMedium.copyWith(
                          color: _getStatusColor(currentStatus),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (availableStatuses.isNotEmpty) ...[
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                // Next Status Button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _updateStatus(availableStatuses.first);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            availableStatuses.first,
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (availableStatuses.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Status is complete',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

