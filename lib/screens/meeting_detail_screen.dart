import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/meeting_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/meeting_attachment_viewer.dart';
import '../core/utils/image_picker_utils.dart';

class MeetingDetailScreen extends StatefulWidget {
  final int meetingId;

  const MeetingDetailScreen({super.key, required this.meetingId});

  @override
  State<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends State<MeetingDetailScreen> {
  MeetingModel? _meeting;
  bool _isLoading = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadMeetingDetail();
  }

  Future<void> _loadMeetingDetail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService.currentToken;
      if (token != null) {
        final response = await ApiService.getMeetingDetail(
          apiToken: token,
          meetingId: widget.meetingId,
        );

        if (response != null && response.status == 1) {
          setState(() {
            _meeting = response.meetingDetail;
          });
        } else {
          SnackBarUtils.showError(
            context,
            message: 'Failed to load meeting details',
          );
        }
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Error loading meeting details: $e',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshMeetingDetail() async {
    setState(() {
      _isRefreshing = true;
    });

    await _loadMeetingDetail();

    setState(() {
      _isRefreshing = false;
    });
  }

  void _addDiscussionPoint() {
    // TODO: Implement add discussion point functionality
    SnackBarUtils.showInfo(
      context,
      message: 'Add discussion point functionality coming soon',
    );
  }

  Future<void> _deleteDiscussionPoint(int discussionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Discussion Point'),
        content: Text(
          'Are you sure you want to delete this discussion point? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
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
      final token = await AuthService.currentToken;
      if (token == null) {
        SnackBarUtils.showError(context, message: 'Authentication token not found');
        return;
      }

      final response = await ApiService.deleteMeetingDiscussion(
        apiToken: token,
        meetingDiscussionId: discussionId,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (response != null && response['status'] == 1) {
        SnackBarUtils.showSuccess(context, message: 'Discussion point deleted successfully');
        // Refresh the meeting details
        await _loadMeetingDetail();
      } else {
        SnackBarUtils.showError(context, message: response?['message'] ?? 'Failed to delete discussion point');
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      SnackBarUtils.showError(context, message: 'Error deleting discussion point: $e');
    }
  }

  Future<void> _addAttachment(int discussionId) async {
    try {
      // Show file picker dialog
      final files = await ImagePickerUtils.pickDocumentsWithSource(
        context: context,
        maxFiles: 1,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'rtf', 'jpg', 'jpeg', 'png', 'gif'],
      );

      if (files.isEmpty) return;

      final file = files.first;

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
        final token = await AuthService.currentToken;
        if (token == null) {
          SnackBarUtils.showError(context, message: 'Authentication token not found');
          return;
        }

        final response = await ApiService.saveMeetingAttachment(
          apiToken: token,
          meetingDiscussionId: discussionId,
          file: file,
        );

        // Close loading dialog
        Navigator.of(context).pop();

        if (response != null && response['status'] == 1) {
          SnackBarUtils.showSuccess(context, message: 'Attachment uploaded successfully');
          // Refresh the meeting details
          await _loadMeetingDetail();
        } else {
          SnackBarUtils.showError(context, message: response?['message'] ?? 'Failed to upload attachment');
        }
      } catch (e) {
        // Close loading dialog
        Navigator.of(context).pop();
        SnackBarUtils.showError(context, message: 'Error uploading attachment: $e');
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Error selecting file: $e');
    }
  }

  Future<void> _deleteAttachment(int attachmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Attachment'),
        content: Text(
          'Are you sure you want to delete this attachment? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
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
      final token = await AuthService.currentToken;
      if (token == null) {
        SnackBarUtils.showError(context, message: 'Authentication token not found');
        return;
      }

      final response = await ApiService.deleteAttachment(
        apiToken: token,
        meetingAttachmentId: attachmentId,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (response != null && response['status'] == 1) {
        SnackBarUtils.showSuccess(context, message: 'Attachment deleted successfully');
        // Refresh the meeting details
        await _loadMeetingDetail();
      } else {
        SnackBarUtils.showError(context, message: response?['message'] ?? 'Failed to delete attachment');
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      SnackBarUtils.showError(context, message: 'Error deleting attachment: $e');
    }
  }

  void _openPdfReport() {
    if (_meeting?.pdfReportUrl.isNotEmpty == true) {
      // TODO: Implement PDF opening functionality
      SnackBarUtils.showInfo(
        context,
        message: 'PDF report opening functionality coming soon',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Meeting Details',
        showDrawer: false,
        showBackButton: true,
      ),

      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _meeting == null
          ? Center(child: Text('Meeting not found'))
          : RefreshIndicator(
              onRefresh: _refreshMeetingDetail,
                             child: SingleChildScrollView(
                 padding: ResponsiveUtils.responsivePadding(context),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     _buildMeetingHeader(),
                     SizedBox(height: 16),
                     _buildMeetingInfo(),
                     SizedBox(height: 16),
                     _buildParticipantsSection(),
                     SizedBox(height: 16),
                     _buildDiscussionsSection(),
                     // Add bottom padding to ensure content is not hidden behind FAB
                     SizedBox(height: 100),
                   ],
                 ),
               ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDiscussionPoint,
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add),
        label: Text('Add Discussion'),
      ),
    );
  }

  Widget _buildMeetingHeader() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Meeting #${_meeting!.id}',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.successColor),
                  ),
                  child: Text(
                    'Completed',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.successColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 8),
                Text(
                  _meeting!.formattedDate,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 24),
                Icon(
                  Icons.access_time,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 8),
                Text(
                  _meeting!.formattedTime,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meeting Information',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),

            // Architect Company
            _buildInfoRow(
              icon: Icons.business,
              label: 'Architect Company',
              value: _meeting!.architectCompany,
            ),

            SizedBox(height: 8),

            // Meeting Place
            if (_meeting!.meetingPlace != null &&
                _meeting!.meetingPlace!.isNotEmpty)
              _buildInfoRow(
                icon: Icons.location_on,
                label: 'Meeting Place',
                value: _meeting!.meetingPlace!,
              ),

            if (_meeting!.meetingPlace != null &&
                _meeting!.meetingPlace!.isNotEmpty)
              SizedBox(height: 8),

            // Created Date
            _buildInfoRow(
              icon: Icons.schedule,
              label: 'Created',
              value: _meeting!.createdAt.split('T')[0], // Show only date
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Participants',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),

            // Simple list format
            if (_meeting!.clients.isNotEmpty)
              _buildSimpleParticipantGroup('Clients', _meeting!.clients),

            if (_meeting!.architects.isNotEmpty)
              _buildSimpleParticipantGroup('Architects', _meeting!.architects),

            if (_meeting!.pmcMembers.isNotEmpty)
              _buildSimpleParticipantGroup('PMC Members', _meeting!.pmcMembers),

            if (_meeting!.contractors.isNotEmpty &&
                _meeting!.contractors.any((c) => c != 'NA'))
              _buildSimpleParticipantGroup(
                'Contractors',
                _meeting!.contractors.where((c) => c != 'NA').toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleParticipantGroup(String title, List<String> participants) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$title:',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              participants.join(', '),
              style: AppTypography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussionsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Discussion Points',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_meeting!.meetingDiscussions.length} points',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            if (_meeting!.meetingDiscussions.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No discussion points yet',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap the + button to add a discussion point',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _meeting!.meetingDiscussions.length,
                itemBuilder: (context, index) {
                  final discussion = _meeting!.meetingDiscussions[index];
                  return _buildDiscussionCard(discussion);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscussionCard(MeetingDiscussionModel discussion) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Padding(
        padding: ResponsiveUtils.horizontalPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      discussion.discussionAction,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 6),
                        Text(
                          discussion.actionBy,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                                 IconButton(
                   onPressed: () => _deleteDiscussionPoint(discussion.id),
                   icon: Icon(Icons.delete, color: AppColors.errorColor),
                   tooltip: 'Delete Discussion',
                   padding: EdgeInsets.zero,
                   constraints: BoxConstraints(),
                 ),
              ],
            ),

            SizedBox(height: 6),

            // Remarks
            if (discussion.remarks.isNotEmpty && discussion.remarks != 'NA')
              Text(
                discussion.remarks,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),


              SizedBox(height: 8),

            // Attachment Section
            _buildAttachmentSection(discussion),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentSection(MeetingDiscussionModel discussion) {
    return Row(
      children: [
        Icon(Icons.attach_file, size: 14, color: AppColors.textSecondary),
        SizedBox(width: 4),
        Text(
          'Attachment:',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 8),
        if (discussion.meetingAttachment != null)
          // Show existing attachment
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.description,
                  size: 14,
                  color: AppColors.primaryColor,
                ),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    discussion.meetingAttachment!.file.split('/').last,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    NavigationUtils.push(
                      context,
                      MeetingAttachmentViewer(
                        attachment: discussion.meetingAttachment!,
                        onAttachmentDeleted: () {
                          // Refresh the meeting details when attachment is deleted
                          _loadMeetingDetail();
                        },
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.open_in_new,
                    size: 14,
                    color: AppColors.primaryColor,
                  ),
                  tooltip: 'Open Attachment',
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
                IconButton(
                  onPressed: () =>
                      _deleteAttachment(discussion.meetingAttachment!.id),
                  icon: Icon(
                    Icons.delete,
                    size: 14,
                    color: AppColors.errorColor,
                  ),
                  tooltip: 'Delete Attachment',
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
          )
        else
          // Show add attachment option
          Expanded(
            child: GestureDetector(
              onTap: () => _addAttachment(discussion.id),
              child: Row(
                children: [
                  Icon(Icons.add, size: 14, color: AppColors.textSecondary),
                  SizedBox(width: 4),
                  Text(
                    'Add Attachment',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
