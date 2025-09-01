import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../models/question_model.dart';

// State holder class for question expansion
class _QuestionStateHolder {
  bool isRemarksExpanded = false;
}

class TaskSurveyForm extends StatefulWidget {
  final List<Question> surveyQuestions;
  final Map<String, dynamic> previousAnswers;
  final Function(List<Question>) onQuestionsChanged;
  final String? surveyErrorMessage;

  const TaskSurveyForm({
    super.key,
    required this.surveyQuestions,
    required this.previousAnswers,
    required this.onQuestionsChanged,
    this.surveyErrorMessage,
  });

  @override
  State<TaskSurveyForm> createState() => _TaskSurveyFormState();
}

class _TaskSurveyFormState extends State<TaskSurveyForm> {
  // Map to store state holders for each question
  final Map<int, _QuestionStateHolder> _questionStateHolders = {};

  // Get or create state holder for a question
  _QuestionStateHolder _getQuestionStateHolder(int questionId) {
    if (!_questionStateHolders.containsKey(questionId)) {
      _questionStateHolders[questionId] = _QuestionStateHolder();
    }
    return _questionStateHolders[questionId]!;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Questions
        ...widget.surveyQuestions
            .map((question) => _buildQuestionItem(question))
            .toList(),

        if (widget.surveyErrorMessage != null) ...[
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.error),
            ),
            child: Text(
              widget.surveyErrorMessage!,
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuestionItem(Question question) {
    // Create a persistent state holder for this question
    final stateHolder = _getQuestionStateHolder(question.id);
    
    return StatefulBuilder(
      builder: (context, setLocalState) {
        // Use the persistent state holder
        bool isRemarksExpanded = stateHolder.isRemarksExpanded;
        
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row: Question + Yes/No options
              Row(
                children: [
                  // Question badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Q${question.id}',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  // Question text
                  Expanded(
                    child: Text(
                      question.question,
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  // Yes/No buttons
                  Row(
                    children: [
                      // Yes button
                      GestureDetector(
                        onTap: () {
                          setLocalState(() {
                            question.answer = 'Yes';
                          });
                          widget.onQuestionsChanged(widget.surveyQuestions);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                question.answer == 'Yes' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                color: question.answer == 'Yes' ? Colors.green : Theme.of(context).colorScheme.onSurfaceVariant,
                                size: 15,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Yes',
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 13,
                                  color: question.answer == 'Yes' ? Colors.green : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // No button
                      GestureDetector(
                        onTap: () {
                          setLocalState(() {
                            question.answer = 'No';
                          });
                          widget.onQuestionsChanged(widget.surveyQuestions);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                question.answer == 'No' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                color: question.answer == 'No' ? Colors.red : Theme.of(context).colorScheme.onSurfaceVariant,
                                size: 15,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'No',
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 14,
                                  color: question.answer == 'No' ? Colors.red : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
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

              // Expandable Remarks Section
              SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  log("Tapped == ");
                  setLocalState(() {
                    stateHolder.isRemarksExpanded = !stateHolder.isRemarksExpanded;
                  });
                  log("Tapped == ${stateHolder.isRemarksExpanded}");
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Remarks (Optional)',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Spacer(),
                      Icon(
                        isRemarksExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),

              // Expandable Remarks TextField
              if (isRemarksExpanded) ...[
                SizedBox(height: 8),
                TextFormField(
                  initialValue: question.remark,
                  maxLines: 3,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    hintText: 'Add any additional remarks...',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onChanged: (value) {
                    setLocalState(() {
                      question.remark = value;
                    });
                    widget.onQuestionsChanged(widget.surveyQuestions);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
