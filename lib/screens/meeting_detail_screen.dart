import 'package:flutter/material.dart';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/meeting_model.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/meeting_attachment_viewer.dart';
import '../widgets/action_by_picker.dart';
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
  
  // Map to store new document attachments for new discussions (key is discussion ID)
  final Map<int, File> _newDiscussionDocuments = {};
  
  // Audio player for voice notes
  late AudioPlayer _audioPlayer;
  bool _isPlayingVoiceNote = false;
  Duration _voiceNoteDuration = Duration.zero;
  Duration _voiceNotePosition = Duration.zero;
  
  // Voice note editing
  File? _newVoiceNoteFile;
  bool _isVoiceNoteRemoved = false;
  
  // Categories for action by picker
  List<CategoryModel> _categories = [];
  
  // Map to track action by names for each discussion during editing
  final Map<int, List<String>> _discussionActionByNames = {};

  @override
  void initState() {
    super.initState();
    _architectCompanyController = TextEditingController();
    _meetingPlaceController = TextEditingController();
    _meetingDateTimeController = TextEditingController();
    
    // Initialize audio player
    _audioPlayer = AudioPlayer();
    _initializeAudioPlayer();
    
    _loadMeetingDetail();
  }

  void _initializeAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _voiceNoteDuration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _voiceNotePosition = position;
        });
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlayingVoiceNote = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _architectCompanyController.dispose();
    _meetingPlaceController.dispose();
    _meetingDateTimeController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    if (_meeting == null) {
      print('Meeting is null, cannot load categories');
      return;
    }

    try {
      final token = await AuthService.currentToken;
      if (token != null) {
        final response = await ApiService.getCategoriesBySite(
          apiToken: token,
          siteId: _meeting!.siteId,
        );
        
        if (response.status == 1) {
          setState(() {
            _categories = response.categories;
          });
          print('Loaded ${_categories.length} categories for meeting detail screen');
        } else {
          print('Failed to load categories: ${response.message}');
        }
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  List<String> _getActionByNames(int discussionId) {
    if (!_discussionActionByNames.containsKey(discussionId)) {
      // Initialize from the discussion's actionBy string
      final discussion = _editableDiscussions.firstWhere(
        (d) => d.id == discussionId,
        orElse: () => _meeting!.meetingDiscussions.firstWhere(
          (d) => d.id == discussionId,
        ),
      );
      final actionBy = discussion.actionBy;
      _discussionActionByNames[discussionId] = actionBy.isEmpty 
          ? [] 
          : actionBy.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return _discussionActionByNames[discussionId]!;
  }

  void _updateActionByNames(int discussionId, List<String> names) {
    setState(() {
      _discussionActionByNames[discussionId] = names;
      
      // Update the discussion in _editableDiscussions
      final discussionIndex = _editableDiscussions.indexWhere((d) => d.id == discussionId);
      if (discussionIndex != -1) {
        final discussion = _editableDiscussions[discussionIndex];
        _editableDiscussions[discussionIndex] = MeetingDiscussionModel(
          id: discussion.id,
          meetingId: discussion.meetingId,
          discussionAction: discussion.discussionAction,
          actionBy: names.join(', '),
          remarks: discussion.remarks,
          createdAt: discussion.createdAt,
          updatedAt: discussion.updatedAt,
          deletedAt: discussion.deletedAt,
          meetingAttachment: discussion.meetingAttachment,
        );
      }
    });
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

    if (mounted) {
    setState(() {
      _isUpdating = true;
    });
    }

    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        SnackBarUtils.showError(
          context,
          message: 'Authentication token not found',
        );
        return;
      }

      // Validate date format before sending to API
      final dateTimeString = _meetingDateTimeController.text.trim();
      if (!_isValidDateTimeFormat(dateTimeString)) {
        SnackBarUtils.showError(
          context,
          message: 'Invalid date format. Please use YYYY-MM-DD HH:mm format',
        );
        return;
      }

      // Validate action by names for all editable discussions
      for (int i = 0; i < _editableDiscussions.length; i++) {
        final discussion = _editableDiscussions[i];
        final actionByNames = _getActionByNames(discussion.id);
        if (discussion.discussionAction.isNotEmpty && actionByNames.isEmpty) {
          SnackBarUtils.showError(
            context,
            message: 'Please select or enter at least one name for discussion point ${i + 1}',
          );
          return;
        }
      }

      // Get all valid discussions (both existing and new)
      final allDiscussions = _editableDiscussions
          .where((d) => d.discussionAction.isNotEmpty && d.actionBy.isNotEmpty)
          .toList();

      // Separate new discussions (with temporary IDs) for file handling
      final newDiscussions = allDiscussions
          .where((d) => d.id > 999999999) // Only new discussions (temporary IDs)
          .toList();

      // Prepare the update data
      final updateData = {
        'api_token': token,
        'site_id': _meeting!.siteId.toString(),
        'meeting_id': _meeting!.id.toString(),
        'architect_company': _architectCompanyController.text.trim(),
        'meeting_date_time': dateTimeString,
        'clients': _editableClients,
        'architects': _editableArchitects,
        'pmc_members': _editablePmcMembers,
        'contractors': _editableContractors,
        'meeting_discussions': allDiscussions.map(
              (d) => {
                'id': d.id > 999999999 ? null : d.id,
                'discussion_action': d.discussionAction,
                'action_by': d.actionBy,
                'remarks': d.remarks,
              },
            )
            .toList(),
      };
      

      print('Sending ${allDiscussions.length} total discussion points (${newDiscussions.length} new, ${allDiscussions.length - newDiscussions.length} existing)');


      final hasFiles = newDiscussions.any((d) => _newDiscussionDocuments.containsKey(d.id));
      final hasVoiceNoteChanges = _newVoiceNoteFile != null || _isVoiceNoteRemoved;

      final response = (hasFiles || hasVoiceNoteChanges)
          ? await ApiService.updateMeetingWithFiles(
              updateData: updateData,
              discussionFiles: newDiscussions.map((d) => _newDiscussionDocuments[d.id]).toList(),
              voiceNoteFile: _newVoiceNoteFile,
            )
          : await ApiService.updateMeeting(updateData);

      if (response != null && response['status'] == 1) {
        SnackBarUtils.showSuccess(
          context,
          message: 'Meeting updated successfully',
        );
        if (mounted) {
        setState(() {
          _isEditing = false;
            _newDiscussionDocuments.clear(); // Clear the attachments map
            _newVoiceNoteFile = null; // Clear the voice note file
            _isVoiceNoteRemoved = false; // Reset removal flag
        });
        }
        // Reload meeting data from server to get updated discussions
        await _loadMeetingDetail();
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
      if (mounted) {
      setState(() {
        _isUpdating = false;
      });
      }
    }
  }

  Future<void> _loadMeetingDetail() async {
    if (mounted) {
    setState(() {
      _isLoading = true;
    });
    }

    try {
      final token = await AuthService.currentToken;
      if (token != null) {
        final response = await ApiService.getMeetingDetail(
          apiToken: token,
          meetingId: widget.meetingId,
        );

        if (response != null && response.status == 1) {
          if (mounted) {
          setState(() {
            _meeting = response.meetingDetail;
          });
          }
          _initializeEditableFields();
          // Load categories after meeting data is available
          _loadCategories();
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
      if (mounted) {
      setState(() {
        _isLoading = false;
      });
      }
    }
  }

  Future<void> _refreshMeetingDetail() async {
    if (mounted) {
    setState(() {
    });
    }

    await _loadMeetingDetail();

    if (mounted) {
    setState(() {
    });
    }
  }


  void _addNewDiscussionPoint() {
    final newDiscussion = MeetingDiscussionModel(
      id: DateTime.now().millisecondsSinceEpoch,
      // Temporary ID
      meetingId: _meeting!.id,
      discussionAction: '',
      actionBy: '',
      remarks: '', // Empty instead of 'NA'
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      deletedAt: null,
      meetingAttachment: null,
    );

    if (mounted) {
    setState(() {
        // Insert at the beginning (index 0) to show new discussions at the top
        _editableDiscussions.insert(0, newDiscussion);
      });
    }
  }

  Future<void> _pickDocumentForNewDiscussion(int discussionId) async {
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

      setState(() {
        _newDiscussionDocuments[discussionId] = files.first;
      });

      SnackBarUtils.showSuccess(
        context,
        message: 'Document attached successfully',
      );
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Error selecting file: $e',
      );
    }
  }

  void _removeDocumentForNewDiscussion(int discussionId) {
    setState(() {
      _newDiscussionDocuments.remove(discussionId);
    });
    SnackBarUtils.showSuccess(
      context,
      message: 'Document removed',
    );
  }

  Future<void> _playVoiceNote() async {
    if (_meeting?.voiceNoteUrl == null || _meeting!.voiceNoteUrl!.isEmpty) {
      SnackBarUtils.showError(context, message: 'No voice note available');
      return;
    }

    try {
      if (_isPlayingVoiceNote) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(UrlSource(_meeting!.voiceNoteUrl!));
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Error playing voice note: $e');
    }
  }

  Future<void> _stopVoiceNote() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Error stopping voice note: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _pickNewVoiceNote() async {
    try {
      // Show options dialog for audio file selection
      final String? selectedType = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Select Audio File'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.audiotrack, color: Colors.purple),
                title: Text('Choose Audio File'),
                subtitle: Text('MP3, WAV, M4A, AAC'),
                onTap: () => Navigator.of(context).pop('audio'),
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

      // Pick audio files
      final files = await ImagePickerUtils.pickDocumentsWithSource(
        context: context,
        maxFiles: 1,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'],
      );

      if (files.isEmpty) return;

      if (mounted) {
        setState(() {
          _newVoiceNoteFile = files.first;
          _isVoiceNoteRemoved = false; // Reset removal flag when new file is selected
        });
      }

      SnackBarUtils.showSuccess(
        context,
        message: 'New voice note selected',
      );
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Error selecting voice note: $e',
      );
    }
  }

  void _removeVoiceNote() {
    if (mounted) {
      setState(() {
        _newVoiceNoteFile = null;
        _isVoiceNoteRemoved = true;
      });
    }
    SnackBarUtils.showSuccess(
      context,
      message: 'Voice note will be removed',
    );
  }

  void _cancelVoiceNoteChanges() {
    if (mounted) {
      setState(() {
        _newVoiceNoteFile = null;
        _isVoiceNoteRemoved = false;
      });
    }
    SnackBarUtils.showSuccess(
      context,
      message: 'Voice note changes cancelled',
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
                    SizedBox(height: 10),
                    _buildMeetingInfo(),
                    SizedBox(height: 10),
                    _buildParticipantsSection(),
                    SizedBox(height: 10),
                    _buildVoiceNoteSection(),
                    SizedBox(height: 10),
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12)
      ),
     
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


            // Editable participants
            if (_isEditing)
              _buildEditableParticipants()
            else
              _buildReadOnlyParticipants(),
          ],
      ),
    );
  }

  Widget _buildReadOnlyParticipants() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
    final controller = TextEditingController();
    
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
        SizedBox(height: 8),
        
        // Inline text field for adding participants
        Row(
            children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Enter $title name',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onSubmitted: (value) {
                  final name = value.trim();
                  if (name.isNotEmpty) {
                      setState(() {
                      participants.add(name);
                      });
                    controller.clear();
                  }
                    },
                  ),
                ),
            SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  participants.add(name);
                });
                  controller.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Icon(Icons.add, size: 20),
          ),
        ],
      ),
        
        if (participants.isNotEmpty) ...[
          SizedBox(height: 8),
          Wrap(
            spacing: 4,
            children: participants.map((participant) => Chip(
              label: Text(participant),
              deleteIcon: Icon(Icons.close, size: 16),
              onDeleted: () {
                setState(() {
                  participants.remove(participant);
                });
              },
            )).toList(),
          ),
        ],
      ],
    );
  }


  Widget _buildSimpleParticipantGroup(String title, List<String> participants) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              '$title:',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: participants.map((participant) => Chip(
              label: Text(
                participant,
                style: AppTypography.bodySmall,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 12,
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussionsSection() {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discussion Points',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),

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
                SizedBox(height: 8,)
              ],
            ),
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
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          margin: EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [

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
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          margin: EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [

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
                      SizedBox(height: 4),
                      if (isEditable)
                        TextFormField(
                          initialValue: discussion.discussionAction,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
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
                      SizedBox(height: 10),
                      if (isEditable)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            ActionByPicker(
                              selectedNames: _getActionByNames(discussion.id),
                              categories: _categories,
                              siteId: _meeting!.siteId,
                              discussionId: discussion.id, // Pass the discussion ID
                              hintText: 'Select Action By *',
                              onChanged: (selectedNames) {
                                _updateActionByNames(discussion.id, selectedNames);
                              },
                            ),

                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [


                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: discussion.actionBy
                                  .split(',')
                                  .map((name) => name.trim())
                                  .where((name) => name.isNotEmpty)
                                  .map((name) => Chip(
                                    label: Text(
                                      name,
                                      style: AppTypography.bodySmall.copyWith(
                                        fontSize: 12,
                                      ),
                                    ),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    labelStyle: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ))
                                  .toList(),
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

            SizedBox(height: 12),

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
                    vertical: 8,
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

            SizedBox(height: 12),
            // Attachment Section
            _buildAttachmentSection(discussion),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentSection(MeetingDiscussionModel discussion) {
    // Check if this is a new discussion (temporary ID) with a new document
    final isNewDiscussion = discussion.id > 999999999;
    final hasNewDocument = isNewDiscussion && _newDiscussionDocuments.containsKey(discussion.id);
    
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
              if (hasNewDocument)
                // Show newly attached document (not yet uploaded)
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        _getFileIconFromPath(_newDiscussionDocuments[discussion.id]!.path),
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _newDiscussionDocuments[discussion.id]!.path.split('/').last,
                          style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeDocumentForNewDiscussion(discussion.id),
                        icon: Icon(
                          Icons.close,
                          size: 14,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        tooltip: 'Remove Attachment',
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                      ),
                    ],
                  ),
                )
              else if (discussion.meetingAttachment != null)
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
                    onTap: () {
                      if (isNewDiscussion && _isEditing) {
                        // For new discussions in edit mode, use the new document picker
                        _pickDocumentForNewDiscussion(discussion.id);
                      } else {
                        // For existing discussions, use the existing attachment method
                        _addAttachment(discussion.id);
                      }
                    },
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

  IconData _getFileIconFromPath(String filePath) {
    final fileName = filePath.toLowerCase();
    if (fileName.endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    } else if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
      return Icons.description;
    } else if (fileName.endsWith('.xls') || fileName.endsWith('.xlsx')) {
      return Icons.table_chart;
    } else if (fileName.endsWith('.jpg') || 
               fileName.endsWith('.jpeg') || 
               fileName.endsWith('.png') || 
               fileName.endsWith('.gif')) {
      return Icons.image;
    } else {
      return Icons.insert_drive_file;
    }
  }

  Widget _buildVoiceNoteSection() {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.audiotrack,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 8),
                Text(
                  'Voice Note',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Spacer(),
                if (_isEditing && (_meeting?.voiceNoteUrl != null && _meeting!.voiceNoteUrl!.isNotEmpty)) ...[
                  // Replace voice note button (only show if voice note exists)
                  IconButton(
                    onPressed: _pickNewVoiceNote,
                    icon: Icon(Icons.edit, size: 18),
                    tooltip: 'Replace Voice Note',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  // Remove voice note button (only show if voice note exists)
                  IconButton(
                    onPressed: _removeVoiceNote,
                    icon: Icon(Icons.delete, size: 18),
                    tooltip: 'Remove Voice Note',
                    color: Theme.of(context).colorScheme.error,
                  ),
                ],
              ],
            ),
            SizedBox(height: 12),
            
            // Voice note content based on state
            if (_isVoiceNoteRemoved)
              // Voice note removed state
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 24,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Voice note will be removed',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _cancelVoiceNoteChanges,
                      child: Text('Cancel'),
                    ),
                  ],
                ),
              )
            else if (_newVoiceNoteFile != null)
              // New voice note selected state
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.audiotrack,
                      size: 24,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New voice note selected',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            _newVoiceNoteFile!.path.split('/').last,
                            style: AppTypography.bodySmall.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _cancelVoiceNoteChanges,
                      child: Text('Cancel'),
                    ),
                  ],
                ),
              )
            else if (_meeting?.voiceNoteUrl != null && _meeting!.voiceNoteUrl!.isNotEmpty)
              // Original voice note player (only if voice note exists)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    // Audio controls
                    Row(
                      children: [
                        // Play/Pause button
                        IconButton(
                          onPressed: _playVoiceNote,
                          icon: Icon(
                            _isPlayingVoiceNote ? Icons.pause_circle : Icons.play_circle,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        
                        SizedBox(width: 16),
                        
                        // Stop button
                        IconButton(
                          onPressed: _stopVoiceNote,
                          icon: Icon(
                            Icons.stop_circle,
                            size: 32,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        
                        SizedBox(width: 16),
                        
                        // Progress info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Voice Note',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${_formatDuration(_voiceNotePosition)} / ${_formatDuration(_voiceNoteDuration)}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Progress bar
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Theme.of(context).colorScheme.primary,
                        inactiveTrackColor: Theme.of(context).colorScheme.outline,
                        thumbColor: Theme.of(context).colorScheme.primary,
                        overlayColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      ),
                      child: Slider(
                        value: _voiceNoteDuration.inMilliseconds > 0
                            ? _voiceNotePosition.inMilliseconds / _voiceNoteDuration.inMilliseconds
                            : 0.0,
                        onChanged: (value) {
                          final position = Duration(
                            milliseconds: (value * _voiceNoteDuration.inMilliseconds).round(),
                          );
                          _audioPlayer.seek(position);
                        },
                      ),
                    ),
                  ],
                ),
              )
            else
              // No voice note - show add option
              InkWell(
                onTap: _isEditing ? _pickNewVoiceNote : null,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isEditing 
                          ? Theme.of(context).colorScheme.outline
                          : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _isEditing ? Icons.add : Icons.audiotrack_outlined,
                        size: 32,
                        color: _isEditing 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(height: 8),
                      Text(
                        _isEditing ? 'Attach Voice Note' : 'No Voice Note',
                        style: AppTypography.bodyMedium.copyWith(
                          color: _isEditing
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: _isEditing ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                      if (_isEditing) ...[
                        SizedBox(height: 4),
                        Text(
                          'Upload audio file (MP3, WAV, M4A, AAC)',
                          style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
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
