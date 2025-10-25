# WiFi Info Enhanced

Flutter plugin for getting WiFi information with improved iOS and Android support.

## Features

- Get comprehensive WiFi connection information
- Type-safe status checking with detailed availability reasons
- Automatic permission handling on both iOS and Android
- No external dependencies
- Enhanced error reporting

## Platform Requirements

### iOS

Starting from iOS 13, Apple requires location permissions to access WiFi information. The plugin automatically handles permission requests.

Add this permission to your `Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to get WiFi information</string>
```

### Android

Starting from Android 10 (API level 29), location permissions are required to access WiFi information. The plugin automatically handles permission requests.

The following permissions are already included in the plugin's `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

Make sure location services are enabled on the device for Android 10+.

## Usage

```dart
import 'package:wifi_info_enhanced/wifi_info_enhanced.dart';

// Get comprehensive WiFi information
WifiInfo wifiInfo = await WifiInfoEnhanced.getWifiInfo();

// Check if WiFi information is available
if (wifiInfo.isAvailable) {
  print('SSID: ${wifiInfo.ssid}');
  print('BSSID: ${wifiInfo.bssid}');
} else {
  // Handle different availability states
  switch (wifiInfo.availability) {
    case WifiAvailability.notConnected:
      print('WiFi is not connected');
      break;
    case WifiAvailability.permissionDenied:
      print('Location permission denied');
      break;
    case WifiAvailability.locationDisabled:
      print('Location services disabled');
      break;
    case WifiAvailability.restrictedByOs:
      print('WiFi connected but SSID restricted by OS');
      break;
    case WifiAvailability.unknown:
      print('Unknown error occurred');
      break;
  }
}

// IP address is usually available regardless of SSID availability
print('IP Address: ${wifiInfo.ipAddress}');
```

## API Reference

### WifiAvailability Enum

- `available` - WiFi connected and information is available
- `restrictedByOs` - WiFi connected, but SSID is hidden due to OS restrictions (Android 10+/iOS 13+)
- `locationDisabled` - Location services disabled (required for WiFi access on Android 10+/iOS 13+)
- `permissionDenied` - No permission to access location
- `notConnected` - WiFi not connected
- `unknown` - Unknown state or error

### WifiInfo Class

- `availability` - Current WiFi availability status
- `ssid` - WiFi network name (only if availability == available)
- `bssid` - WiFi BSSID/MAC address (only if availability == available)
- `ipAddress` - Device IP address (may be available even if SSID is not)
- `isAvailable` - Boolean indicating if WiFi info is fully available
- `isConnected` - Boolean indicating if WiFi is connected (regardless of SSID availability)

## Migration from v1.x

If you're upgrading from v1.x, you'll need to update your code:

```dart
// OLD API (v1.x)
final ssid = await WifiInfoEnhanced.getWifiName();
final bssid = await WifiInfoEnhanced.getWifiBSSID();
final ip = await WifiInfoEnhanced.getWifiIPAddress();

// NEW API (v2.0+)
final wifiInfo = await WifiInfoEnhanced.getWifiInfo();
if (wifiInfo.isAvailable) {
  final ssid = wifiInfo.ssid;
  final bssid = wifiInfo.bssid;
}
final ip = wifiInfo.ipAddress;
```

## Limitations

- **iOS 13+**: Location permissions are required
- **Android 10+**: Location permissions and enabled location services are required
- User can deny permissions, making WiFi info unavailable
- Some information may be restricted on newer OS versions
- IP address retrieval does not require location permission on either platform