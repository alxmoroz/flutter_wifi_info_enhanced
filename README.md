# WiFi Info Enhanced

Flutter plugin for getting WiFi information with improved iOS and Android support.

## Features

- Get current WiFi SSID (network name)
- Get WiFi BSSID (MAC address)
- Get device IP address in WiFi network
- Automatic permission handling on both iOS and Android
- No external dependencies

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

// Get WiFi SSID
String? ssid = await WifiInfoEnhanced.getWifiName();

// Get WiFi BSSID
String? bssid = await WifiInfoEnhanced.getWifiBSSID();

// Get device IP address
String? ipAddress = await WifiInfoEnhanced.getWifiIPAddress();
```

All methods automatically request necessary permissions when called. If the user denies permission, the methods return `null`.

## Limitations

- **iOS 13+**: Location permissions are required
- **Android 10+**: Location permissions and enabled location services are required
- User can deny permissions, making WiFi info unavailable
- Some information may be restricted on newer OS versions
- IP address retrieval does not require location permission on either platform
