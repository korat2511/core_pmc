import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/qc_point_model.dart';
import '../models/task_detail_model.dart';
import '../models/api_response.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/custom_app_bar.dart';

class QcCreationScreen extends StatefulWidget {
  final String checkType;
  final int qcCategoryId;
  final int taskId;
  final QualityCheckModel? existingQc;
  final VoidCallback onQcCreated;

  const QcCreationScreen({
    super.key,
    required this.checkType,
    required this.qcCategoryId,
    required this.taskId,
    this.existingQc,
    required this.onQcCreated,
  });

  @override
  State<QcCreationScreen> createState() => _QcCreationScreenState();
}

class _QcCreationScreenState extends State<QcCreationScreen> {
  DateTime? _qcCreationDate;
  Map<String, Map<String, String>> _qcAnswers = {};
  bool _isCreatingQc = false;
  List<QcPointModel> _qcPoints = [];
  bool _isLoadingQcPoints = false;
  List<Map<String, dynamic>> _extraPoints = [];
  final TextEditingController _extraPointController = TextEditingController();
  bool _qcSubmissionSuccessful = false;

  @override
  void initState() {
    super.initState();
    _qcCreationDate = DateTime.now();
    _loadQcPoints();
    
    // If editing existing QC, populate the data
    if (widget.existingQc != null) {
      _populateExistingQcData();
    }
  }

  @override
  void dispose() {
    _extraPointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: widget.existingQc != null
                  ? 'Edit ${widget.checkType.toUpperCase()} QC'
                  : 'Create ${widget.checkType.toUpperCase()} QC',
          showBackButton: true,
          showDrawer: false,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date picker
              _buildQcDateField(),
              SizedBox(height: 10),


            Container(
alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _showAddExtraPointModal,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        size: 16,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Add Point',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),

            if (_isLoadingQcPoints)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            else if (_qcPoints.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No QC points available for this category',
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else ...[
                // Extra Points
                if (_extraPoints.isNotEmpty) ...[
                  SizedBox(height: 8),
                  ..._extraPoints.map((point) => _buildExtraPointItem(point)).toList(),
                ],

              if (_getQcQuestions(widget.checkType).isNotEmpty) ...[
                ..._getQcQuestions(widget.checkType).map((question) => _buildQcQuestionItem(question)).toList(),
              ]
            ],



            SizedBox(height: 12),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCreatingQc ? null : _submitQcCheck,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isCreatingQc
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                )
                    : Text(
                  widget.existingQc != null ? 'Update QC' : 'Submit QC',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            

          ],
        ),
      ),
    ));
  }

  Widget _buildQcDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QC Date',
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 3),
        GestureDetector(
          onTap: () async {
            final selectedDate = await showDatePicker(
              context: context,
              initialDate: _qcCreationDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (selectedDate != null) {
              setState(() {
                _qcCreationDate = selectedDate;
              });
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary, size: 16),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _qcCreationDate != null
                        ? '${_qcCreationDate!.day.toString().padLeft(2, '0')}-${_qcCreationDate!.month.toString().padLeft(2, '0')}-${_qcCreationDate!.year}'
                        : 'Select Date',
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 13,
                      color: _qcCreationDate != null
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQcQuestionItem(Map<String, dynamic> question) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        // color: Colors.red,
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.borderColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question['question'],
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12),

          // Yes/No/NA options
          Row(
            children: [
              _buildQcOptionButton(question['id'], 'yes', 'Yes', Icons.check_circle, Colors.green),
              SizedBox(width: 8),
              _buildQcOptionButton(question['id'], 'no', 'No', Icons.cancel, Colors.red),
              SizedBox(width: 8),
              _buildQcOptionButton(question['id'], 'na', 'NA', Icons.remove_circle, Colors.grey),
            ],
          ),

          SizedBox(height: 12),

          // Remarks field
          TextFormField(
            initialValue: _qcAnswers[question['id']]?['remarks'] ?? '',
            maxLines: 2,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: AppColors.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: AppColors.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
              hintText: 'Add remarks (optional)...',
              hintStyle: AppTypography.bodyMedium.copyWith(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onChanged: (value) {
              _updateQcAnswer(question['id'], 'remarks', value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQcOptionButton(String questionId, String value, String label, IconData icon, Color color) {
    final isSelected = _qcAnswers[questionId]?['answer'] == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          _updateQcAnswer(questionId, 'answer', value);
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? color : AppColors.borderColor,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadQcPoints() async {
    setState(() {
      _isLoadingQcPoints = true;
    });

    try {
      final String? apiToken = await LocalStorageService.getToken();
      if (apiToken == null) {
        SnackBarUtils.showError(
          context,
          message: 'Authentication token not found',
        );
        return;
      }

      final response = await ApiService.getQcPoints(
        apiToken: apiToken,
        type: widget.checkType,
        categoryId: widget.qcCategoryId,
      );

      if (mounted) {
        setState(() {
          _qcPoints = response.isSuccess ? response.points : [];
          _isLoadingQcPoints = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingQcPoints = false;
        });
        SnackBarUtils.showError(
          context,
          message: 'Failed to load QC points: $e',
        );
      }
    }
  }

  List<Map<String, dynamic>> _getQcQuestions(String checkType) {
    // Convert QcPointModel to the format expected by the UI
    // If editing existing QC, only show questions that haven't been answered yet
    if (widget.existingQc != null) {
      // Get all existing answered question IDs from the existing QC data
      final existingQc = widget.existingQc!;
      
      // Create a set of all existing QC item IDs and also check by question text
      final answeredQuestionIds = existingQc.items.map((item) => 'point_${item.id}').toSet();
      final answeredQuestionTexts = existingQc.items.map((item) => item.description.toLowerCase().trim()).toSet();
      
      // Debug logging
      print('🔍 === QC QUESTIONS DEBUG ===');
      print('📊 Total QC Points: ${_qcPoints.length}');
      print('📊 Existing QC Items: ${existingQc.items.length}');
      print('📊 Answered Question IDs: $answeredQuestionIds');
      print('📊 Answered Question Texts: $answeredQuestionTexts');
      
      // Filter out questions that are already answered in the existing QC
      // Check both by ID and by question text to avoid duplicates
      final filteredQuestions = _qcPoints.where((point) {
        final questionId = 'point_${point.id}';
        final questionText = point.point.toLowerCase().trim();
        
        final isAnsweredById = answeredQuestionIds.contains(questionId);
        final isAnsweredByText = answeredQuestionTexts.contains(questionText);
        final isAnswered = isAnsweredById || isAnsweredByText;
        
        print('   • Question: ${point.point}');
        print('     - ID: $questionId');
        print('     - Text: $questionText');
        print('     - Is Answered by ID: $isAnsweredById');
        print('     - Is Answered by Text: $isAnsweredByText');
        print('     - Final Is Answered: $isAnswered');
        
        return !isAnswered;
      }).map((point) => {
        'id': 'point_${point.id}',
        'question': point.point,
      }).toList();
      
      print('📊 Filtered Questions: ${filteredQuestions.length}');
      print('🔍 === END DEBUG ===');
      
      return filteredQuestions;
    } else {
      // For new QC, show all questions
      return _qcPoints.map((point) => {
        'id': 'point_${point.id}',
        'question': point.point,
      }).toList();
    }
  }

  void _updateQcAnswer(String questionId, String field, String value) {
    setState(() {
      if (!_qcAnswers.containsKey(questionId)) {
        _qcAnswers[questionId] = {};
      }
      _qcAnswers[questionId]![field] = value;
    });
  }

  Future<void> _submitQcCheck() async {
    // Validate required fields
    if (_qcCreationDate == null) {
      SnackBarUtils.showError(context, message: 'Please select a QC date');
      return;
    }

    setState(() {
      _isCreatingQc = true;
      _qcSubmissionSuccessful = false; // Reset success flag
    });

    try {
      // Get all questions (regular + extra) and filter only answered ones
      final allQuestions = [
        ..._getQcQuestions(widget.checkType),
        ..._extraPoints,
      ];
      
      final answeredQuestions = allQuestions.where((question) {
        final answer = _qcAnswers[question['id']];
        return answer != null && answer['answer'] != null;
      }).toList();

      if (answeredQuestions.isEmpty) {
        SnackBarUtils.showError(
          context,
          message: 'Please answer at least one question',
        );
        return;
      }

      // Prepare data for API call
      final items = answeredQuestions.map((question) => {
        'description': question['question'],
        'status': _qcAnswers[question['id']]!['answer']!,
        'remarks': _qcAnswers[question['id']]?['remarks'] ?? '',
      }).toList();

      print('QC Data to send: $items'); // Debug: Show what data will be sent

      // Use task ID from widget
      final taskId = widget.taskId;
      
      // Determine if this is a create or update operation
      final isUpdate = widget.existingQc != null;
      
      print('Operation type: ${isUpdate ? "Update" : "Create"}');
      if (isUpdate) {
        print('Updating QC ID: ${widget.existingQc!.id}');
      }

      // Call the appropriate API based on operation type
      final apiToken = await LocalStorageService.getToken();
      if (apiToken == null) {
        SnackBarUtils.showError(context, message: 'Authentication token not found');
        return;
      }

      ApiResponse<Map<String, dynamic>> response;
      
      if (isUpdate) {
        // Update existing QC
        response = await ApiService.updateQualityCheck(
          apiToken: apiToken,
          taskId: taskId,
          checkType: widget.checkType,
          qualityCheckId: widget.existingQc!.id,
          date: _qcCreationDate!.toIso8601String().split('T')[0],
          items: items,
        );
      } else {
        // Create new QC
        response = await ApiService.storeQualityCheck(
          apiToken: apiToken,
          taskId: taskId,
          checkType: widget.checkType,
          date: _qcCreationDate!.toIso8601String().split('T')[0],
          items: items,
        );
      }

      if (response.isSuccess) {
        SnackBarUtils.showSuccess(
          context,
          message: isUpdate ? 'QC check updated successfully' : 'QC check created successfully',
        );
        widget.onQcCreated();
        // Set success flag to show Done button
        setState(() {
          _qcSubmissionSuccessful = true;
        });


        Navigator.pop(context);

      } else {
        SnackBarUtils.showError(
          context,
          message: response.message,
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Failed to create QC check: $e',
      );
    } finally {
      setState(() {
        _isCreatingQc = false;
      });
    }
  }

  void _showAddExtraPointModal() {
    _extraPointController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _buildAddExtraPointModal(),
      ),
    );
  }

  Widget _buildAddExtraPointModal() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Add Extra QC Point',
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Form
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                TextField(
                  controller: _extraPointController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter your QC point...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                    ),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  autofocus: true,
                ),

                SizedBox(height: 16),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addExtraPoint,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Add Point',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),
        ],
      ),
    );
  }

  void _addExtraPoint() {
    if (_extraPointController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, message: 'Please enter a QC point');
      return;
    }

    final newPoint = {
      'id': 'extra_${DateTime.now().millisecondsSinceEpoch}',
      'question': _extraPointController.text.trim(),
      'isExtra': true,
    };

    setState(() {
      _extraPoints.add(newPoint);
    });

    Navigator.pop(context);
    SnackBarUtils.showSuccess(context, message: 'Extra QC point added');
  }

  Widget _buildExtraPointItem(Map<String, dynamic> point) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        // color: Colors.red,
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.borderColor.withOpacity(0.3),
          width: 1,
        ),
      ),


      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            point['question'],
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12),

          // Yes/No/NA options
          Row(
            children: [
              _buildQcOptionButton(point['id'], 'yes', 'Yes', Icons.check_circle, Colors.green),
              SizedBox(width: 8),
              _buildQcOptionButton(point['id'], 'no', 'No', Icons.cancel, Colors.red),
              SizedBox(width: 8),
              _buildQcOptionButton(point['id'], 'na', 'NA', Icons.remove_circle, Colors.grey),
            ],
          ),

          SizedBox(height: 12),

          // Remarks field
          TextFormField(
            initialValue: _qcAnswers[point['id']]?['remarks'] ?? '',
            maxLines: 2,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: AppColors.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: AppColors.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
              hintText: 'Add remarks (optional)...',
              hintStyle: AppTypography.bodyMedium.copyWith(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onChanged: (value) {
              _updateQcAnswer(point['id'], 'remarks', value);
            },
          ),
        ],
      ),

    );
  }

  void _removeExtraPoint(String pointId) {
    setState(() {
      _extraPoints.removeWhere((point) => point['id'] == pointId);
      _qcAnswers.remove(pointId);
    });
    SnackBarUtils.showSuccess(context, message: 'Extra QC point removed');
  }

  void _populateExistingQcData() {
    if (widget.existingQc == null) return;
    
    final qc = widget.existingQc!;
    
    // Set the date
    setState(() {
      _qcCreationDate = DateTime.parse(qc.date);
    });
    
    // Populate answers from existing QC items
    for (final item in qc.items) {
      final questionId = 'point_${item.id}';
      _qcAnswers[questionId] = {
        'answer': item.status,
        'remarks': item.remarks ?? '',
      };
    }
    
    print('🔍 === POPULATE EXISTING QC DEBUG ===');
    print('📊 Total Existing Items: ${qc.items.length}');
    print('📊 Standard QC Points Count: ${_qcPoints.length}');
    print('📊 Standard QC Point IDs: ${_qcPoints.map((p) => 'point_${p.id}').toSet()}');
    print('📊 Existing Item IDs: ${qc.items.map((item) => 'point_${item.id}').toSet()}');
    print('🔍 === END POPULATE DEBUG ===');
    
    // Add existing items as extra points ONLY if they're truly extra
    // First, identify which items are from standard QC points
    final standardQuestionIds = _qcPoints.map((p) => 'point_${p.id}').toSet();
    
    // Only add as extra if the item is NOT from standard QC points
    final extraItems = qc.items.where((item) {
      final questionId = 'point_${item.id}';
      return !standardQuestionIds.contains(questionId);
    }).toList();
    
    print('🔍 === EXTRA POINTS DEBUG ===');
    print('📊 Standard Question IDs: $standardQuestionIds');
    print('📊 Found Extra Items: ${extraItems.length}');
    
    for (final item in extraItems) {
      print('   • Extra Item: ${item.description}');
      final extraPoint = {
        'id': 'point_${item.id}',
        'question': item.description,
        'remarks': item.remarks ?? '',
        'isExtra': true,
      };
      _extraPoints.add(extraPoint);
      
      // Set the answer for this extra point
      _qcAnswers['point_${item.id}'] = {
        'answer': item.status,
        'remarks': item.remarks ?? '',
      };
    }
    print('🔍 === END EXTRA POINTS DEBUG ===');
  }



  Color _getAnswerColor(String? answer) {
    switch (answer?.toLowerCase()) {
      case 'yes':
        return Colors.green;
      case 'no':
        return Colors.red;
      case 'na':
        return Colors.grey;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }
}