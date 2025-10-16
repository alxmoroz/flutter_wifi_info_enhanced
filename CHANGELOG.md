# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-10-16

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
