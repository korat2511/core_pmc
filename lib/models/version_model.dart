class VersionModel {
  final String latestVersion;
  final String androidUpdateUrl;
  final String iosUpdateUrl;
  final String? androidPlayStoreUrl;
  final String? androidGoogleDriveUrl;
  final String? iosAppStoreUrl;
  final String? iosTestFlightUrl;
  final bool forceUpdate;

  VersionModel({
    required this.latestVersion,
    required this.androidUpdateUrl,
    required this.iosUpdateUrl,
    this.androidPlayStoreUrl,
    this.androidGoogleDriveUrl,
    this.iosAppStoreUrl,
    this.iosTestFlightUrl,
    this.forceUpdate = false,
  });

  factory VersionModel.fromJson(Map<String, dynamic> json) {
    return VersionModel(
      latestVersion: json['latest_version'] ?? '',
      androidUpdateUrl: json['android_update_url'] ?? '',
      iosUpdateUrl: json['ios_update_url'] ?? '',
      androidPlayStoreUrl: json['android_play_store_url'],
      androidGoogleDriveUrl: json['android_google_drive_url'],
      iosAppStoreUrl: json['ios_app_store_url'],
      iosTestFlightUrl: json['ios_testflight_url'],
      forceUpdate: json['force_update'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latest_version': latestVersion,
      'android_update_url': androidUpdateUrl,
      'ios_update_url': iosUpdateUrl,
      'android_play_store_url': androidPlayStoreUrl,
      'android_google_drive_url': androidGoogleDriveUrl,
      'ios_app_store_url': iosAppStoreUrl,
      'ios_testflight_url': iosTestFlightUrl,
      'force_update': forceUpdate,
    };
  }
}
