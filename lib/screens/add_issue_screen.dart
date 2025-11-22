import 'dart:io';
import 'package:flutter/material.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../core/utils/date_picker_utils.dart';
import '../core/utils/image_picker_utils.dart';
import '../models/site_model.dart';
import '../models/issue_model.dart';
import '../models/task_model.dart';
import '../models/material_model.dart';
import '../models/site_user_model.dart';
import '../models/tag_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/api_response.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_date_picker_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/dismiss_keyboard.dart';
import '../widgets/custom_search_bar.dart';
import '../core/constants/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AddIssueScreen extends StatefulWidget {
  final SiteModel site;
  final Issue? issue; // For editing

  const AddIssueScreen({
    super.key,
    required this.site,
    this.issue,
  });

  @override
  State<AddIssueScreen> createState() => _AddIssueScreenState();
}

class _AddIssueScreenState extends State<AddIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _dueDateController = TextEditingController();

  String _linkType = 'from_site'; // from_task, from_site, from_material, other
  int? _selectedTaskId;
  int? _selectedMaterialId;
  List<int> _selectedAssignedTo = [];
  List<int> _selectedTagId = [];
  String _status = 'Open';

  // Options
  List<TaskModel> _tasks = [];
  List<MaterialModel> _materials = [];
  List<SiteUserModel> _siteUsers = [];
  List<TagModel> _tags = [];
  bool _isLoadingOptions = false;

  // Attachments
  List<File> _selectedAttachments = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
    _loadOptions();
  }

  void _initializeFields() {
    if (widget.issue != null) {
      final issue = widget.issue!;
      _linkType = issue.linkType;
      _descriptionController.text = issue.description;
      _dueDateController.text = issue.dueDate != null
          ? DateFormat('dd-MM-yyyy').format(issue.dueDate!)
          : '';
      _selectedTaskId = issue.taskId;
      _selectedMaterialId = issue.materialId;
      // Parse comma-separated values or single value
      if (issue.assignedTo != null) {
        _selectedAssignedTo = [issue.assignedTo!];
      } else {
        _selectedAssignedTo = [];
      }
      if (issue.tagId != null) {
        _selectedTagId = [issue.tagId!];
      } else {
        _selectedTagId = [];
      }
      _status = issue.status;
    } else {
      _dueDateController.text = DatePickerUtils.getCurrentDate(format: 'dd-MM-yyyy');
      _selectedAssignedTo = [];
      _selectedTagId = [];
    }
    
    // Load full issue detail to get comma-separated values if editing
    if (widget.issue != null) {
      _loadIssueDetailForEditing();
    }
  }

  Future<void> _loadIssueDetailForEditing() async {
    if (widget.issue == null) return;
    
    try {
      final token = await AuthService.currentToken;
      if (token == null) return;
      
      final response = await ApiService.getIssueDetail(
        apiToken: token,
        issueId: widget.issue!.id,
      );
      
      if (response.status == 1 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        
        // Parse comma-separated assigned_to
        if (data['assigned_to'] != null) {
          final assignedToStr = data['assigned_to'].toString();
          if (assignedToStr.isNotEmpty) {
            setState(() {
              _selectedAssignedTo = assignedToStr
                  .split(',')
                  .map((id) => int.tryParse(id.trim()) ?? 0)
                  .where((id) => id > 0)
                  .toList();
            });
          }
        }
        
        // Parse comma-separated tag_id
        if (data['tag_id'] != null) {
          final tagIdStr = data['tag_id'].toString();
          if (tagIdStr.isNotEmpty) {
            setState(() {
              _selectedTagId = tagIdStr
                  .split(',')
                  .map((id) => int.tryParse(id.trim()) ?? 0)
                  .where((id) => id > 0)
                  .toList();
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading issue detail for editing: $e');
      // Keep the values from _initializeFields
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _isLoadingOptions = true;
    });

    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        SnackBarUtils.showError(context, message: 'Authentication token not found');
        return;
      }

      // Load tasks - only normal tasks (cat_sub_id = 5)
      final taskResponse = await ApiService.getTaskList(
        apiToken: token,
        siteId: widget.site.id,
        filters: {
          'normalTasksOnly': '1', // Only normal tasks (cat_sub_id = 5)
        },
      );
      if (taskResponse.status == 1) {
        setState(() {
          _tasks = taskResponse.data;
        });
      }

      // Load materials
      final materialResponse = await ApiService.getMaterials(
        siteId: widget.site.id,
      );
      if (materialResponse != null && materialResponse.status == 1 && materialResponse.data != null) {
        setState(() {
          _materials = materialResponse.data!;
        });
      }

      // Load site users
      final userResponse = await ApiService.getUsersBySite(
        apiToken: token,
        siteId: widget.site.id,
      );
      if (userResponse.isSuccess) {
        setState(() {
          _siteUsers = userResponse.users;
        });
      }

      // Load tags
      final tagResponse = await ApiService.getTags(apiToken: token);
      if (tagResponse.isSuccess) {
        setState(() {
          _tags = tagResponse.data;
        });
      }
    } catch (e) {
      debugPrint('Error loading options: $e');
    } finally {
      setState(() {
        _isLoadingOptions = false;
      });
    }
  }

  Future<void> _pickAttachments() async {
    try {
      final List<File> images = await ImagePickerUtils.pickImages(
        context: context,
        chooseMultiple: true,
        maxImages: 10,
        imageQuality: 80,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedAttachments.addAll(images);
        });
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Error picking files: $e');
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _selectedAttachments.removeAt(index);
    });
  }

  Future<void> _saveIssue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_linkType == 'from_task' && _selectedTaskId == null) {
      SnackBarUtils.showError(context, message: 'Please select a task');
      return;
    }

    if (_linkType == 'from_material' && _selectedMaterialId == null) {
      SnackBarUtils.showError(context, message: 'Please select a material');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        SnackBarUtils.showError(context, message: 'Authentication token not found');
        return;
      }

      // Format date from dd-MM-yyyy to yyyy-MM-dd for API
      DateTime? dueDate;
      if (_dueDateController.text.isNotEmpty) {
        try {
          // Parse dd-MM-yyyy format
          final parsed = DateFormat('dd-MM-yyyy').parse(_dueDateController.text);
          dueDate = parsed;
        } catch (e) {
          // If parsing fails, try to parse as is
          try {
            dueDate = DateTime.parse(_dueDateController.text);
          } catch (e2) {
            debugPrint('Error parsing date: $e2');
          }
        }
      }

      ApiResponse response;

      if (widget.issue != null) {
        // Update existing issue
        response = await ApiService.updateIssue(
          apiToken: token,
          issueId: widget.issue!.id,
          description: _descriptionController.text,
          dueDate: dueDate,
          assignedTo: _selectedAssignedTo.isEmpty ? null : _selectedAssignedTo.join(','),
          tagId: _selectedTagId.isEmpty ? null : _selectedTagId.join(','),
          status: _status,
          attachments: _selectedAttachments,
        );
      } else {
        // Create new issue
        response = await ApiService.createIssue(
          apiToken: token,
          siteId: widget.site.id,
          linkType: _linkType,
          description: _descriptionController.text,
          dueDate: dueDate,
          assignedTo: _selectedAssignedTo.isEmpty ? null : _selectedAssignedTo.join(','),
          tagId: _selectedTagId.isEmpty ? null : _selectedTagId.join(','),
          status: _status,
          taskId: _linkType == 'from_task' ? _selectedTaskId : null,
          materialId: _linkType == 'from_material' ? _selectedMaterialId : null,
          agencyId: null, // Agency not needed for "other" link type
          attachments: _selectedAttachments,
        );
      }

      if (response.status == 1) {
        SnackBarUtils.showSuccess(
          context,
          message: widget.issue != null
              ? 'Issue updated successfully'
              : 'Issue created successfully',
        );
        NavigationUtils.pop(context, true);
      } else {
        SnackBarUtils.showError(
          context,
          message: response.message.isNotEmpty ? response.message : 'Failed to save issue',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Error saving issue: $e',
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DismissKeyboard(
      child: Scaffold(
        appBar: CustomAppBar(
          title: widget.issue != null ? 'Edit Issue' : 'New Issue',
          showDrawer: false,
          showBackButton: true,
        ),
        body: _isLoadingOptions
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Link Type Selection
                      Text(
                        'Source',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildLinkTypeSelector(),
                      const SizedBox(height: 24),

                      // Conditional Fields based on Link Type
                      if (_linkType == 'from_task') ...[
                        _buildTaskSelector(),
                        const SizedBox(height: 16),
                      ],
                      if (_linkType == 'from_material') ...[
                        _buildMaterialSelector(),
                        const SizedBox(height: 16),
                      ],

                      // Description
                      CustomTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        hintText: 'Enter issue description',
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Due Date
                      CustomDatePickerField(
                        controller: _dueDateController,
                        label: 'Due Date',
                        hintText: 'Select due date',
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                      ),
                      const SizedBox(height: 16),

                      // Assigned To (Multiple Selection)
                      _buildMultiSelectionField<int>(
                        label: 'Assigned To',
                        values: _selectedAssignedTo,
                        displayText: _selectedAssignedTo.isEmpty
                            ? 'None'
                            : _selectedAssignedTo.length == 1
                                ? _siteUsers.firstWhere((u) => u.id == _selectedAssignedTo.first, orElse: () => _siteUsers.first).fullName
                                : '${_selectedAssignedTo.length} users selected',
                        onTap: () => _showUserSelector(),
                      ),
                      const SizedBox(height: 16),

                      // Tag (Multiple Selection)
                      _buildMultiSelectionField<int>(
                        label: 'Tag',
                        values: _selectedTagId,
                        displayText: _selectedTagId.isEmpty
                            ? 'None'
                            : _selectedTagId.length == 1
                                ? _tags.firstWhere((t) => t.id == _selectedTagId.first, orElse: () => _tags.first).name
                                : '${_selectedTagId.length} tags selected',
                        onTap: () => _showTagSelector(),
                      ),
                      const SizedBox(height: 16),

                      // Status (only editable when editing existing issue)
                      _buildSelectionField<String>(
                        label: 'Status',
                        value: _status,
                        displayText: _status,
                        onTap: widget.issue != null ? () => _showStatusSelector() : null,
                        isEnabled: widget.issue != null,
                      ),
                      const SizedBox(height: 16),

                      // Attachments
                      Text(
                        'Attachments',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildAttachmentsSection(),
                      const SizedBox(height: 24),

                      // Save Button
                      CustomButton(
                        text: widget.issue != null ? 'Update Issue' : 'Create Issue',
                        onPressed: _isSaving ? null : _saveIssue,
                        isLoading: _isSaving,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLinkTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildLinkTypeButton(
            label: 'Task',
            value: 'from_task',
            icon: Icons.task_outlined,
            color: AppColors.primaryColor,
          ),
          _buildLinkTypeButton(
            label: 'Site',
            value: 'from_site',
            icon: Icons.location_on_outlined,
            color: AppColors.infoColor,
          ),
          _buildLinkTypeButton(
            label: 'Material',
            value: 'from_material',
            icon: Icons.inventory_2_outlined,
            color: AppColors.warningColor,
          ),
          _buildLinkTypeButton(
            label: 'Other',
            value: 'other',
            icon: Icons.more_horiz,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTypeButton({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _linkType == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          // Dismiss keyboard when changing link type
          FocusScope.of(context).unfocus();
          setState(() {
            _linkType = value;
            _selectedTaskId = null;
            _selectedMaterialId = null;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: color, width: 2) : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: isSelected ? color : Colors.grey,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskSelector() {
    return _buildSelectionField<int>(
      label: 'Task',
      value: _selectedTaskId,
      displayText: _selectedTaskId != null
          ? _tasks.firstWhere((t) => t.id == _selectedTaskId, orElse: () => _tasks.first).name
          : 'Select Task',
      onTap: () => _showTaskSelector(),
      validator: (value) {
        if (_linkType == 'from_task' && value == null) {
          return 'Please select a task';
        }
        return null;
      },
    );
  }

  Widget _buildMaterialSelector() {
    return _buildSelectionField<int>(
      label: 'Material',
      value: _selectedMaterialId,
      displayText: _selectedMaterialId != null
          ? _materials.firstWhere((m) => m.id == _selectedMaterialId, orElse: () => _materials.first).name
          : 'Select Material',
      onTap: () => _showMaterialSelector(),
      validator: (value) {
        if (_linkType == 'from_material' && value == null) {
          return 'Please select a material';
        }
        return null;
      },
    );
  }

  Widget _buildMultiSelectionField<T>({
    required String label,
    required List<T> values,
    required String displayText,
    required VoidCallback? onTap,
    String? Function(List<T>)? validator,
    bool isEnabled = true,
  }) {
    return GestureDetector(
      onTap: isEnabled && onTap != null
          ? () {
              FocusScope.of(context).unfocus();
              onTap();
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 1,
          ),
        ),
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 12),
                child: Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayText,
                        style: AppTypography.bodyLarge.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (isEnabled)
                      Icon(
                        Icons.arrow_drop_down,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionField<T>({
    required String label,
    required T? value,
    required String displayText,
    required VoidCallback? onTap,
    String? Function(T?)? validator,
    bool isEnabled = true,
  }) {
    return GestureDetector(
      onTap: isEnabled && onTap != null
          ? () {
              FocusScope.of(context).unfocus();
              onTap();
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 1,
          ),
        ),
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 12),
                child: Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayText,
                        style: AppTypography.bodyLarge.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (isEnabled)
                      Icon(
                        Icons.arrow_drop_down,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTaskSelector() async {
    FocusScope.of(context).unfocus();
    
    final selectedTask = await showModalBottomSheet<TaskModel?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TaskSelectorModal(
        tasks: _tasks,
        selectedTaskId: _selectedTaskId,
      ),
    );

    if (selectedTask != null) {
      setState(() {
        _selectedTaskId = selectedTask.id;
      });
    }
  }

  Future<void> _showMaterialSelector() async {
    FocusScope.of(context).unfocus();
    
    final selectedMaterial = await showModalBottomSheet<MaterialModel?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MaterialSelectorModal(
        materials: _materials,
        selectedMaterialId: _selectedMaterialId,
      ),
    );

    if (selectedMaterial != null) {
      setState(() {
        _selectedMaterialId = selectedMaterial.id;
      });
    }
  }

  Future<void> _showUserSelector() async {
    FocusScope.of(context).unfocus();
    
    final selectedUserIds = await showModalBottomSheet<List<int>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UserSelectorModal(
        users: _siteUsers,
        selectedUserIds: _selectedAssignedTo,
        multipleSelection: true,
      ),
    );

    if (selectedUserIds != null) {
      setState(() {
        _selectedAssignedTo = selectedUserIds;
      });
    }
  }

  Future<void> _showTagSelector() async {
    FocusScope.of(context).unfocus();
    
    final selectedTagIds = await showModalBottomSheet<List<int>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TagSelectorModal(
        tags: _tags,
        selectedTagIds: _selectedTagId,
        multipleSelection: true,
      ),
    );

    if (selectedTagIds != null) {
      setState(() {
        _selectedTagId = selectedTagIds;
      });
    }
  }

  Future<void> _showStatusSelector() async {
    FocusScope.of(context).unfocus();
    
    final statuses = ['Open', 'working', 'QC', 'solved', 'done'];
    final selectedStatus = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StatusSelectorModal(
        statuses: statuses,
        selectedStatus: _status,
      ),
    );

    if (selectedStatus != null) {
      setState(() {
        _status = selectedStatus;
      });
    }
  }

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _pickAttachments,
          icon: const Icon(Icons.attach_file),
          label: const Text('Add Attachments'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        if (_selectedAttachments.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              _selectedAttachments.length,
              (index) => _buildAttachmentPreview(index),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAttachmentPreview(int index) {
    final file = _selectedAttachments[index];
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.insert_drive_file);
              },
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeAttachment(index),
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
  }
}

// Task Selector Modal
class _TaskSelectorModal extends StatefulWidget {
  final List<TaskModel> tasks;
  final int? selectedTaskId;

  const _TaskSelectorModal({
    required this.tasks,
    this.selectedTaskId,
  });

  @override
  State<_TaskSelectorModal> createState() => _TaskSelectorModalState();
}

class _TaskSelectorModalState extends State<_TaskSelectorModal> {
  late List<TaskModel> _filteredTasks;

  @override
  void initState() {
    super.initState();
    _filteredTasks = widget.tasks;
  }

  void _filterTasks(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTasks = widget.tasks;
      } else {
        _filteredTasks = widget.tasks
            .where((task) => task.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        Navigator.of(context).pop();
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'Select Task',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(
                          Icons.close,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CustomSearchBar(
                    hintText: 'Search tasks...',
                    onChanged: _filterTasks,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _filteredTasks.isEmpty
                      ? Center(
                          child: Text(
                            'No tasks found',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = _filteredTasks[index];
                            final isSelected = widget.selectedTaskId == task.id;
                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop(task);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryColor.withOpacity(0.1)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primaryColor
                                        : AppColors.borderColor,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        task.name,
                                        style: AppTypography.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        color: AppColors.primaryColor,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Material Selector Modal
class _MaterialSelectorModal extends StatefulWidget {
  final List<MaterialModel> materials;
  final int? selectedMaterialId;

  const _MaterialSelectorModal({
    required this.materials,
    this.selectedMaterialId,
  });

  @override
  State<_MaterialSelectorModal> createState() => _MaterialSelectorModalState();
}

class _MaterialSelectorModalState extends State<_MaterialSelectorModal> {
  late List<MaterialModel> _filteredMaterials;

  @override
  void initState() {
    super.initState();
    _filteredMaterials = widget.materials;
  }

  void _filterMaterials(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMaterials = widget.materials;
      } else {
        _filteredMaterials = widget.materials
            .where((material) => material.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        Navigator.of(context).pop();
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'Select Material',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(
                          Icons.close,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CustomSearchBar(
                    hintText: 'Search materials...',
                    onChanged: _filterMaterials,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _filteredMaterials.isEmpty
                      ? Center(
                          child: Text(
                            'No materials found',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredMaterials.length,
                          itemBuilder: (context, index) {
                            final material = _filteredMaterials[index];
                            final isSelected = widget.selectedMaterialId == material.id;
                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop(material);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryColor.withOpacity(0.1)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primaryColor
                                        : AppColors.borderColor,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        material.name,
                                        style: AppTypography.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        color: AppColors.primaryColor,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// User Selector Modal
class _UserSelectorModal extends StatefulWidget {
  final List<SiteUserModel> users;
  final List<int> selectedUserIds;
  final bool multipleSelection;

  const _UserSelectorModal({
    required this.users,
    required this.selectedUserIds,
    this.multipleSelection = false,
  });

  @override
  State<_UserSelectorModal> createState() => _UserSelectorModalState();
}

class _UserSelectorModalState extends State<_UserSelectorModal> {
  late List<int> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedUserIds);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        Navigator.of(context).pop();
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'Assign Users to Task',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(
                          Icons.close,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: widget.users.length,
                    itemBuilder: (context, index) {
                      final user = widget.users[index];
                      final isSelected = _selectedIds.contains(user.id);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedIds.remove(user.id);
                            } else {
                              _selectedIds.add(user.id);
                            }
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryColor.withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : AppColors.borderColor,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // User avatar
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: AppColors.primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // User info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.fullName,
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      user.email,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Assign/Remove button
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedIds.remove(user.id);
                                    } else {
                                      _selectedIds.add(user.id);
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.errorColor
                                        : AppColors.primaryColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isSelected ? 'Remove' : 'Assign',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Action buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: AppTypography.bodyMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Update Assignment (${_selectedIds.length})',
                          onPressed: () {
                            Navigator.of(context).pop(_selectedIds);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Tag Selector Modal
class _TagSelectorModal extends StatefulWidget {
  final List<TagModel> tags;
  final List<int> selectedTagIds;
  final bool multipleSelection;

  const _TagSelectorModal({
    required this.tags,
    required this.selectedTagIds,
    this.multipleSelection = false,
  });

  @override
  State<_TagSelectorModal> createState() => _TagSelectorModalState();
}

class _TagSelectorModalState extends State<_TagSelectorModal> {
  late List<int> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedTagIds);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        Navigator.of(context).pop();
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'Select Tags',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(
                          Icons.close,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: widget.tags.length,
                    itemBuilder: (context, index) {
                      final tag = widget.tags[index];
                      final isSelected = _selectedIds.contains(tag.id);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedIds.remove(tag.id);
                            } else {
                              _selectedIds.add(tag.id);
                            }
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryColor.withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : AppColors.borderColor,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  tag.name,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: AppColors.primaryColor,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Action buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: AppTypography.bodyMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Update Tags (${_selectedIds.length})',
                          onPressed: () {
                            Navigator.of(context).pop(_selectedIds);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Status Selector Modal
class _StatusSelectorModal extends StatelessWidget {
  final List<String> statuses;
  final String selectedStatus;

  const _StatusSelectorModal({
    required this.statuses,
    required this.selectedStatus,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        Navigator.of(context).pop();
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.7,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'Select Status',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(
                          Icons.close,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: statuses.length,
                    itemBuilder: (context, index) {
                      final status = statuses[index];
                      final isSelected = selectedStatus == status;
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop(status);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryColor.withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : AppColors.borderColor,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  status,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: AppColors.primaryColor,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

