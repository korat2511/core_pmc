class AttendanceCheckModel {
  final int status;
  final AttendanceDataModel? data;
  final AttendanceDataModel? lastAttendance;
  final String flag;

  AttendanceCheckModel({
    required this.status,
    this.data,
    this.lastAttendance,
    required this.flag,
  });

  factory AttendanceCheckModel.fromJson(Map<String, dynamic> json) {
    return AttendanceCheckModel(
      status: json['status'] ?? 0,
      data: json['data'] != null ? AttendanceDataModel.fromJson(json['data']) : null,
      lastAttendance: json['lastAttendance'] != null ? AttendanceDataModel.fromJson(json['lastAttendance']) : null,
      flag: json['flag'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data?.toJson(),
      'lastAttendance': lastAttendance?.toJson(),
      'flag': flag,
    };
  }
}

class AttendanceDataModel {
  final int id;
  final String date;
  final int userId;
  final String inTime;
  final String? remark;
  final String? latitudeIn;
  final String? latitudeOut;
  final String? longitudeIn;
  final String? longitudeOut;
  final String? outTime;
  final String? addressIn;
  final String? addressOut;
  final String createdAt;
  final int? siteId;
  final String updatedAt;
  final String? deletedAt;

  AttendanceDataModel({
    required this.id,
    required this.date,
    required this.userId,
    required this.inTime,
    this.remark,
    this.latitudeIn,
    this.latitudeOut,
    this.longitudeIn,
    this.longitudeOut,
    this.outTime,
    this.addressIn,
    this.addressOut,
    required this.createdAt,
    this.siteId,
    required this.updatedAt,
    this.deletedAt,
  });

  factory AttendanceDataModel.fromJson(Map<String, dynamic> json) {
    return AttendanceDataModel(
      id: json['id'] ?? 0,
      date: json['date'] ?? '',
      userId: json['user_id'] ?? 0,
      inTime: json['in_time'] ?? '',
      remark: json['remark'],
      latitudeIn: json['latitude_in'],
      latitudeOut: json['latitude_out'],
      longitudeIn: json['longitude_in'],
      longitudeOut: json['longitude_out'],
      outTime: json['out_time'],
      addressIn: json['address_in'],
      addressOut: json['address_out'],
      createdAt: json['created_at'] ?? '',
      siteId: json['site_id'],
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'user_id': userId,
      'in_time': inTime,
      'remark': remark,
      'latitude_in': latitudeIn,
      'latitude_out': latitudeOut,
      'longitude_in': longitudeIn,
      'longitude_out': longitudeOut,
      'out_time': outTime,
      'address_in': addressIn,
      'address_out': addressOut,
      'created_at': createdAt,
      'site_id': siteId,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }

  bool get hasCheckedOut => outTime != null && outTime != '00:00:00' && outTime!.isNotEmpty;
  bool get isCheckedIn => inTime.isNotEmpty;
}
