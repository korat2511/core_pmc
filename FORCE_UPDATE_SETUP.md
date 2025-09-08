# Force Update Feature Setup Guide

## Overview
This implementation provides a comprehensive force update feature for both Android and iOS platforms with multiple download options.

## Features
- ✅ Automatic version checking on app startup
- ✅ Force update and optional update modes
- ✅ Platform-specific download options
- ✅ Multiple download sources (Play Store, App Store, TestFlight, Google Drive, Direct Download)
- ✅ Manual update check option
- ✅ Beautiful UI with version comparison

## Setup Instructions

### 1. Update Your GitHub Repository
Create a `version.json` file in your GitHub repository with the following structure:

```json
{
  "latest_version": "3.0.1",
  "force_update": false,
  "android_update_url": "https://pmcprojects.in",
  "ios_update_url": "https://pmcprojects.in",
  "android_play_store_url": "https://play.google.com/store/apps/details?id=com.pmcprojects.app",
  "android_google_drive_url": "https://drive.google.com/file/d/your-file-id/view",
  "ios_app_store_url": "https://apps.apple.com/app/your-app-id",
  "ios_testflight_url": "https://testflight.apple.com/join/your-testflight-code"
}
```

### 2. Update Version Check Service
Edit `lib/services/version_check_service.dart` and update the GitHub URL:

```dart
static const String _versionJsonUrl = 'https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/version.json';
```

### 3. Configure Your URLs

#### Android URLs:
- `android_play_store_url`: Your app's Play Store URL
- `android_google_drive_url`: Direct download link from Google Drive
- `android_update_url`: Fallback URL for direct download

#### iOS URLs:
- `ios_app_store_url`: Your app's App Store URL
- `ios_testflight_url`: TestFlight beta testing URL
- `ios_update_url`: Fallback URL for direct download

### 4. Version Control
- Update `latest_version` in your JSON file when releasing new versions
- Set `force_update: true` to make updates mandatory
- Set `force_update: false` to make updates optional

## How It Works

### Automatic Check
- App checks for updates on startup
- Compares current app version with latest version from JSON
- Shows update dialog if newer version is available

### Update Dialog Features
- Shows current vs latest version
- Multiple download options based on platform
- Force update prevents app usage until updated
- Optional update allows "Later" option

### Platform-Specific Options

#### Android:
1. Google Play Store (if URL provided)
2. Google Drive (if URL provided)
3. Direct Download (fallback)

#### iOS:
1. App Store (if URL provided)
2. TestFlight (if URL provided)
3. Direct Download (fallback)

## Manual Update Check
Add the `UpdateCheckButton` widget to your settings screen:

```dart
import '../widgets/update_check_button.dart';

// In your settings screen
UpdateCheckButton()
```

## Testing

### Test Force Update:
1. Set `force_update: true` in version.json
2. Set `latest_version` higher than current app version
3. Launch app - should show force update dialog

### Test Optional Update:
1. Set `force_update: false` in version.json
2. Set `latest_version` higher than current app version
3. Launch app - should show optional update dialog with "Later" button

## File Structure
```
lib/
├── models/
│   └── version_model.dart
├── services/
│   ├── version_check_service.dart
│   └── force_update_manager.dart
├── widgets/
│   ├── force_update_dialog.dart
│   └── update_check_button.dart
└── main.dart (updated with ForceUpdateWrapper)
```

## Dependencies Required
The following dependencies are already included in your pubspec.yaml:
- `package_info_plus: ^8.3.0` - Get current app version
- `url_launcher: ^6.3.2` - Open download URLs
- `http: ^1.4.0` - Fetch version JSON

## Customization

### Styling
Edit `lib/widgets/force_update_dialog.dart` to customize:
- Colors and themes
- Dialog layout
- Button styles
- Icons and images

### Behavior
Edit `lib/services/force_update_manager.dart` to customize:
- When to check for updates
- How often to check
- Dialog display logic

## Security Notes
- Always use HTTPS URLs for downloads
- Validate JSON structure before parsing
- Consider adding signature verification for direct downloads
- Use official app stores when possible for security

## Troubleshooting

### Update Dialog Not Showing
- Check internet connection
- Verify GitHub URL is accessible
- Check JSON format is valid
- Ensure version comparison logic is working

### URLs Not Opening
- Verify URL format is correct
- Check if URL schemes are supported on device
- Test URLs in browser first

### Version Comparison Issues
- Ensure version format is consistent (e.g., "1.0.0")
- Check version parsing logic in `_compareVersions` method
