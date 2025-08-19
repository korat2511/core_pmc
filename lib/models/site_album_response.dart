import 'site_album_model.dart';

class SiteAlbumResponse {
  final int status;
  final String message;
  final List<SiteAlbumModel> siteAlbum;

  SiteAlbumResponse({
    required this.status,
    required this.message,
    required this.siteAlbum,
  });

  factory SiteAlbumResponse.fromJson(Map<String, dynamic> json) {
    return SiteAlbumResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      siteAlbum: (json['siteAlbum'] as List<dynamic>?)
              ?.map((album) => SiteAlbumModel.fromJson(album))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'siteAlbum': siteAlbum.map((album) => album.toJson()).toList(),
    };
  }
}
