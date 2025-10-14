import 'dart:convert';

class MeetingDiscussionModel {
  final int id;
  final int meetingId;
  final String discussionAction;
  final String actionBy;
  final String remarks;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final MeetingAttachmentModel? meetingAttachment;

  MeetingDiscussionModel({
    required this.id,
    required this.meetingId,
    required this.discussionAction,
    required this.actionBy,
    required this.remarks,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.meetingAttachment,
  });

  factory MeetingDiscussionModel.fromJson(Map<String, dynamic> json) {
    return MeetingDiscussionModel(
      id: json['id'] ?? 0,
      meetingId: json['meeting_id'] ?? 0,
      discussionAction: json['discussion_action'] ?? '',
      actionBy: json['action_by'] ?? '',
      remarks: json['remarks'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
      meetingAttachment: json['meeting_attachment'] != null 
          ? MeetingAttachmentModel.fromJson(json['meeting_attachment'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meeting_id': meetingId,
      'discussion_action': discussionAction,
      'action_by': actionBy,
      'remarks': remarks,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'meeting_attachment': meetingAttachment?.toJson(),
    };
  }
}

class MeetingAttachmentModel {
  final int id;
  final int meetingDiscussionId;
  final String file;
  final String filePath;

  MeetingAttachmentModel({
    required this.id,
    required this.meetingDiscussionId,
    required this.file,
    required this.filePath,
  });

  factory MeetingAttachmentModel.fromJson(Map<String, dynamic> json) {
    return MeetingAttachmentModel(
      id: json['id'] ?? 0,
      meetingDiscussionId: json['meeting_discussion_id'] ?? 0,
      file: json['file'] ?? '',
      filePath: json['file_path'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meeting_discussion_id': meetingDiscussionId,
      'file': file,
      'file_path': filePath,
    };
  }
}

class MeetingModel {
  final int id;
  final int siteId;
  final List<String> clients;
  final int userId;
  final List<String> architects;
  final List<String> pmcMembers;
  final List<String> contractors;
  final String architectCompany;
  final String meetingDateTime;
  final String? meetingPlace;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String pdfReportUrl;
  final String? voiceNoteUrl;
  final List<MeetingDiscussionModel> meetingDiscussions;

  MeetingModel({
    required this.id,
    required this.siteId,
    required this.clients,
    required this.userId,
    required this.architects,
    required this.pmcMembers,
    required this.contractors,
    required this.architectCompany,
    required this.meetingDateTime,
    this.meetingPlace,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.pdfReportUrl,
    this.voiceNoteUrl,
    required this.meetingDiscussions,
  });

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id: json['id'] ?? 0,
      siteId: json['site_id'] ?? 0,
      clients: _parseStringList(json['clients']),
      userId: json['user_id'] ?? 0,
      architects: _parseStringList(json['architects']),
      pmcMembers: _parseStringList(json['pmc_members']),
      contractors: _parseStringList(json['contractors']),
      architectCompany: json['architect_company'] ?? '',
      meetingDateTime: json['meeting_date_time'] ?? '',
      meetingPlace: json['meeting_place'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
      pdfReportUrl: json['pdf_report_url'] ?? '',
      voiceNoteUrl: json['voice_note_url'],
      meetingDiscussions: (json['meeting_discussions'] as List<dynamic>?)
              ?.map((item) => MeetingDiscussionModel.fromJson(item))
              .toList() ??
          [],
    );
  }

  // Helper method to parse string list (handles both JSON string and array)
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    
    // If it's already a list, convert it to List<String>
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    
    // If it's a string, try to parse it as JSON
    if (value is String) {
      try {
        // Remove any extra whitespace
        final trimmed = value.trim();
        
        // If it's an empty string or "[]", return empty list
        if (trimmed.isEmpty || trimmed == '[]') return [];
        
        // Try to parse as JSON
        final decoded = jsonDecode(trimmed);
        if (decoded is List) {
          return decoded.map((item) => item.toString()).toList();
        }
      } catch (e) {
        print('Error parsing string list: $e, value: $value');
        return [];
      }
    }
    
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_id': siteId,
      'clients': clients,
      'user_id': userId,
      'architects': architects,
      'pmc_members': pmcMembers,
      'contractors': contractors,
      'architect_company': architectCompany,
      'meeting_date_time': meetingDateTime,
      'meeting_place': meetingPlace,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'pdf_report_url': pdfReportUrl,
      'voice_note_url': voiceNoteUrl,
      'meeting_discussions': meetingDiscussions.map((d) => d.toJson()).toList(),
    };
  }

  // Helper methods
  DateTime get meetingDate {
    try {
      return DateTime.parse(meetingDateTime);
    } catch (e) {
      return DateTime.now();
    }
  }

  String get formattedDate {
    final date = meetingDate;
    return '${date.day}/${date.month}/${date.year}';
  }

  String get formattedTime {
    final date = meetingDate;
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String get participantsSummary {
    final allParticipants = <String>[];
    allParticipants.addAll(clients);
    allParticipants.addAll(architects);
    allParticipants.addAll(pmcMembers);
    allParticipants.addAll(contractors.where((c) => c != 'NA'));
    
    if (allParticipants.isEmpty) return 'No participants';
    if (allParticipants.length <= 3) return allParticipants.join(', ');
    return '${allParticipants.take(3).join(', ')} +${allParticipants.length - 3} more';
  }
}

class MeetingListResponse {
  final int status;
  final String message;
  final List<MeetingModel> meetingList;

  MeetingListResponse({
    required this.status,
    required this.message,
    required this.meetingList,
  });

  factory MeetingListResponse.fromJson(Map<String, dynamic> json) {
    return MeetingListResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      meetingList: (json['meeting_list'] as List<dynamic>?)
              ?.map((item) => MeetingModel.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class MeetingDetailResponse {
  final int status;
  final String message;
  final MeetingModel meetingDetail;

  MeetingDetailResponse({
    required this.status,
    required this.message,
    required this.meetingDetail,
  });

  factory MeetingDetailResponse.fromJson(Map<String, dynamic> json) {
    return MeetingDetailResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      meetingDetail: MeetingModel.fromJson(json['meeting_detail'] ?? {}),
    );
  }
}
