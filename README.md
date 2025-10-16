# WiFi Info Plus

Flutter plugin for getting WiFi information with improved iOS support.

## Features

- Get current WiFi SSID (network name)
- Get WiFi BSSID (MAC address)
- Get device IP address in WiFi network
- Improved iOS 13+ support with location permissions

## iOS Requirements

Starting from iOS 13, Apple requires location permissions to access WiFi information. The plugin automatically handles permission requests.

Add this permission to your `Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Для определения подключения к Wi-Fi события</string>
```

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

## Limitations

- On iOS 13+, location permissions are required
- User can deny location permissions, making WiFi info unavailable
- Some information may be restricted on newer iOS versions
