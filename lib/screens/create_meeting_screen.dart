import 'package:flutter/material.dart';
import 'dart:io';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/utils/image_picker_utils.dart';
import '../models/site_model.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/action_by_picker.dart';

class CreateMeetingScreen extends StatefulWidget {
  final SiteModel site;

  const CreateMeetingScreen({
    super.key,
    required this.site,
  });

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _architectCompanyController = TextEditingController();
  final _meetingPlaceController = TextEditingController();
  final _meetingDateTimeController = TextEditingController();
  
  // Participant lists
  List<String> _clients = [];
  List<String> _architects = [];
  List<String> _pmcMembers = [];
  List<String> _contractors = [];
  
  // Discussion points
  List<MeetingDiscussion> _discussions = [];
  
  // Voice note file
  File? _voiceNoteFile;
  
  // Categories for action by picker
  List<CategoryModel> _categories = [];
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set default date/time to next hour
    final now = DateTime.now();
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1, 0);
    _meetingDateTimeController.text = _formatDateTime(nextHour);
    
    // Pre-fill architect company from site if available
    if (widget.site.architectName != null && widget.site.architectName!.isNotEmpty) {
      _architectCompanyController.text = widget.site.architectName!;
    }
    
    // Load categories for action by picker
    _loadCategories();
  }

  @override
  void dispose() {
    _architectCompanyController.dispose();
    _meetingPlaceController.dispose();
    _meetingDateTimeController.dispose();
    // Dispose discussion controllers
    for (var discussion in _discussions) {
      discussion.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final token = await AuthService.currentToken;
      if (token != null) {
        final response = await ApiService.getCategoriesBySite(
          apiToken: token,
          siteId: widget.site.id,
        );
        
        if (response.status == 1) {
          setState(() {
            _categories = response.categories;
          });
          print('Loaded ${_categories.length} categories for create meeting screen');
        } else {
          print('Failed to load categories: ${response.message}');
        }
      } else {
        print('No auth token available');
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  String _formatDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return "$y-$m-$d $h:$min";
  }

  Future<void> _selectDateTime() async {
    DateTime initialDate = DateTime.now();
    TimeOfDay initialTime = TimeOfDay.now();

    if (_meetingDateTimeController.text.isNotEmpty) {
      try {
        final parts = _meetingDateTimeController.text.split(' ');
        if (parts.length == 2) {
          final datePart = parts[0];
          final timePart = parts[1];
          final dateTime = DateTime.parse('${datePart}T$timePart:00');
          initialDate = dateTime;
          initialTime = TimeOfDay(
            hour: dateTime.hour,
            minute: dateTime.minute,
          );
        }
      } catch (e) {
        // Use current date/time if parsing fails
      }
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(Duration(days: 180)), // 6 months ago
      lastDate: DateTime.now().add(Duration(days: 365)), // 1 year future
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );

      if (pickedTime != null) {
        final combinedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        
        setState(() {
          _meetingDateTimeController.text = _formatDateTime(combinedDateTime);
        });
      }
    }
  }


  void _addDiscussionPoint() {
    // Dismiss keyboard before adding new discussion point
    FocusScope.of(context).unfocus();
    
    setState(() {
      // Insert at the beginning (index 0) to show new discussions at the top
      _discussions.insert(0, MeetingDiscussion(
        id: DateTime.now().millisecondsSinceEpoch, // Generate unique ID
        discussionAction: '',
        actionBy: '',
        remarks: '',
        document: null,
      ));
    });
    
    // Multiple safety checks to ensure keyboard stays dismissed
    Future.delayed(Duration(milliseconds: 50), () {
      FocusScope.of(context).unfocus();
    });
    
    Future.delayed(Duration(milliseconds: 150), () {
      FocusScope.of(context).unfocus();
    });
    
    Future.delayed(Duration(milliseconds: 300), () {
      FocusScope.of(context).unfocus();
    });
  }

  void _removeDiscussionPoint(int index) {
    setState(() {
      _discussions.removeAt(index);
    });
  }

  Future<void> _pickDocument(int index) async {
    // Dismiss keyboard before showing dialog
    FocusScope.of(context).unfocus();
    
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
        _discussions[index].document = files.first;
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

  void _removeDocument(int index) {
    setState(() {
      _discussions[index].document = null;
    });
    SnackBarUtils.showSuccess(
      context,
      message: 'Document removed',
    );
  }

  Future<void> _pickVoiceNote() async {
    try {
      // Dismiss keyboard before showing dialog
      FocusScope.of(context).unfocus();
      
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

      setState(() {
        _voiceNoteFile = files.first;
      });

      SnackBarUtils.showSuccess(
        context,
        message: 'Voice note attached successfully',
      );
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Error selecting voice note: $e',
      );
    }
  }

  void _removeVoiceNote() {
    setState(() {
      _voiceNoteFile = null;
    });
    SnackBarUtils.showSuccess(
      context,
      message: 'Voice note removed',
    );
  }

  Future<void> _createMeeting() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate action by names for all discussions
    for (int i = 0; i < _discussions.length; i++) {
      final discussion = _discussions[i];
      if (discussion.discussionAction.isNotEmpty && discussion.actionByNames.isEmpty) {
        SnackBarUtils.showError(
          context,
          message: 'Please select or enter at least one name for discussion point ${i + 1}',
        );
        return;
      }
    }

    if (_clients.isEmpty && _architects.isEmpty && _pmcMembers.isEmpty) {
      SnackBarUtils.showError(
        context,
        message: 'Please add at least one participant',
      );
      return;
    }

    setState(() {
      _isLoading = true;
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

      // Filter out empty discussions and update actionBy from actionByNames
      final validDiscussions = _discussions
          .where((d) => d.discussionAction.isNotEmpty && d.actionByNames.isNotEmpty)
          .toList();
      
      // Update actionBy field from actionByNames for all valid discussions
      for (var discussion in validDiscussions) {
        discussion.updateActionBy();
      }

      final meetingData = {
        'api_token': token,
        'site_id': widget.site.id.toString(),
        'architect_company': _architectCompanyController.text.trim(),
        'meeting_date_time': _meetingDateTimeController.text.trim(),
        'meeting_place': _meetingPlaceController.text.trim().isEmpty 
            ? null 
            : _meetingPlaceController.text.trim(),
        'clients': _clients,
        'architects': _architects,
        'pmc_members': _pmcMembers,
        'contractors': _contractors,
        'meeting_discussions': validDiscussions.map((d) => {
          'discussion_action': d.discussionAction,
          'action_by': d.actionBy,
          'remarks': d.remarks.isEmpty ? 'NA' : d.remarks,
          'document': '', // Add empty document field for consistency
        }).toList(),
      };



      // Check if any discussion has a file attached or if there's a voice note
      final hasFiles = validDiscussions.any((d) => d.document != null) || _voiceNoteFile != null;
      
      final response = hasFiles
          ? await ApiService.saveMeetingWithFiles(
              meetingData: meetingData,
              discussionFiles: validDiscussions.map((d) => d.document).toList(),
              voiceNoteFile: _voiceNoteFile,
            )
          : await ApiService.saveMeeting(meetingData);

      if (response != null && response['status'] == 1) {
        SnackBarUtils.showSuccess(
          context,
          message: 'Meeting created successfully',
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      } else {
        SnackBarUtils.showError(
          context,
          message: response?['message'] ?? 'Failed to create meeting',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Error creating meeting: $e',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Create Meeting',
        showDrawer: false,
        showBackButton: true,
        onBackPressed: () {
          // Dismiss keyboard before navigating back
          FocusScope.of(context).unfocus();
          Navigator.of(context).pop();
        },
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: ResponsiveUtils.responsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMeetingInfoSection(),
                SizedBox(height: 8),
                _buildParticipantsSection(),
                SizedBox(height: 8),
                _buildDiscussionsSection(),
                SizedBox(height: 8),
                _buildVoiceNoteSection(),
                SizedBox(height: 100), // Space for FAB
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _createMeeting,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(Icons.save),
        label: Text(_isLoading ? 'Creating...' : 'Create Meeting'),
      ),
    );
  }

  Widget _buildMeetingInfoSection() {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            
            // Architect Company
            TextFormField(
              controller: _architectCompanyController,
              enabled: widget.site.architectName == null || widget.site.architectName!.isEmpty,
              decoration: InputDecoration(
                labelText: 'Architect Company *',
                hintText: widget.site.architectName != null && widget.site.architectName!.isNotEmpty
                    ? 'From site'
                    : 'Enter architect company name',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: widget.site.architectName != null && widget.site.architectName!.isNotEmpty,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter architect company name';
                }
                return null;
              },
            ),
            
            SizedBox(height: 16),
            
            // Meeting Date & Time
            GestureDetector(
              onTap: _selectDateTime,
              child: AbsorbPointer(
                child: TextFormField(
                  controller: _meetingDateTimeController,
                  decoration: InputDecoration(
                    labelText: 'Meeting Date & Time *',
                    hintText: 'Select meeting date and time',
                    prefixIcon: Icon(Icons.access_time),
                    suffixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please select meeting date and time';
                }
                return null;
              },
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Meeting Place (Optional)
            TextFormField(
              controller: _meetingPlaceController,
              decoration: InputDecoration(
                labelText: 'Meeting Place (Optional)',
                hintText: 'Enter meeting location',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsSection() {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            
            _buildParticipantGroup('Clients', _clients, Icons.person),
            SizedBox(height: 16),
            _buildParticipantGroup('Architects', _architects, Icons.architecture),
            SizedBox(height: 16),
            _buildParticipantGroup('PMC Members', _pmcMembers, Icons.group),
            SizedBox(height: 16),
            _buildParticipantGroup('Contractors', _contractors, Icons.build),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantGroup(String title, List<String> participants, IconData icon) {
    final controller = TextEditingController();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 8),
            Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
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
            spacing: 8,
            runSpacing: 8,
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

  Widget _buildDiscussionsSection() {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Discussion Points',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Spacer(),
                TextButton.icon(
                  onPressed: _addDiscussionPoint,
                  icon: Icon(Icons.add, size: 16),
                  label: Text('Add Point'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),


            if (_discussions.isEmpty)
              Container(
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

                    SizedBox(height: 8),
                    Text(
                      'No discussion points yet',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Add discussion points to plan meeting agenda',
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: _discussions.length,
                itemBuilder: (context, index) {
                  return _buildDiscussionCard(index);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscussionCard(int index) {
    final discussion = _discussions[index];
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(
                'Discussion Point ${index + 1}',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Spacer(),
              Container(
                height: 20,
                width: 20,
                child: IconButton(
                  onPressed: () => _removeDiscussionPoint(index),
                  icon: Icon(Icons.delete, size: 18),
                  color: Theme.of(context).colorScheme.error,
                  tooltip: 'Remove Discussion Point',
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          
          // Discussion Action
          TextFormField(
            controller: discussion.discussionActionController,
            autofocus: false, // Prevent auto-focus to avoid keyboard opening
            decoration: InputDecoration(
              labelText: 'Discussion Action *',
              hintText: 'What needs to be discussed?',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onChanged: (value) {
              discussion.discussionAction = value;
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter discussion action';
              }
              return null;
            },
          ),
          
          SizedBox(height: 8),
          
          // Action By
          ActionByPicker(
            selectedNames: discussion.actionByNames,
            categories: _categories,
            siteId: widget.site.id,
            discussionId: discussion.id, // Use the actual discussion ID
            hintText: 'Action By *',
            onChanged: (selectedNames) {
              discussion.actionByNames = selectedNames;
              discussion.updateActionBy();
            },
          ),
          
          SizedBox(height: 8),
          
          // Remarks
          TextFormField(
            controller: discussion.remarksController,
            autofocus: false, // Prevent auto-focus to avoid keyboard opening
            decoration: InputDecoration(
              labelText: 'Remarks (Optional)',
              hintText: 'Additional notes or comments',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onChanged: (value) {
              discussion.remarks = value;
            },
            maxLines: 2,
          ),
          
          SizedBox(height: 12),
          
          // Document Attachment
          Row(
            children: [
              Icon(
                Icons.attach_file,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 8),
              Text(
                'Document:',
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 8),
              if (discussion.document != null)
                // Show attached document
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getFileIcon(discussion.document!.path),
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            discussion.document!.path.split('/').last,
                            style: AppTypography.bodySmall.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        SizedBox(width: 4),
                        InkWell(
                          onTap: () => _removeDocument(index),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                // Show attach button
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDocument(index),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Attach Document',
                          style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
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
                if (_voiceNoteFile != null)
                  TextButton.icon(
                    onPressed: _removeVoiceNote,
                    icon: Icon(Icons.delete, size: 16),
                    label: Text('Remove'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12),
            
            if (_voiceNoteFile != null)
              // Show attached voice note
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
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
                            _voiceNoteFile!.path.split('/').last,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Voice Note File',
                            style: AppTypography.bodySmall.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _removeVoiceNote,
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      tooltip: 'Remove Voice Note',
                    ),
                  ],
                ),
              )
            else
              // Show attach button
              InkWell(
                onTap: _pickVoiceNote,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [

                      Text(
                        'Attach Voice Note',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Upload audio file (MP3, WAV, M4A, AAC)',
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String filePath) {
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
}

class MeetingDiscussion {
  int id; // Add ID field for proper identification
  String discussionAction;
  String actionBy; // This will store comma-separated names for API
  List<String> actionByNames; // This will store individual names for UI
  String remarks;
  File? document;
  TextEditingController? discussionActionController;
  TextEditingController? remarksController;

  MeetingDiscussion({
    required this.id, // Make ID required
    required this.discussionAction,
    required this.actionBy,
    required this.remarks,
    this.document,
  }) : actionByNames = actionBy.isEmpty ? [] : actionBy.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() {
    discussionActionController = TextEditingController(text: discussionAction);
    remarksController = TextEditingController(text: remarks);
  }

  // Helper method to update actionBy from actionByNames
  void updateActionBy() {
    actionBy = actionByNames.join(', ');
  }

  void dispose() {
    discussionActionController?.dispose();
    remarksController?.dispose();
  }
}
