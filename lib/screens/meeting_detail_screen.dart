import 'package:flutter/material.dart';
import 'dart:io';
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
  bool _isEditing = false;
  bool _isUpdating = false;
  int _uiUpdateCounter = 0;

  // Editable fields
  late TextEditingController _architectCompanyController;
  late TextEditingController _meetingPlaceController;
  late TextEditingController _meetingDateTimeController;
  late List<String> _editableClients;
  late List<String> _editableArchitects;
  late List<String> _editablePmcMembers;
  late List<String> _editableContractors;
  late List<MeetingDiscussionModel> _editableDiscussions;

  @override
  void initState() {
    super.initState();
    _architectCompanyController = TextEditingController();
    _meetingPlaceController = TextEditingController();
    _meetingDateTimeController = TextEditingController();
    _loadMeetingDetail();
  }

  @override
  void dispose() {
    _architectCompanyController.dispose();
    _meetingPlaceController.dispose();
    _meetingDateTimeController.dispose();
    super.dispose();
  }

  void _initializeEditableFields() {
    if (_meeting != null) {
      _architectCompanyController.text = _meeting!.architectCompany;
      _meetingPlaceController.text = _meeting!.meetingPlace ?? '';
      
      // Format the date time to remove seconds if present
      String dateTimeString = _meeting!.meetingDateTime;
      try {
        // If the date includes seconds, remove them
        if (dateTimeString.contains(':')) {
          final parts = dateTimeString.split(' ');
          if (parts.length == 2) {
            final datePart = parts[0];
            final timePart = parts[1];
            // Remove seconds from time part (e.g., "12:05:00" -> "12:05")
            if (timePart.split(':').length == 3) {
              final timeComponents = timePart.split(':');
              final formattedTime = '${timeComponents[0]}:${timeComponents[1]}';
              dateTimeString = '$datePart $formattedTime';
            }
          }
        }
      } catch (e) {
        // If parsing fails, use original string
      }
      
      _meetingDateTimeController.text = dateTimeString;
      _editableClients = List.from(_meeting!.clients);
      _editableArchitects = List.from(_meeting!.architects);
      _editablePmcMembers = List.from(_meeting!.pmcMembers);
      _editableContractors = List.from(_meeting!.contractors);
      _editableDiscussions = List.from(_meeting!.meetingDiscussions);
    }
  }

  void _updateLocalMeetingData() {
    if (_meeting != null) {
      // Update the meeting model with new data from controllers
      final updatedMeeting = MeetingModel(
        id: _meeting!.id,
        siteId: _meeting!.siteId,
        userId: _meeting!.userId,
        architectCompany: _architectCompanyController.text.trim(),
        meetingPlace: _meetingPlaceController.text.trim().isEmpty ? null : _meetingPlaceController.text.trim(),
        meetingDateTime: _meetingDateTimeController.text.trim(),
        clients: _editableClients,
        architects: _editableArchitects,
        pmcMembers: _editablePmcMembers,
        contractors: _editableContractors,
        meetingDiscussions: _editableDiscussions.where((d) => d.discussionAction.isNotEmpty && d.actionBy.isNotEmpty).toList(),
        createdAt: _meeting!.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
        pdfReportUrl: _meeting!.pdfReportUrl,
      );
      
      setState(() {
        _meeting = updatedMeeting;
      });
    }
  }

  void _removeDiscussionPointLocally(int discussionId) {
    if (_meeting != null) {
      // Remove from both editable and main meeting discussions
      _editableDiscussions.removeWhere((d) => d.id == discussionId);
      
      final updatedDiscussions = _meeting!.meetingDiscussions.where((d) => d.id != discussionId).toList();
      
      final updatedMeeting = MeetingModel(
        id: _meeting!.id,
        siteId: _meeting!.siteId,
        userId: _meeting!.userId,
        architectCompany: _meeting!.architectCompany,
        meetingPlace: _meeting!.meetingPlace,
        meetingDateTime: _meeting!.meetingDateTime,
        clients: _meeting!.clients,
        architects: _meeting!.architects,
        pmcMembers: _meeting!.pmcMembers,
        contractors: _meeting!.contractors,
        meetingDiscussions: updatedDiscussions,
        createdAt: _meeting!.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
        pdfReportUrl: _meeting!.pdfReportUrl,
      );
      
      setState(() {
        _meeting = updatedMeeting;
      });
    }
  }

  void _removeAttachmentLocally(int attachmentId) {
    if (_meeting != null) {
      // Remove attachment from discussions
      final updatedDiscussions = _meeting!.meetingDiscussions.map((discussion) {
        if (discussion.meetingAttachment?.id == attachmentId) {
          return MeetingDiscussionModel(
            id: discussion.id,
            meetingId: discussion.meetingId,
            discussionAction: discussion.discussionAction,
            actionBy: discussion.actionBy,
            remarks: discussion.remarks,
            createdAt: discussion.createdAt,
            updatedAt: discussion.updatedAt,
            deletedAt: discussion.deletedAt,
            meetingAttachment: null,
          );
        }
        return discussion;
      }).toList();
      
      // Also update editable discussions
      _editableDiscussions = _editableDiscussions.map((discussion) {
        if (discussion.meetingAttachment?.id == attachmentId) {
          return MeetingDiscussionModel(
            id: discussion.id,
            meetingId: discussion.meetingId,
            discussionAction: discussion.discussionAction,
            actionBy: discussion.actionBy,
            remarks: discussion.remarks,
            createdAt: discussion.createdAt,
            updatedAt: discussion.updatedAt,
            deletedAt: discussion.deletedAt,
            meetingAttachment: null,
          );
        }
        return discussion;
      }).toList();
      
      final updatedMeeting = MeetingModel(
        id: _meeting!.id,
        siteId: _meeting!.siteId,
        userId: _meeting!.userId,
        architectCompany: _meeting!.architectCompany,
        meetingPlace: _meeting!.meetingPlace,
        meetingDateTime: _meeting!.meetingDateTime,
        clients: _meeting!.clients,
        architects: _meeting!.architects,
        pmcMembers: _meeting!.pmcMembers,
        contractors: _meeting!.contractors,
        meetingDiscussions: updatedDiscussions,
        createdAt: _meeting!.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
        pdfReportUrl: _meeting!.pdfReportUrl,
      );
      
      setState(() {
        _meeting = updatedMeeting;
        _uiUpdateCounter++;
      });
    }
  }

  void _addAttachmentLocally(int discussionId, dynamic attachmentData) {
    print('_addAttachmentLocally called with discussionId: $discussionId, attachmentData: $attachmentData');
    
    if (_meeting != null && attachmentData != null) {
      // Create new attachment model
      final newAttachment = MeetingAttachmentModel(
        id: attachmentData['id'] ?? DateTime.now().millisecondsSinceEpoch,
        meetingDiscussionId: discussionId,
        file: attachmentData['file'] ?? '',
        filePath: attachmentData['file_path'] ?? attachmentData['file'] ?? '',
      );
      
      print('Created new attachment: id=${newAttachment.id}, file=${newAttachment.file}, filePath=${newAttachment.filePath}');
      
      // Update discussions with new attachment
      print('Looking for discussion with ID: $discussionId');
      print('Available discussion IDs: ${_meeting!.meetingDiscussions.map((d) => d.id).toList()}');
      
      final updatedDiscussions = _meeting!.meetingDiscussions.map((discussion) {
        if (discussion.id == discussionId) {
          print('Found matching discussion, updating with attachment');
          return MeetingDiscussionModel(
            id: discussion.id,
            meetingId: discussion.meetingId,
            discussionAction: discussion.discussionAction,
            actionBy: discussion.actionBy,
            remarks: discussion.remarks,
            createdAt: discussion.createdAt,
            updatedAt: discussion.updatedAt,
            deletedAt: discussion.deletedAt,
            meetingAttachment: newAttachment,
          );
        }
        return discussion;
      }).toList();
      
      // Also update editable discussions
      print('Available editable discussion IDs: ${_editableDiscussions.map((d) => d.id).toList()}');
      _editableDiscussions = _editableDiscussions.map((discussion) {
        if (discussion.id == discussionId) {
          print('Found matching editable discussion, updating with attachment');
          return MeetingDiscussionModel(
            id: discussion.id,
            meetingId: discussion.meetingId,
            discussionAction: discussion.discussionAction,
            actionBy: discussion.actionBy,
            remarks: discussion.remarks,
            createdAt: discussion.createdAt,
            updatedAt: discussion.updatedAt,
            deletedAt: discussion.deletedAt,
            meetingAttachment: newAttachment,
          );
        }
        return discussion;
      }).toList();
      
      final updatedMeeting = MeetingModel(
        id: _meeting!.id,
        siteId: _meeting!.siteId,
        userId: _meeting!.userId,
        architectCompany: _meeting!.architectCompany,
        meetingPlace: _meeting!.meetingPlace,
        meetingDateTime: _meeting!.meetingDateTime,
        clients: _meeting!.clients,
        architects: _meeting!.architects,
        pmcMembers: _meeting!.pmcMembers,
        contractors: _meeting!.contractors,
        meetingDiscussions: updatedDiscussions,
        createdAt: _meeting!.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
        pdfReportUrl: _meeting!.pdfReportUrl,
      );
      
      setState(() {
        _meeting = updatedMeeting;
        _uiUpdateCounter++;
      });
      
      print('State updated. New meeting has ${_meeting!.meetingDiscussions.length} discussions');
      print('Discussion attachments: ${_meeting!.meetingDiscussions.map((d) => 'ID: ${d.id}, Attachment: ${d.meetingAttachment?.id ?? 'none'}').toList()}');
    } else {
      print('_addAttachmentLocally failed: _meeting is null or attachmentData is null');
    }
  }

  Future<void> _updateMeeting() async {
    if (_meeting == null) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        SnackBarUtils.showError(
          context,
          message: 'Authentication token not found',
        );
        return;
      }

      // Prepare the update data
      final updateData = {
        'api_token': token,
        'site_id': _meeting!.siteId.toString(),
        'meeting_id': _meeting!.id.toString(),
        'architect_company': _architectCompanyController.text.trim(),
        'meeting_date_time': _meetingDateTimeController.text.trim(),
        'clients': _editableClients,
        'architects': _editableArchitects,
        'pmc_members': _editablePmcMembers,
        'contractors': _editableContractors,
        'meeting_discussions': _editableDiscussions
            .where(
              (d) => d.discussionAction.isNotEmpty && d.actionBy.isNotEmpty,
            ) // Filter out empty discussions
            .where(
              (d) => d.id > 999999999, // Only new discussions (temporary IDs)
            ) // Only send new discussion points
            .map(
              (d) => {
                'discussion_action': d.discussionAction,
                'action_by': d.actionBy,
                'remarks': d.remarks,
                'meeting_attachment': d.meetingAttachment != null
                    ? {
                        'id': d.meetingAttachment!.id,
                        'file': d.meetingAttachment!.file,
                      }
                    : null,
              },
            )
            .toList(),
      };

      // Validate date format before sending to API
      final dateTimeString = _meetingDateTimeController.text.trim();
      if (!_isValidDateTimeFormat(dateTimeString)) {
        SnackBarUtils.showError(
          context,
          message: 'Invalid date format. Please use YYYY-MM-DD HH:mm format',
        );
        return;
      }

      // Debug: Print the date format being sent
      print('Meeting date time being sent: "$dateTimeString"');
      
      // Debug: Print new discussion points count
      final newDiscussions = _editableDiscussions
          .where((d) => d.discussionAction.isNotEmpty && d.actionBy.isNotEmpty)
          .where((d) => d.id > 999999999)
          .toList();
      print('Sending ${newDiscussions.length} new discussion points');

      final response = await ApiService.updateMeeting(updateData);

      if (response != null && response['status'] == 1) {
        SnackBarUtils.showSuccess(
          context,
          message: 'Meeting updated successfully',
        );
        setState(() {
          _isEditing = false;
        });
        // Update local data without full reload
        _updateLocalMeetingData();
        // Return true to indicate meeting was updated
        Navigator.of(context).pop(true);
      } else {
        SnackBarUtils.showError(
          context,
          message: response?['message'] ?? 'Failed to update meeting',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Error updating meeting: $e');
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
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
          _initializeEditableFields();
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
    });

    await _loadMeetingDetail();

    setState(() {
    });
  }


  void _addNewDiscussionPoint() {
    final newDiscussion = MeetingDiscussionModel(
      id: DateTime.now().millisecondsSinceEpoch,
      // Temporary ID
      meetingId: _meeting!.id,
      discussionAction: '',
      actionBy: '',
      remarks: 'NA',
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      deletedAt: null,
      meetingAttachment: null,
    );

    setState(() {
      _editableDiscussions.add(newDiscussion);
    });
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
              backgroundColor: Theme.of(context).colorScheme.error,
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
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        SnackBarUtils.showError(
          context,
          message: 'Authentication token not found',
        );
        return;
      }

      final response = await ApiService.deleteMeetingDiscussion(
        apiToken: token,
        meetingDiscussionId: discussionId,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (response != null && response['status'] == 1) {
        SnackBarUtils.showSuccess(
          context,
          message: 'Discussion point deleted successfully',
        );
        // Update local data without full reload
        _removeDiscussionPointLocally(discussionId);
      } else {
        SnackBarUtils.showError(
          context,
          message: response?['message'] ?? 'Failed to delete discussion point',
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      SnackBarUtils.showError(
        context,
        message: 'Error deleting discussion point: $e',
      );
    }
  }

  Future<void> _addAttachment(int discussionId) async {
    // Show options dialog for file type selection
    final String? selectedType = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select File Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.image, color: Colors.blue),
              title: Text('Choose Image'),
              subtitle: Text('JPG, PNG, GIF'),
              onTap: () => Navigator.of(context).pop('image'),
            ),
            ListTile(
              leading: Icon(Icons.description, color: Colors.green),
              title: Text('Choose Document'),
              subtitle: Text('PDF, DOC, XLS, TXT'),
              onTap: () => Navigator.of(context).pop('document'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedType == null) return;

    try {
      List<File> files = [];
      
      if (selectedType == 'image') {
        // Pick images (includes camera and gallery options)
        final file = await ImagePickerUtils.showImageSourceDialog(context: context);
        if (file != null) {
          files = [file];
        }
      } else {
        // Pick documents
        files = await ImagePickerUtils.pickDocumentsWithSource(
          context: context,
          maxFiles: 1,
          allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'rtf'],
        );
      }

      if (files.isEmpty) return;

      final file = files.first;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        },
      );

      try {
        final token = await AuthService.currentToken;
        if (token == null) {
          SnackBarUtils.showError(
            context,
            message: 'Authentication token not found',
          );
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
          SnackBarUtils.showSuccess(
            context,
            message: 'Attachment uploaded successfully',
          );
          // Debug: Print the response to see the structure
          print('Attachment API Response: $response');
          
          // Update local data without full reload
          // Try different possible response structures
          final attachmentData = response['data'] ?? response['attachment'] ?? response;
          print('Using attachment data: $attachmentData');
          
          // Try to update locally first
          _addAttachmentLocally(discussionId, attachmentData);
          
          // If local update doesn't work, reload the meeting data
          // This ensures we get the latest data from the server
          Future.delayed(Duration(milliseconds: 500), () {
            _loadMeetingDetail();
          });
        } else {
          SnackBarUtils.showError(
            context,
            message: response?['message'] ?? 'Failed to upload attachment',
          );
        }
      } catch (e) {
        // Close loading dialog
        Navigator.of(context).pop();
        SnackBarUtils.showError(
          context,
          message: 'Error uploading attachment: $e',
        );
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
              backgroundColor: Theme.of(context).colorScheme.error,
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
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        SnackBarUtils.showError(
          context,
          message: 'Authentication token not found',
        );
        return;
      }

      final response = await ApiService.deleteAttachment(
        apiToken: token,
        meetingAttachmentId: attachmentId,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (response != null && response['status'] == 1) {
        SnackBarUtils.showSuccess(
          context,
          message: 'Attachment deleted successfully',
        );
        // Update local data without full reload
        _removeAttachmentLocally(attachmentId);
      } else {
        SnackBarUtils.showError(
          context,
          message: response?['message'] ?? 'Failed to delete attachment',
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      SnackBarUtils.showError(
        context,
        message: 'Error deleting attachment: $e',
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
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : _meeting == null
          ? Center(child: Text('Meeting not found'))
          : RefreshIndicator(
              onRefresh: _refreshMeetingDetail,
              color: Theme.of(context).colorScheme.primary,
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
      floatingActionButton: _isEditing
          ? FloatingActionButton.extended(
              onPressed: _isUpdating ? null : _updateMeeting,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              icon: _isUpdating
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.save),
              label: Text(_isUpdating ? 'Saving...' : 'Save Changes'),
            )
          : FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              icon: Icon(Icons.add),
              label: Text('Add or Edit'),
            ),
    );
  }


  Widget _buildMeetingHeader() {
    return Card(
      color: Theme.of(context).colorScheme.surface,
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
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(
                    'Completed',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.green,
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
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 8),
                Text(
                  _meeting!.formattedDate,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(width: 24),
                Icon(
                  Icons.access_time,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 8),
                Text(
                  _meeting!.formattedTime,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
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
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meeting Information',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Architect Company
            _buildEditableInfoRow(
              icon: Icons.business,
              label: 'Architect Company',
              controller: _architectCompanyController,
              isEditing: _isEditing,
            ),

            SizedBox(height: 8),

            // Meeting Place
            _buildEditableInfoRow(
              icon: Icons.location_on,
              label: 'Meeting Place',
              controller: _meetingPlaceController,
              isEditing: _isEditing,
              isOptional: true,
            ),

            SizedBox(height: 8),

            // Meeting Date & Time
            if (_isEditing)
              _buildEditableInfoRow(
                icon: Icons.access_time,
                label: 'Meeting Date & Time',
                controller: _meetingDateTimeController,
                isEditing: _isEditing,
                onTap: _selectDateTime,
              )
            else
              _buildInfoRow(
                icon: Icons.access_time,
                label: 'Meeting Date & Time',
                value: '${_meeting!.formattedDate} ${_meeting!.formattedTime}',
              ),

            SizedBox(height: 8),

            // Created Date (Read-only)
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
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableInfoRow({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    bool isOptional = false,
    VoidCallback? onTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 2),
              if (isEditing)
                GestureDetector(
                  onTap: onTap,
                  child: TextFormField(
                    controller: controller,
                    enabled: onTap == null,
                    // Disable if it has onTap (like date picker)
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      hintText: isOptional ? 'Optional' : 'Enter $label',
                    ),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                )
              else
                Text(
                  controller.text.isEmpty
                      ? (isOptional ? 'Not specified' : 'N/A')
                      : controller.text,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: controller.text.isEmpty
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    try {
      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      // Ensure format matches API expectation exactly: "YYYY-MM-DD HH:mm" (NO SECONDS)
      final formatted = "$y-$m-$d $h:$min";
      if (!_isValidDateTimeFormat(formatted)) {
        throw Exception('Generated date format is invalid: $formatted');
      }
      return formatted;
    } catch (e) {
      throw Exception('Invalid date format. Please use YYYY-MM-DD HH:mm format');
    }
  }

  bool _isValidDateTimeFormat(String dateTimeString) {
    try {
      // Check if the format matches YYYY-MM-DD HH:mm exactly
      final regex = RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$');
      if (!regex.hasMatch(dateTimeString)) {
        return false;
      }
      
      // Try to parse the date to ensure it's valid
      final parts = dateTimeString.split(' ');
      if (parts.length != 2) return false;
      
      final datePart = parts[0];
      final timePart = parts[1];
      
      final dateComponents = datePart.split('-');
      final timeComponents = timePart.split(':');
      
      if (dateComponents.length != 3 || timeComponents.length != 2) {
        return false;
      }
      
      final year = int.parse(dateComponents[0]);
      final month = int.parse(dateComponents[1]);
      final day = int.parse(dateComponents[2]);
      final hour = int.parse(timeComponents[0]);
      final minute = int.parse(timeComponents[1]);
      
      // Validate ranges
      if (year < 2000 || year > 2100) return false;
      if (month < 1 || month > 12) return false;
      if (day < 1 || day > 31) return false;
      if (hour < 0 || hour > 23) return false;
      if (minute < 0 || minute > 59) return false;
      
      // Try to create a DateTime to ensure it's valid
      DateTime(year, month, day, hour, minute);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _selectDateTime() async {
    // Parse current date from controller to set initial values
    DateTime initialDate = DateTime.now();
    TimeOfDay initialTime = TimeOfDay.now();

    if (_meetingDateTimeController.text.isNotEmpty) {
      try {
        // Try to parse the current date format
        String dateTimeText = _meetingDateTimeController.text;
        
        // If the time has seconds, remove them for parsing
        if (dateTimeText.contains(':')) {
          final parts = dateTimeText.split(' ');
          if (parts.length == 2) {
            final datePart = parts[0];
            final timePart = parts[1];
            // Remove seconds if present (e.g., "12:05:00" -> "12:05")
            if (timePart.split(':').length == 3) {
              final timeComponents = timePart.split(':');
              final formattedTime = '${timeComponents[0]}:${timeComponents[1]}';
              dateTimeText = '$datePart $formattedTime';
            }
          }
        }
        
        final currentDateTime = DateTime.parse('${dateTimeText.split(' ')[0]}T${dateTimeText.split(' ')[1]}:00');
        initialDate = currentDateTime;
        initialTime = TimeOfDay(
          hour: currentDateTime.hour,
          minute: currentDateTime.minute,
        );
      } catch (e) {
        // If parsing fails, use current date/time
      }
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );

      if (pickedTime != null) {
        // Use the robust formatting method
        final combinedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        
        try {
          final formattedDateTime = _formatDateTime(combinedDateTime);
          setState(() {
            _meetingDateTimeController.text = formattedDateTime;
          });
        } catch (e) {
          SnackBarUtils.showError(
            context,
            message: 'Error formatting date: ${e.toString()}',
          );
        }
      }
    }
  }

  Widget _buildParticipantsSection() {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Participants',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 12),

            // Editable participants
            if (_isEditing)
              _buildEditableParticipants()
            else
              _buildReadOnlyParticipants(),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyParticipants() {
    return Column(
      children: [
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
    );
  }

  Widget _buildEditableParticipants() {
    return Column(
      children: [
        _buildEditableParticipantGroup('Clients', _editableClients),
        SizedBox(height: 8),
        _buildEditableParticipantGroup('Architects', _editableArchitects),
        SizedBox(height: 8),
        _buildEditableParticipantGroup('PMC Members', _editablePmcMembers),
        SizedBox(height: 8),
        _buildEditableParticipantGroup('Contractors', _editableContractors),
      ],
    );
  }

  Widget _buildEditableParticipantGroup(
    String title,
    List<String> participants,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 4),
        Container(
          width: double.infinity,
          child: Wrap(
            spacing: ResponsiveUtils.isPhone(context) ? 4 : 8,
            runSpacing: ResponsiveUtils.isPhone(context) ? 2 : 4,
            children: [
              ...participants.map(
                (participant) => ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: ResponsiveUtils.isPhone(context) ? 120 : 150,
                  ),
                  child: Chip(
                    label: Text(
                      participant,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.isPhone(context) ? 12 : 14,
                      ),
                    ),
                    deleteIcon: Icon(
                      Icons.close,
                      size: ResponsiveUtils.isPhone(context) ? 14 : 16,
                    ),
                    onDeleted: () {
                      setState(() {
                        participants.remove(participant);
                      });
                    },
                  ),
                ),
              ),
              ActionChip(
                label: Text('+ Add'),
                onPressed: () => _addParticipant(title, participants),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: ResponsiveUtils.isPhone(context) ? 12 : 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _addParticipant(String groupTitle, List<String> participants) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $groupTitle'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Name',
            hintText: 'Enter $groupTitle name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  participants.add(name);
                });
                Navigator.of(context).pop();
              }
            },
            child: Text('Add'),
          ),
        ],
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              participants.join(', '),
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussionsSection() {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discussion Points',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_isEditing ? _editableDiscussions.length : _meeting!.meetingDiscussions.length} points',
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (_isEditing)
                      IconButton(
                        onPressed: _addNewDiscussionPoint,
                        icon: Icon(
                          Icons.add_circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        tooltip: 'Add Discussion Point',
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),

            _buildDiscussionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscussionsList() {
    if (_isEditing) {
      // Show editable discussions
      if (_editableDiscussions.isEmpty) {
        return Center(
          child: Column(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              SizedBox(height: 8),
              Text(
                'No discussion points yet',
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Tap the + button to add a discussion point',
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      } else {
        return ListView.builder(
          key: ValueKey('editable_discussions_$_uiUpdateCounter'),
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _editableDiscussions.length,
          itemBuilder: (context, index) {
            final discussion = _editableDiscussions[index];
            return _buildDiscussionCard(discussion);
          },
        );
      }
    } else {
      // Show read-only discussions
      if (_meeting!.meetingDiscussions.isEmpty) {
        return Center(
          child: Column(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              SizedBox(height: 8),
              Text(
                'No discussion points yet',
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Tap the + button to add a discussion point',
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      } else {
        return ListView.builder(
          key: ValueKey('readonly_discussions_$_uiUpdateCounter'),
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _meeting!.meetingDiscussions.length,
          itemBuilder: (context, index) {
            final discussion = _meeting!.meetingDiscussions[index];
            return _buildDiscussionCard(discussion);
          },
        );
      }
    }
  }

  Widget _buildDiscussionCard(MeetingDiscussionModel discussion) {
    final int discussionIndex = _editableDiscussions.indexWhere(
      (d) => d.id == discussion.id,
    );
    final bool isEditable = _isEditing && discussionIndex != -1;

    return Container(
      key: ValueKey('discussion_${discussion.id}_${discussion.meetingAttachment?.id ?? 'no_attachment'}'),
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isEditable)
                        TextFormField(
                          initialValue: discussion.discussionAction,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            hintText: 'Discussion action',
                          ),
                          onChanged: (value) {
                            if (discussionIndex != -1) {
                              final discussion =
                                  _editableDiscussions[discussionIndex];
                              _editableDiscussions[discussionIndex] =
                                  MeetingDiscussionModel(
                                    id: discussion.id,
                                    meetingId: discussion.meetingId,
                                    discussionAction: value,
                                    actionBy: discussion.actionBy,
                                    remarks: discussion.remarks,
                                    createdAt: discussion.createdAt,
                                    updatedAt: discussion.updatedAt,
                                    deletedAt: discussion.deletedAt,
                                    meetingAttachment:
                                        discussion.meetingAttachment,
                                  );
                            }
                          },
                        )
                      else
                        Text(
                          discussion.discussionAction,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.visible,
                        ),
                      SizedBox(height: 5),
                      if (isEditable)
                        TextFormField(
                          initialValue: discussion.actionBy,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            hintText: 'Action by',
                          ),
                          onChanged: (value) {
                            if (discussionIndex != -1) {
                              final discussion =
                                  _editableDiscussions[discussionIndex];
                              _editableDiscussions[discussionIndex] =
                                  MeetingDiscussionModel(
                                    id: discussion.id,
                                    meetingId: discussion.meetingId,
                                    discussionAction:
                                        discussion.discussionAction,
                                    actionBy: value,
                                    remarks: discussion.remarks,
                                    createdAt: discussion.createdAt,
                                    updatedAt: discussion.updatedAt,
                                    deletedAt: discussion.deletedAt,
                                    meetingAttachment:
                                        discussion.meetingAttachment,
                                  );
                            }
                          },
                        )
                      else
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                discussion.actionBy,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                // Show delete button for all discussions
                IconButton(
                  onPressed: () {
                    if (_isEditing && discussion.id > 999999999) {
                      // If it's a new discussion (temporary ID) in edit mode, just remove from editable list
                      setState(() {
                        _editableDiscussions.removeWhere(
                          (d) => d.id == discussion.id,
                        );
                      });
                    } else {
                      // Existing discussion, show delete confirmation (works in both edit and read-only mode)
                      _deleteDiscussionPoint(discussion.id);
                    }
                  },
                  icon: Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  tooltip: (_isEditing && discussion.id > 999999999)
                      ? 'Remove New Discussion'
                      : 'Delete Discussion',
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),

            SizedBox(height: 6),

            // Remarks
            if (isEditable)
              TextFormField(
                initialValue: discussion.remarks == 'NA'
                    ? ''
                    : discussion.remarks,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  hintText: 'Remarks (optional)',
                ),
                onChanged: (value) {
                  if (discussionIndex != -1) {
                    final discussion = _editableDiscussions[discussionIndex];
                    _editableDiscussions[discussionIndex] =
                        MeetingDiscussionModel(
                          id: discussion.id,
                          meetingId: discussion.meetingId,
                          discussionAction: discussion.discussionAction,
                          actionBy: discussion.actionBy,
                          remarks: value.isEmpty ? 'NA' : value,
                          createdAt: discussion.createdAt,
                          updatedAt: discussion.updatedAt,
                          deletedAt: discussion.deletedAt,
                          meetingAttachment: discussion.meetingAttachment,
                        );
                  }
                },
              )
            else if (discussion.remarks.isNotEmpty &&
                discussion.remarks != 'NA')
              Text(
                discussion.remarks,
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        Icon(
          Icons.attach_file,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: 4),
        Flexible(
          child: Row(
            children: [
              Text(
                'Attachment:',
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 8),
              if (discussion.meetingAttachment != null)
                // Show existing attachment
                Expanded(
                  child: Row(
                    children: [
                      // Show appropriate icon based on file type
                      _buildAttachmentIcon(discussion.meetingAttachment!.file),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          discussion.meetingAttachment!.file.split('/').last,
                          style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.primary,
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
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        tooltip: 'Open Attachment',
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                      ),
                      IconButton(
                        onPressed: () =>
                            _deleteAttachment(discussion.meetingAttachment!.id),
                        icon: Icon(
                          Icons.delete,
                          size: 14,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        tooltip: 'Delete Attachment',
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(minWidth: 24, minHeight: 24),
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
                        Icon(
                          Icons.add,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Add Attachment',
                            style: AppTypography.bodySmall.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentIcon(String filePath) {
    final fileName = filePath.toLowerCase();
    final IconData iconData;
    final Color iconColor;

    if (fileName.contains('.jpg') || fileName.contains('.jpeg') || 
        fileName.contains('.png') || fileName.contains('.gif')) {
      iconData = Icons.image;
      iconColor = Colors.blue;
    } else if (fileName.contains('.pdf')) {
      iconData = Icons.picture_as_pdf;
      iconColor = Colors.red;
    } else if (fileName.contains('.doc') || fileName.contains('.docx')) {
      iconData = Icons.description;
      iconColor = Colors.blue;
    } else if (fileName.contains('.xls') || fileName.contains('.xlsx')) {
      iconData = Icons.table_chart;
      iconColor = Colors.green;
    } else {
      iconData = Icons.attach_file;
      iconColor = Theme.of(context).colorScheme.primary;
    }

    return Icon(
      iconData,
      size: 14,
      color: iconColor,
    );
  }
}
