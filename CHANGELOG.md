# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-10-25

### Changed
- **BREAKING**: Removed `permission_handler` dependency - permissions now handled natively
- **BREAKING**: Removed `requestPermission` parameter from `getWifiName()` and `getWifiBSSID()` methods
- **BREAKING**: Removed public methods `checkPermissionStatus()` and `requestPermissions()`
- Simplified API - all permission requests are now handled automatically by native code
- Improved Android support with native permission handling via ActivityAware interface
- Updated description to reflect Android support

### Added
- Full Android platform support with automatic permission handling
- Native permission request flow on Android (matching iOS behavior)
- Comprehensive README documentation for both iOS and Android platforms

### Fixed
- Removed debug print statements from iOS code
- Improved consistency between iOS and Android permission handling

### Technical Details
- Android: Implemented ActivityAware interface for runtime permission requests
- iOS: Maintained existing native permission handling via CLLocationManager
- Both platforms now follow the same permission flow pattern
- No external dependencies required

## [1.0.1] - 2025-10-18

### Fixed
- Resolved CocoaPods "No podspec found" error in iOS projects

## [1.0.0] - 2025-10-17

### Added
- Initial release of wifi_info_enhanced plugin
- Support for iOS platform only
- Get current WiFi network name (SSID)
- Get WiFi BSSID (MAC address)
- Get device IP address in WiFi network
- Improved iOS 13+ support with location permissions
- Comprehensive error handling with null safety
- Complete documentation and README

### Technical Details
- iOS: Uses native iOS APIs to access WiFi information
- iOS 13+ compatibility with automatic location permission handling
- Cross-platform API design (Android not implemented in this version)
- Proper error handling and exception management
- Null-safe return values for unavailable information

### Platform Support
- ✅ iOS: Full support with location permission handling
- ❌ Android: Not implemented (focus on iOS enhanced functionality)

### iOS Requirements
- iOS 13+ requires location permissions to access WiFi information
- Automatic permission request handling
- Graceful degradation when permissions are denied
