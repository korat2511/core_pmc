import 'package:flutter/material.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/site_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';

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
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set default date/time to next hour
    final now = DateTime.now();
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1, 0);
    _meetingDateTimeController.text = _formatDateTime(nextHour);
  }

  @override
  void dispose() {
    _architectCompanyController.dispose();
    _meetingPlaceController.dispose();
    _meetingDateTimeController.dispose();
    super.dispose();
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
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
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

  void _addDiscussionPoint() {
    setState(() {
      _discussions.add(MeetingDiscussion(
        discussionAction: '',
        actionBy: '',
        remarks: '',
      ));
    });
  }

  void _removeDiscussionPoint(int index) {
    setState(() {
      _discussions.removeAt(index);
    });
  }

  Future<void> _createMeeting() async {
    if (!_formKey.currentState!.validate()) {
      return;
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

      // Filter out empty discussions
      final validDiscussions = _discussions
          .where((d) => d.discussionAction.isNotEmpty && d.actionBy.isNotEmpty)
          .toList();

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
        }).toList(),
      };

      final response = await ApiService.saveMeeting(meetingData);

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
                SizedBox(height: 24),
                _buildParticipantsSection(),
                SizedBox(height: 24),
                _buildDiscussionsSection(),
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
            Text(
              'Meeting Information',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 16),
            
            // Architect Company
            TextFormField(
              controller: _architectCompanyController,
              decoration: InputDecoration(
                labelText: 'Architect Company *',
                hintText: 'Enter architect company name',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
            Text(
              'Participants',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 16),
            
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
            Spacer(),
            TextButton.icon(
              onPressed: () => _addParticipant(title, participants),
              icon: Icon(Icons.add, size: 16),
              label: Text('Add'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        if (participants.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'No $title added yet',
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
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
            Row(
              children: [
                Text(
                  'Discussion Points',
                  style: AppTypography.titleMedium.copyWith(
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
            SizedBox(height: 16),
            
            if (_discussions.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
              IconButton(
                onPressed: () => _removeDiscussionPoint(index),
                icon: Icon(Icons.delete, size: 18),
                color: Theme.of(context).colorScheme.error,
                tooltip: 'Remove Discussion Point',
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: 8),
          
          // Discussion Action
          TextFormField(
            initialValue: discussion.discussionAction,
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
          TextFormField(
            initialValue: discussion.actionBy,
            decoration: InputDecoration(
              labelText: 'Action By *',
              hintText: 'Who is responsible?',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onChanged: (value) {
              discussion.actionBy = value;
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter action by';
              }
              return null;
            },
          ),
          
          SizedBox(height: 8),
          
          // Remarks
          TextFormField(
            initialValue: discussion.remarks,
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
        ],
      ),
    );
  }
}

class MeetingDiscussion {
  String discussionAction;
  String actionBy;
  String remarks;

  MeetingDiscussion({
    required this.discussionAction,
    required this.actionBy,
    required this.remarks,
  });
}
