import 'dart:convert';
import 'package:flutter/material.dart';

import 'material_model.dart';
import 'user_model.dart';
import 'unified_image_model.dart';
import 'unified_attachment_model.dart';
import 'tag_model.dart';

class TaskDetailModel {
  final int id;
  final String name;
  final String? notes;
  final String? comment;
  final int siteId;
  final int createdBy;
  final String? assignTo;
  final String? startDate;
  final String? endDate;
  final int? progress;
  final int totalWorkDone;
  final int totalWork;
  final int categoryId;
  final String? voiceNote;
  final String? totalPrice;
  final String? tag;
  final String status;
  final String unit;
  final String? decisionByAgency;
  final String? decisionPendingOther;
  final String? completionDate;
  final String? decisionPendingFrom;
  final int? qcCategoryId;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final List<TagModel> tagsData;
  final String categoryName;
  final int catSubId;
  final List<String> assignedUserName;
  final String? qcPdf;
  final String? voiceNotePath;
  final UserModel createdUser;
  final List<TaskImageModel> images;
  final List<TaskInstructionModel> instructions;
  final List<ProgressDetailModel> progressDetails;
  final List<String> attachments;
  final List<TaskRemarkModel> remarks;
  final List<String> voiceNotes;
  final List<TaskCommentModel> comments;
  final List<QualityCheckModel> qualityChecks;

  TaskDetailModel({
    required this.id,
    required this.name,
    this.notes,
    this.comment,
    required this.siteId,
    required this.createdBy,
    this.assignTo,
    this.startDate,
    this.endDate,
    this.progress,
    required this.totalWorkDone,
    required this.totalWork,
    required this.categoryId,
    this.voiceNote,
    this.totalPrice,
    this.tag,
    required this.status,
    required this.unit,
    this.decisionByAgency,
    this.decisionPendingOther,
    this.completionDate,
    this.decisionPendingFrom,
    this.qcCategoryId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.tagsData = const [],
    required this.categoryName,
    required this.catSubId,
    required this.assignedUserName,
    this.qcPdf,
    this.voiceNotePath,
    required this.createdUser,
    required this.images,
    required this.instructions,
    required this.progressDetails,
    required this.attachments,
    required this.remarks,
    required this.voiceNotes,
    required this.comments,
    required this.qualityChecks,
  });


  factory TaskDetailModel.fromJson(Map<String, dynamic> json) {
    return TaskDetailModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      notes: json['notes'],
      comment: json['comment'],
      siteId: json['site_id'] ?? 0,
      createdBy: json['created_by'] ?? 0,
      assignTo: json['assign_to'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      progress: json['progress'],
      totalWorkDone: json['total_work_done'] ?? 0,
      totalWork: json['total_work'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      voiceNote: json['voice_note'],
      totalPrice: json['total_price'],
      tag: json['tag'],
      status: json['status'] ?? '',
      unit: json['unit'] ?? '',
      decisionByAgency: json['decision_by_agency'],
      decisionPendingOther: json['decision_pending_other'],
      completionDate: json['completion_date'],
      decisionPendingFrom: json['decision_pending_from'],
      qcCategoryId: json['qc_category_id'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
      tagsData: (json['tags_data'] as List<dynamic>?)
          ?.map((tag) => TagModel.fromJson(tag))
          .toList() ?? [],
      categoryName: json['category_name'] ?? '',
      catSubId: json['cat_sub_id'] ?? 0,
      assignedUserName: (json['assigned_user_name'] as List<dynamic>?)
          ?.map((name) => name.toString())
          .toList() ?? [],
      qcPdf: json['qc_pdf'],
      voiceNotePath: json['voice_note_path'],
      createdUser: UserModel.fromJson(json['createduser'] ?? {}),
      images: (json['images'] as List<dynamic>?)
          ?.map((image) => TaskImageModel.fromJson(image))
          .toList() ?? [],
      instructions: (json['instructions'] as List<dynamic>?)
          ?.map((instruction) => TaskInstructionModel.fromJson(instruction))
          .toList() ?? [],
      progressDetails: (json['progress_details'] as List<dynamic>?)
          ?.map((detail) => ProgressDetailModel.fromJson(detail))
          .toList() ?? [],
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((attachment) {
            if (attachment is Map<String, dynamic>) {
              return (attachment['attachment_path'] ?? attachment['attechment_path'] ?? attachment.toString()) as String;
            }
            return attachment.toString();
          })
          .toList() ?? [],
      remarks: (json['remarks'] as List<dynamic>?)
          ?.map((remark) => TaskRemarkModel.fromJson(remark))
          .toList() ?? [],
      voiceNotes: (json['voice_notes'] as List<dynamic>?)
          ?.map((note) => note.toString())
          .toList() ?? [],
      comments: (json['comments'] as List<dynamic>?)
          ?.map((comment) => TaskCommentModel.fromJson(comment))
          .toList() ?? [],
      qualityChecks: (json['quality_checks'] as List<dynamic>?)
          ?.map((check) => QualityCheckModel.fromJson(check))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'notes': notes,
      'comment': comment,
      'site_id': siteId,
      'created_by': createdBy,
      'assign_to': assignTo,
      'start_date': startDate,
      'end_date': endDate,
      'progress': progress,
      'total_work_done': totalWorkDone,
      'total_work': totalWork,
      'category_id': categoryId,
      'voice_note': voiceNote,
      'total_price': totalPrice,
      'tag': tag,
      'status': status,
      'unit': unit,
      'decision_by_agency': decisionByAgency,
      'decision_pending_other': decisionPendingOther,
      'completion_date': completionDate,
      'decision_pending_from': decisionPendingFrom,
      'qc_category_id': qcCategoryId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'tags_data': tagsData.map((tag) => tag.toJson()).toList(),
      'category_name': categoryName,
      'cat_sub_id': catSubId,
      'assigned_user_name': assignedUserName,
      'qc_pdf': qcPdf,
      'voice_note_path': voiceNotePath,
      'createduser': createdUser.toJson(),
      'images': images,
      'instructions': instructions,
      'progress_details': progressDetails.map((detail) => detail.toJson()).toList(),
      'attachments': attachments,
      'remarks': remarks,
      'voice_notes': voiceNotes,
      'comments': comments,
      'quality_checks': qualityChecks,
    };
  }

  // Helper getters for task type identification
  bool get isSiteSurvey => catSubId == 1;
  bool get isSpecialTask => [2, 3, 4, 6].contains(catSubId);
  bool get isNormalTask => catSubId == 5;
  
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isActive => status.toLowerCase() == 'active';
  bool get isComplete => status.toLowerCase() == 'complete';
  bool get isOverdue => status.toLowerCase() == 'overdue';
  
  double get progressPercentage => progress?.toDouble() ?? 0.0;

  TaskDetailModel copyWith({
    int? id,
    String? name,
    String? notes,
    String? comment,
    int? siteId,
    int? createdBy,
    String? assignTo,
    String? startDate,
    String? endDate,
    int? progress,
    int? totalWorkDone,
    int? totalWork,
    int? categoryId,
    String? voiceNote,
    String? totalPrice,
    String? tag,
    String? status,
    String? unit,
    String? decisionByAgency,
    String? decisionPendingOther,
    String? completionDate,
    String? decisionPendingFrom,
    int? qcCategoryId,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
    List<TagModel>? tagsData,
    String? categoryName,
    int? catSubId,
    List<String>? assignedUserName,
    String? qcPdf,
    String? voiceNotePath,
    UserModel? createdUser,
    List<TaskImageModel>? images,
    List<TaskInstructionModel>? instructions,
    List<ProgressDetailModel>? progressDetails,
    List<String>? attachments,
    List<TaskRemarkModel>? remarks,
    List<String>? voiceNotes,
    List<TaskCommentModel>? comments,
    List<QualityCheckModel>? qualityChecks,
  }) {
    return TaskDetailModel(
      id: id ?? this.id,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      comment: comment ?? this.comment,
      siteId: siteId ?? this.siteId,
      createdBy: createdBy ?? this.createdBy,
      assignTo: assignTo ?? this.assignTo,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      progress: progress ?? this.progress,
      totalWorkDone: totalWorkDone ?? this.totalWorkDone,
      totalWork: totalWork ?? this.totalWork,
      categoryId: categoryId ?? this.categoryId,
      voiceNote: voiceNote ?? this.voiceNote,
      totalPrice: totalPrice ?? this.totalPrice,
      tag: tag ?? this.tag,
      status: status ?? this.status,
      unit: unit ?? this.unit,
      decisionByAgency: decisionByAgency ?? this.decisionByAgency,
      decisionPendingOther: decisionPendingOther ?? this.decisionPendingOther,
      completionDate: completionDate ?? this.completionDate,
      decisionPendingFrom: decisionPendingFrom ?? this.decisionPendingFrom,
      qcCategoryId: qcCategoryId ?? this.qcCategoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      tagsData: tagsData ?? this.tagsData,
      categoryName: categoryName ?? this.categoryName,
      catSubId: catSubId ?? this.catSubId,
      assignedUserName: assignedUserName ?? this.assignedUserName,
      qcPdf: qcPdf ?? this.qcPdf,
      voiceNotePath: voiceNotePath ?? this.voiceNotePath,
      createdUser: createdUser ?? this.createdUser,
      images: images ?? this.images,
      instructions: instructions ?? this.instructions,
      progressDetails: progressDetails ?? this.progressDetails,
      attachments: attachments ?? this.attachments,
      remarks: remarks ?? this.remarks,
      voiceNotes: voiceNotes ?? this.voiceNotes,
      comments: comments ?? this.comments,
      qualityChecks: qualityChecks ?? this.qualityChecks,
    );
  }

  // Helper methods for tags
  List<String> get parsedTags {
    if (tagsData.isEmpty) {
      return [];
    }
    
    // tagsData is a List<TagModel>, so just get the names
    return tagsData.map((tag) => tag.name).toList();
  }

  String get displayTags {
    final tagNames = parsedTags;
    if (tagNames.isEmpty) {
      return 'No tags';
    }
    return tagNames.join(', ');
  }

  // Get tag IDs for API calls
  List<int> get tagIds {
    return tagsData.map((tag) => tag.id).toList();
  }
}

class UsedMaterialModel {
  final int id;
  final int materialId;
  final MaterialModel material;
  final int? siteId;
  final String type;
  final String quantity;
  final String? price;
  final int userId;
  final String? description;
  final int progressId;
  final String? currentStock;
  final int? grnId;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  UsedMaterialModel({
    required this.id,
    required this.materialId,
    required this.material,
    this.siteId,
    required this.type,
    required this.quantity,
    this.price,
    required this.userId,
    this.description,
    required this.progressId,
    this.currentStock,
    this.grnId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory UsedMaterialModel.fromJson(Map<String, dynamic> json) {
    return UsedMaterialModel(
      id: json['id'] ?? 0,
      materialId: json['material_id'] ?? 0,
      material: MaterialModel.fromJson(json['material'] ?? {}),

      siteId: json['site_id'] is int ? json['site_id'] : null,
      type: json['type'] ?? '',
      quantity: (json['quantity'] ?? '').toString(),
      price: json['price']?.toString(),
      userId: json['user_id'] ?? 0,
      description: json['description'],
      progressId: json['progress_id'] ?? 0,
      currentStock: json['current_stock']?.toString(),
      grnId: json['grn_id'] is int ? json['grn_id'] : null,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'material_id': materialId,
      'material': material.toJson(),
      'site_id': siteId,
      'type': type,
      'quantity': quantity,
      'price': price,
      'user_id': userId,
      'description': description,
      'progress_id': progressId,
      'current_stock': currentStock,
      'grn_id': grnId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }
}

class ProgressDetailModel {
  final int id;
  final String workDone;
  final String? workLeft;
  final String? skillWorkers;
  final String? unskillWorkers;
  final String? voiceNote;
  final String? remark;
  final String? comment;
  final int taskId;
  final int userId;
  final String? instruction;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String? voiceNotePath;
  final UserModel user;
  final List<ProgressImageModel> progressImages;
  final List<TaskQuestionModel> taskQuestions;
  final List<UsedMaterialModel> usedMaterial;
  final Map<String, dynamic>? company;

  ProgressDetailModel({
    required this.id,
    required this.workDone,
    this.workLeft,
    this.skillWorkers,
    this.unskillWorkers,
    this.voiceNote,
    this.remark,
    this.comment,
    required this.taskId,
    required this.userId,
    this.instruction,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.voiceNotePath,
    required this.user,
    required this.progressImages,
    required this.taskQuestions,
    required this.usedMaterial,
    this.company,
  });

  factory ProgressDetailModel.fromJson(Map<String, dynamic> json) {
    return ProgressDetailModel(
      id: json['id'] ?? 0,
      workDone: json['work_done'] ?? '',
      workLeft: json['work_left'],
      skillWorkers: json['skill_workers'],
      unskillWorkers: json['unskill_workers'],
      voiceNote: json['voice_note'],
      remark: json['remark'],
      comment: json['comment'],
      taskId: json['task_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      instruction: json['instruction'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
      voiceNotePath: json['voice_note_path'],
      user: UserModel.fromJson(json['user'] ?? {}),
      progressImages: (json['progress_images'] as List<dynamic>?)
          ?.map((image) => ProgressImageModel.fromJson(image))
          .toList() ?? [],
      taskQuestions: (json['task_questions'] as List<dynamic>?)
          ?.map((question) => TaskQuestionModel.fromJson(question))
          .toList() ?? [],
      usedMaterial: (json['used_material'] as List<dynamic>?)
          ?.map((material) => UsedMaterialModel.fromJson(material))
          .toList() ?? [],
      company: json['company'] != null && json['company'] is Map 
          ? Map<String, dynamic>.from(json['company']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'work_done': workDone,
      'work_left': workLeft,
      'skill_workers': skillWorkers,
      'unskill_workers': unskillWorkers,
      'voice_note': voiceNote,
      'remark': remark,
      'comment': comment,
      'task_id': taskId,
      'user_id': userId,
      'instruction': instruction,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'voice_note_path': voiceNotePath,
      'user': user.toJson(),
      'progress_images': progressImages,
      'task_questions': taskQuestions.map((question) => question.toJson()).toList(),
      'used_material': usedMaterial.map((material) => material.toJson()).toList(),
      'company': company,
    };
  }
}

class TaskQuestionModel {
  final int id;
  final int taskId;
  final int taskProgressId;
  final String question1;
  final String answer1;
  final String question2;
  final String answer2;
  final String question3;
  final String answer3;
  final String question4;
  final String answer4;
  final String question5;
  final String answer5;
  final String? remark1;
  final String? remark2;
  final String? remark3;
  final String? remark4;
  final String? remark5;

  TaskQuestionModel({
    required this.id,
    required this.taskId,
    required this.taskProgressId,
    required this.question1,
    required this.answer1,
    required this.question2,
    required this.answer2,
    required this.question3,
    required this.answer3,
    required this.question4,
    required this.answer4,
    required this.question5,
    required this.answer5,
    this.remark1,
    this.remark2,
    this.remark3,
    this.remark4,
    this.remark5,
  });

  factory TaskQuestionModel.fromJson(Map<String, dynamic> json) {
    return TaskQuestionModel(
      id: json['id'] ?? 0,
      taskId: json['task_id'] ?? 0,
      taskProgressId: json['task_progress_id'] ?? 0,
      question1: json['question_1'] ?? '',
      answer1: json['answer_1'] ?? '',
      question2: json['question_2'] ?? '',
      answer2: json['answer_2'] ?? '',
      question3: json['question_3'] ?? '',
      answer3: json['answer_3'] ?? '',
      question4: json['question_4'] ?? '',
      answer4: json['answer_4'] ?? '',
      question5: json['question_5'] ?? '',
      answer5: json['answer_5'] ?? '',
      remark1: json['remark_1'],
      remark2: json['remark_2'],
      remark3: json['remark_3'],
      remark4: json['remark_4'],
      remark5: json['remark_5'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'task_progress_id': taskProgressId,
      'question_1': question1,
      'answer_1': answer1,
      'question_2': question2,
      'answer_2': answer2,
      'question_3': question3,
      'answer_3': answer3,
      'question_4': question4,
      'answer_4': answer4,
      'question_5': question5,
      'answer_5': answer5,
      'remark_1': remark1,
      'remark_2': remark2,
      'remark_3': remark3,
      'remark_4': remark4,
      'remark_5': remark5,
    };
  }

  // Helper method to get questions and answers as a list
  List<Map<String, String?>> get questionsAndAnswers {
    return [
      {'question': question1, 'answer': answer1, 'remark': remark1},
      {'question': question2, 'answer': answer2, 'remark': remark2},
      {'question': question3, 'answer': answer3, 'remark': remark3},
      {'question': question4, 'answer': answer4, 'remark': remark4},
      {'question': question5, 'answer': answer5, 'remark': remark5},
    ];
  }
}

class TaskImageModel {
  final int id;
  final int taskId;
  final String image;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String imagePath;

  TaskImageModel({
    required this.id,
    required this.taskId,
    required this.image,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.imagePath,
  });

  factory TaskImageModel.fromJson(Map<String, dynamic> json) {
    return TaskImageModel(
      id: json['id'] ?? 0,
      taskId: json['task_id'] ?? 0,
      image: json['image'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
      imagePath: json['image_path'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'image': image,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'image_path': imagePath,
    };
  }
}

class TaskInstructionModel {
  final int id;
  final String instruction;
  final int userId;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final int taskId;
  final UserModel user;

  TaskInstructionModel({
    required this.id,
    required this.instruction,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.taskId,
    required this.user,
  });

  factory TaskInstructionModel.fromJson(Map<String, dynamic> json) {
    return TaskInstructionModel(
      id: json['id'] ?? 0,
      instruction: json['instruction'] ?? '',
      userId: json['user_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
      taskId: json['task_id'] ?? 0,
      user: UserModel.fromJson(json['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instruction': instruction,
      'user_id': userId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'task_id': taskId,
      'user': user.toJson(),
    };
  }
}

class TaskRemarkModel {
  final int id;
  final int taskId;
  final int userId;
  final String remark;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final UserModel user;

  TaskRemarkModel({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.remark,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.user,
  });

  factory TaskRemarkModel.fromJson(Map<String, dynamic> json) {
    return TaskRemarkModel(
      id: json['id'] ?? 0,
      taskId: json['task_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      remark: json['remark'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
      user: UserModel.fromJson(json['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'user_id': userId,
      'remark': remark,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'user': user.toJson(),
    };
  }
}

class TaskCommentModel {
  final int id;
  final int taskId;
  final int userId;
  final String comment;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final UserModel user;

  TaskCommentModel({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.user,
  });

  factory TaskCommentModel.fromJson(Map<String, dynamic> json) {
    return TaskCommentModel(
      id: json['id'] ?? 0,
      taskId: json['task_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      comment: json['comment'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
      user: UserModel.fromJson(json['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'user_id': userId,
      'comment': comment,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'user': user.toJson(),
    };
  }
}

class ProgressImageModel {
  final int id;
  final int taskProgressId;
  final String image;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String imagePath;

  ProgressImageModel({
    required this.id,
    required this.taskProgressId,
    required this.image,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.imagePath,
  });

  factory ProgressImageModel.fromJson(Map<String, dynamic> json) {
    return ProgressImageModel(
      id: json['id'] ?? 0,
      taskProgressId: json['task_progress_id'] ?? 0,
      image: json['image'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
      imagePath: json['image_path'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_progress_id': taskProgressId,
      'image': image,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'image_path': imagePath,
    };
  }
}

class QualityCheckModel {
  final int id;
  final int taskId;
  final String checkType;
  final String date;
  final String? clientTeamName;
  final String? pmcTeamName;
  final String? contractorTeamName;
  final int userId;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final List<QualityCheckItemModel> items;

  QualityCheckModel({
    required this.id,
    required this.taskId,
    required this.checkType,
    required this.date,
    this.clientTeamName,
    this.pmcTeamName,
    this.contractorTeamName,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.items,
  });

  factory QualityCheckModel.fromJson(Map<String, dynamic> json) {
    return QualityCheckModel(
      id: json['id'] ?? 0,
      taskId: json['task_id'] ?? 0,
      checkType: json['check_type'] ?? '',
      date: json['date'] ?? '',
      clientTeamName: json['client_team_name'],
      pmcTeamName: json['pmc_team_name'],
      contractorTeamName: json['contractor_team_name'],
      userId: json['user_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => QualityCheckItemModel.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'check_type': checkType,
      'date': date,
      'client_team_name': clientTeamName,
      'pmc_team_name': pmcTeamName,
      'contractor_team_name': contractorTeamName,
      'user_id': userId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  // Helper getters for check type
  bool get isPreCheck => checkType.toLowerCase() == 'pre';
  bool get isDuringCheck => checkType.toLowerCase() == 'during';
  bool get isAfterCheck => checkType.toLowerCase() == 'after';
}

// Extension to add unified images and attachments functionality to TaskDetailModel
extension TaskDetailModelExtension on TaskDetailModel {
  List<UnifiedImageModel> get allImages {
    final List<UnifiedImageModel> unifiedImages = [];
    
    // Add task images
    for (final image in images) {
      unifiedImages.add(UnifiedImageModel.fromTaskImage({
        'id': image.id,
        'image_path': image.imagePath,
        'created_at': image.createdAt,
        'updated_at': image.updatedAt,
        'deleted_at': image.deletedAt,
        'task_id': image.taskId,
      }));
    }
    
    // Add progress images
    for (final progress in progressDetails) {
      for (final progressImage in progress.progressImages) {
        unifiedImages.add(UnifiedImageModel.fromProgressImage({
          'id': progressImage.id,
          'image_path': progressImage.imagePath,
          'created_at': progressImage.createdAt,
          'updated_at': progressImage.updatedAt,
          'deleted_at': progressImage.deletedAt,
          'task_progress_id': progressImage.taskProgressId,
        }));
      }
    }
    
    return unifiedImages;
  }

  List<UnifiedAttachmentModel> get allAttachments {
    final List<UnifiedAttachmentModel> unifiedAttachments = [];
    
    // Add task attachments
    for (final attachment in attachments) {
      final unifiedAttachment = UnifiedAttachmentModel.fromTaskAttachment(attachment);
      unifiedAttachments.add(unifiedAttachment);
      print('Added attachment to allAttachments: ${unifiedAttachment.debugInfo}');
    }
    
    // Add progress attachments (if they exist in the future)
    // Note: Currently progress details don't have attachments field
    // This is ready for when the API includes progress attachments
    

    return unifiedAttachments;
  }
}

class QualityCheckItemModel {
  final int id;
  final int qualityCheckId;
  final String description;
  final String status;
  final String remarks;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  QualityCheckItemModel({
    required this.id,
    required this.qualityCheckId,
    required this.description,
    required this.status,
    required this.remarks,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory QualityCheckItemModel.fromJson(Map<String, dynamic> json) {
    return QualityCheckItemModel(
      id: json['id'] ?? 0,
      qualityCheckId: json['quality_check_id'] ?? 0,
      description: json['description'] ?? '',
      status: json['status'] ?? '',
      remarks: json['remarks'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quality_check_id': qualityCheckId,
      'description': description,
      'status': status,
      'remarks': remarks,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }

  // Helper getters for status
  bool get isPassed => status.toLowerCase() == 'yes';
  bool get isFailed => status.toLowerCase() == 'no';
}
