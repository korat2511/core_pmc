class StoneModel {
  final int id;
  final String name;
  final String? deletedAt;
  final String createdAt;
  final String updatedAt;

  StoneModel({
    required this.id,
    required this.name,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StoneModel.fromJson(Map<String, dynamic> json) {
    return StoneModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      deletedAt: json['deleted_at'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'deleted_at': deletedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class LocationModel {
  final int id;
  final int siteId;
  final String name;
  final String? deletedAt;
  final String createdAt;
  final String updatedAt;

  LocationModel({
    required this.id,
    required this.siteId,
    required this.name,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] ?? 0,
      siteId: json['site_id'] ?? 0,
      name: json['name'] ?? '',
      deletedAt: json['deleted_at'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_id': siteId,
      'name': name,
      'deleted_at': deletedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class StoneQuantityModel {
  final int id;
  final int siteId;
  final int siteElementId;
  final int siteLocationId;
  final int stoneId;
  final String? code;
  final double floorArea;
  final String skirtingLength;
  final String skirtingHeight;
  final String skirtingSubtractLength;
  final double skirtingArea;
  final double counterTopAdditional;
  final double wallArea;
  final double totalCounterSkirtingWall;
  final double total;
  final String? deletedAt;
  final String createdAt;
  final String updatedAt;
  final StoneModel stone;
  final LocationModel location;

  StoneQuantityModel({
    required this.id,
    required this.siteId,
    required this.siteElementId,
    required this.siteLocationId,
    required this.stoneId,
    this.code,
    required this.floorArea,
    required this.skirtingLength,
    required this.skirtingHeight,
    required this.skirtingSubtractLength,
    required this.skirtingArea,
    required this.counterTopAdditional,
    required this.wallArea,
    required this.totalCounterSkirtingWall,
    required this.total,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.stone,
    required this.location,
  });

  factory StoneQuantityModel.fromJson(Map<String, dynamic> json) {
    return StoneQuantityModel(
      id: json['id'] ?? 0,
      siteId: json['site_id'] ?? 0,
      siteElementId: json['site_element_id'] ?? 0,
      siteLocationId: json['site_location_id'] ?? 0,
      stoneId: json['stone_id'] ?? 0,
      code: json['code'],
      floorArea: (json['floor_area'] as num?)?.toDouble() ?? 0.0,
      skirtingLength: json['skirting_length'] ?? '0\'-0"',
      skirtingHeight: json['skirting_height'] ?? '0\'-0"',
      skirtingSubtractLength: json['skirting_subtract_length'] ?? '0\'-0"',
      skirtingArea: (json['skirting_area'] as num?)?.toDouble() ?? 0.0,
      counterTopAdditional: (json['counter_top_additional'] as num?)?.toDouble() ?? 0.0,
      wallArea: (json['wall_area'] as num?)?.toDouble() ?? 0.0,
      totalCounterSkirtingWall: (json['total_counter_skirting_wall'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      deletedAt: json['deleted_at'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      stone: StoneModel.fromJson(json['stone'] ?? {}),
      location: LocationModel.fromJson(json['location'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_id': siteId,
      'site_element_id': siteElementId,
      'site_location_id': siteLocationId,
      'stone_id': stoneId,
      'code': code,
      'floor_area': floorArea,
      'skirting_length': skirtingLength,
      'skirting_height': skirtingHeight,
      'skirting_subtract_length': skirtingSubtractLength,
      'skirting_area': skirtingArea,
      'counter_top_additional': counterTopAdditional,
      'wall_area': wallArea,
      'total_counter_skirting_wall': totalCounterSkirtingWall,
      'total': total,
      'deleted_at': deletedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'stone': stone.toJson(),
      'location': location.toJson(),
    };
  }
}
