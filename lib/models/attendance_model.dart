import 'user_model.dart';

class AttendanceModel {
  final int id;
  final String date;
  final int userId;
  final String inTime;
  final String? remark;
  final String? latitudeIn;
  final String? latitudeOut;
  final String? longitudeIn;
  final String? longitudeOut;
  final String outTime;
  final String? addressIn;
  final String? addressOut;
  final String? imageIn;
  final String? imageOut;
  final String? imageInUrl;
  final String? imageOutUrl;
  final String createdAt;
  final int? siteId;
  final String updatedAt;
  final String? deletedAt;
  final UserModel? user;

  AttendanceModel({
    required this.id,
    required this.date,
    required this.userId,
    required this.inTime,
    this.remark,
    this.latitudeIn,
    this.latitudeOut,
    this.longitudeIn,
    this.longitudeOut,
    required this.outTime,
    this.addressIn,
    this.addressOut,
    this.imageIn,
    this.imageOut,
    this.imageInUrl,
    this.imageOutUrl,
    required this.createdAt,
    this.siteId,
    required this.updatedAt,
    this.deletedAt,
    this.user,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] ?? 0,
      date: json['date']?.toString() ?? '',
      userId: json['user_id'] ?? 0,
      inTime: json['in_time']?.toString() ?? '',
      remark: json['remark']?.toString(),
      latitudeIn: json['latitude_in']?.toString(),
      latitudeOut: json['latitude_out']?.toString(),
      longitudeIn: json['longitude_in']?.toString(),
      longitudeOut: json['longitude_out']?.toString(),
      outTime: json['out_time']?.toString() ?? '',
      addressIn: json['address_in']?.toString(),
      addressOut: json['address_out']?.toString(),
      imageIn: json['image_in']?.toString(),
      imageOut: json['image_out']?.toString(),
      imageInUrl: json['image_in_url']?.toString(),
      imageOutUrl: json['image_out_url']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      siteId: json['site_id'],
      updatedAt: json['updated_at']?.toString() ?? '',
      deletedAt: json['deleted_at']?.toString(),
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
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
      'image_in': imageIn,
      'image_out': imageOut,
      'image_in_url': imageInUrl,
      'image_out_url': imageOutUrl,
      'created_at': createdAt,
      'site_id': siteId,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'user': user?.toJson(),
    };
  }

  // Helper getters
  DateTime get dateTime {
    try {
      return DateTime.parse(date);
    } catch (e) {
      return DateTime.now();
    }
  }
  
  bool get isPresent => inTime.isNotEmpty && inTime != '00:00:00';
  bool get isAbsent => inTime.isEmpty || inTime == '00:00:00';
  bool get hasCheckedOut => outTime.isNotEmpty && outTime != '00:00:00';
  bool get isAutoCheckout => outTime.isNotEmpty && outTime == '00:00:00';
  
  // Get check-in time
  String get checkInTime => inTime.isNotEmpty ? inTime : '';
  
  // Get check-out time
  String get checkOutTime => outTime.isNotEmpty ? outTime : '';
  
  // Get checkout status text
  String get checkoutStatusText {
    if (outTime.isEmpty) return 'Not checked out';
    if (isAutoCheckout) return 'Auto checkout at midnight';
    return checkOutTime;
  }

  // Get user name from user object
  String get userName {
    return user?.displayName ?? '';
  }
}
