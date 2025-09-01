import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/task_detail_model.dart';
import '../../models/question_model.dart';

class TaskDetailsUtils {
  // Survey Helper Methods
  static List<Question> initializeSurveyQuestions(TaskDetailModel? taskDetail) {
    return [
      Question(
        id: 1,
        question: "ANY ACCIDENTS ON SITE TODAY?",
        remark: _getRemark(taskDetail, 0, 'remark1'),
        answer: _getAnswer(taskDetail, 0, 'answer1'),
      ),
      Question(
        id: 2,
        question: "ANY SCHEDULES DELAY OCCURS?",
        remark: _getRemark(taskDetail, 0, 'remark2'),
        answer: _getAnswer(taskDetail, 0, 'answer2'),
      ),
      Question(
        id: 3,
        question: "DID WEATHER CAUSES ANY DELAY?",
        remark: _getRemark(taskDetail, 0, 'remark3'),
        answer: _getAnswer(taskDetail, 0, 'answer3'),
      ),
      Question(
        id: 4,
        question: "ANY VISITORS ON SITE?",
        remark: _getRemark(taskDetail, 0, 'remark4'),
        answer: _getAnswer(taskDetail, 0, 'answer4'),
      ),
      Question(
        id: 5,
        question: "ANY AREA THAT CAN'T BE WORKED ON?",
        remark: _getRemark(taskDetail, 0, 'remark5'),
        answer: _getAnswer(taskDetail, 0, 'answer5'),
      ),
    ];
  }

  static String _getRemark(TaskDetailModel? taskDetail, int index, String remarkField) {
    if (taskDetail?.progressDetails.isNotEmpty == true &&
        taskDetail!.progressDetails[index].taskQuestions.isNotEmpty) {
      final taskQuestion = taskDetail.progressDetails[index].taskQuestions[0];
      switch (remarkField) {
        case 'remark1':
          return taskQuestion.remark1 ?? "";
        case 'remark2':
          return taskQuestion.remark2 ?? "";
        case 'remark3':
          return taskQuestion.remark3 ?? "";
        case 'remark4':
          return taskQuestion.remark4 ?? "";
        case 'remark5':
          return taskQuestion.remark5 ?? "";
        default:
          return "";
      }
    }
    return "";
  }

  static String _getAnswer(TaskDetailModel? taskDetail, int index, String answerField) {
    if (taskDetail?.progressDetails.isNotEmpty == true &&
        taskDetail!.progressDetails[index].taskQuestions.isNotEmpty) {
      final taskQuestion = taskDetail.progressDetails[index].taskQuestions[0];
      switch (answerField) {
        case 'answer1':
          return taskQuestion.answer1 ?? "";
        case 'answer2':
          return taskQuestion.answer2 ?? "";
        case 'answer3':
          return taskQuestion.answer3 ?? "";
        case 'answer4':
          return taskQuestion.answer4 ?? "";
        case 'answer5':
          return taskQuestion.answer5 ?? "";
        default:
          return "";
      }
    }
    return "";
  }

  static bool validateSurveyAnswers(List<Question> surveyQuestions) {
    for (var question in surveyQuestions) {
      if (question.answer == null || question.answer!.isEmpty) {
        return false;
      }
    }
    return true;
  }

  static Map<String, dynamic> questionsToListOfMaps(List<Question> questions) {
    Map<String, dynamic> combinedMap = {};
    for (var question in questions) {
      combinedMap['question_${question.id}'] = question.question;
      combinedMap['answer_${question.id}'] = question.answer ?? '';
      combinedMap['remark_${question.id}'] = question.remark;
    }
    return combinedMap;
  }

  static bool hasSurveyChanges(List<Question> surveyQuestions, Map<String, dynamic> previousAnswers) {
    Map<String, dynamic> currentAnswers = questionsToListOfMaps(surveyQuestions);
    return !mapEquals(previousAnswers, currentAnswers);
  }

  // Date formatting utility
  static String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return '';
    }

    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      final month = months[date.month - 1];
      final day = date.day;
      final year = date.year;

      return '$month $day, $year';
    } catch (e) {
      return dateString;
    }
  }

  // Status color utility
  static Color getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'active':
        return AppColors.primaryColor;
      case 'complete':
        return Colors.green;
      case 'overdue':
        return AppColors.errorColor;
      default:
        return AppColors.textSecondary;
    }
  }

  // Empty state widget
  static Widget buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            SizedBox(height: 12),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // App bar title utility
  static String getAppBarTitle(TaskDetailModel? taskDetail) {
    if (taskDetail == null) return 'Task Details';

    final taskName = taskDetail.name;
    final progress = taskDetail.progress;

    if (progress != null) {
      return '$taskName - $progress%';
    }

    return taskName;
  }
}
