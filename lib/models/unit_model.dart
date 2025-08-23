class UnitModel {
  final int id;
  final String name;
  final String symbol;

  UnitModel({
    required this.id,
    required this.name,
    required this.symbol,
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      symbol: json['symbol'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
    };
  }
}

class UnitResponse {
  final int status;
  final List<UnitModel> data;

  UnitResponse({
    required this.status,
    required this.data,
  });

  factory UnitResponse.fromJson(Map<String, dynamic> json) {
    return UnitResponse(
      status: json['status'] ?? 0,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => UnitModel.fromJson(item))
              .toList() ??
          [],
    );
  }
}
