class ManpowerEntryModel {
  final int categoryId;
  final String? categoryName;
  final int shift;
  final int skilledWorker;
  final int unskilledWorker;

  ManpowerEntryModel({
    required this.categoryId,
    this.categoryName,
    required this.shift,
    required this.skilledWorker,
    required this.unskilledWorker,
  });

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'shift': shift,
      'skilled_worker': skilledWorker,
      'unskilled_worker': unskilledWorker,
    };
  }

  factory ManpowerEntryModel.fromJson(Map<String, dynamic> json) {
    return ManpowerEntryModel(
      categoryId: json['category_id'] is int ? json['category_id'] : int.tryParse(json['category_id'].toString()) ?? 0,
      categoryName: json['category_name']?.toString(),
      shift: json['shift'] is int ? json['shift'] : int.tryParse(json['shift'].toString()) ?? 1,
      skilledWorker: json['skilled_worker'] is int ? json['skilled_worker'] : int.tryParse(json['skilled_worker'].toString()) ?? 0,
      unskilledWorker: json['unskilled_worker'] is int ? json['unskilled_worker'] : int.tryParse(json['unskilled_worker'].toString()) ?? 0,
    );
  }

  ManpowerEntryModel copyWith({
    int? categoryId,
    String? categoryName,
    int? shift,
    int? skilledWorker,
    int? unskilledWorker,
  }) {
    return ManpowerEntryModel(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      shift: shift ?? this.shift,
      skilledWorker: skilledWorker ?? this.skilledWorker,
      unskilledWorker: unskilledWorker ?? this.unskilledWorker,
    );
  }

  String get shiftText {
    switch (shift) {
      case 1:
        return 'Day';
      case 2:
        return 'Night';
      case 3:
        return 'Day Night';
      default:
        return 'Day';
    }
  }
}
