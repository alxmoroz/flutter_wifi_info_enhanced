# WiFi Info Enhanced - Enhancement Instructions

## Overview

This document provides detailed instructions for enhancing the `wifi_info_enhanced` Flutter plugin to provide better WiFi status information and eliminate the need for magic strings in client code.

## Current Problem

The current API returns `null` for WiFi SSID in various scenarios, but clients cannot distinguish between:
- WiFi not connected
- WiFi connected but SSID hidden due to OS restrictions (Android 10+/iOS 13+)
- Location services disabled (required for WiFi access on Android 10+/iOS 13+)
- Permission denied

This forces clients to use magic strings like `'CONNECTED_BUT_HIDDEN'` and `'LOCATION_DISABLED'`, which is error-prone and can conflict with actual SSID names.

## Solution

Replace the current three separate methods with a single comprehensive API that provides structured WiFi information.

## Changes Required

### 1. Update `lib/wifi_info_enhanced.dart`

**BREAKING CHANGES:** Replace existing methods with new API.

```dart
// Copyright (c) 2025. Alexandr Moroz

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Статус доступности WiFi информации
enum WifiAvailability {
  /// WiFi подключен и информация доступна
  available,
  
  /// WiFi подключен, но SSID скрыт из-за ограничений ОС (Android 10+/iOS 13+)
  restrictedByOs,
  
  /// Геолокация выключена (требуется для доступа к WiFi на Android 10+/iOS 13+)
  locationDisabled,
  
  /// Нет разрешения на доступ к геолокации
  permissionDenied,
  
  /// WiFi не подключен
  notConnected,
  
  /// Неизвестное состояние или ошибка
  unknown,
}

/// Детальная информация о WiFi подключении
class WifiInfo {
  final WifiAvailability availability;
  final String? ssid;        // только если availability == available
  final String? bssid;       // только если availability == available
  final String? ipAddress;   // может быть доступен даже если SSID недоступен
  
  const WifiInfo({
    required this.availability,
    this.ssid,
    this.bssid,
    this.ipAddress,
  });
  
  /// WiFi подключен и информация доступна
  bool get isAvailable => availability == WifiAvailability.available;
  
  /// WiFi подключен (независимо от доступности SSID)
  bool get isConnected => availability != WifiAvailability.notConnected && 
                          availability != WifiAvailability.unknown;
}

/// A Flutter plugin for getting WiFi information with improved iOS and Android support.
///
/// Note: On iOS 13+ and Android 10+, location permissions are required to access WiFi information.
/// Permissions are requested automatically by the native code when needed.
class WifiInfoEnhanced {
  static const MethodChannel _channel = MethodChannel('wifi_info_enhanced');

  /// Get detailed WiFi connection information.
  ///
  /// Returns [WifiInfo] with complete information about WiFi state,
  /// including the reason why SSID might be unavailable.
  ///
  /// Platform support: iOS and Android.
  /// Note: On iOS 13+ and Android 10+, location permission is required.
  /// Permission will be requested automatically if not granted.
  static Future<WifiInfo> getWifiInfo() async {
    try {
      if (Platform.isIOS || Platform.isAndroid) {
        final Map<dynamic, dynamic> result = await _channel.invokeMethod('getWifiInfo');
        
        return WifiInfo(
          availability: _parseAvailability(result['availability']),
          ssid: result['ssid'],
          bssid: result['bssid'],
          ipAddress: result['ipAddress'],
        );
      }
      return const WifiInfo(availability: WifiAvailability.unknown);
    } on PlatformException catch (e) {
      if (kDebugMode) print('Error getting WiFi info: ${e.message}');
      return const WifiInfo(availability: WifiAvailability.unknown);
    }
  }
  
  static WifiAvailability _parseAvailability(String? availability) {
    switch (availability) {
      case 'available':
        return WifiAvailability.available;
      case 'restrictedByOs':
        return WifiAvailability.restrictedByOs;
      case 'locationDisabled':
        return WifiAvailability.locationDisabled;
      case 'permissionDenied':
        return WifiAvailability.permissionDenied;
      case 'notConnected':
        return WifiAvailability.notConnected;
      default:
        return WifiAvailability.unknown;
    }
  }
}
```

### 2. Update Android Implementation (`android/src/main/kotlin/team/moroz/wifi_info_enhanced/WifiInfoEnhancedPlugin.kt`)

**BREAKING CHANGES:** Replace existing methods with new `getWifiInfo` method.

```kotlin
package team.moroz.wifi_info_enhanced

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.location.LocationManager
import android.net.wifi.WifiManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.net.InetAddress
import java.net.NetworkInterface

class WifiInfoEnhancedPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
    private lateinit var channel : MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private var pendingResult: Result? = null
    private var pendingMethodCall: MethodCall? = null
    
    companion object {
        private const val PERMISSION_REQUEST_CODE = 8472
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "wifi_info_enhanced")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getWifiInfo" -> {
                getWifiInfo(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun getWifiInfo(result: Result) {
        try {
            val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val network = connectivityManager.activeNetwork
            val capabilities = connectivityManager.getNetworkCapabilities(network)
            
            val isWifiConnected = capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true
            
            // Check location permission for Android 10+
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                if (!hasLocationPermission()) {
                    // Request permission if Activity is available
                    if (activity != null) {
                        requestLocationPermission(result, "getWifiInfo")
                        return
                    } else {
                        result.success(mapOf(
                            "availability" to "permissionDenied",
                            "ssid" to null,
                            "bssid" to null,
                            "ipAddress" to getWifiIPAddress()
                        ))
                        return
                    }
                }
                
                if (!isLocationServiceEnabled()) {
                    result.success(mapOf(
                        "availability" to "locationDisabled",
                        "ssid" to null,
                        "bssid" to null,
                        "ipAddress" to getWifiIPAddress()
                    ))
                    return
                }
            }
            
            if (!isWifiConnected) {
                result.success(mapOf(
                    "availability" to "notConnected",
                    "ssid" to null,
                    "bssid" to null,
                    "ipAddress" to getWifiIPAddress()
                ))
                return
            }
            
            val wifiInfo = wifiManager.connectionInfo
            val ssid = wifiInfo.ssid
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // On Android 10+ special permission is required
                if (ssid == "<unknown ssid>" || ssid == null || ssid.isEmpty()) {
                    result.success(mapOf(
                        "availability" to "restrictedByOs",
                        "ssid" to null,
                        "bssid" to null,
                        "ipAddress" to getWifiIPAddress()
                    ))
                } else {
                    result.success(mapOf(
                        "availability" to "available",
                        "ssid" to ssid.replace("\"", ""),
                        "bssid" to wifiInfo.bssid,
                        "ipAddress" to getWifiIPAddress()
                    ))
                }
            } else {
                // On older Android versions
                if (ssid == "<unknown ssid>") {
                    result.success(mapOf(
                        "availability" to "notConnected",
                        "ssid" to null,
                        "bssid" to null,
                        "ipAddress" to getWifiIPAddress()
                    ))
                } else {
                    result.success(mapOf(
                        "availability" to "available",
                        "ssid" to ssid?.replace("\"", ""),
                        "bssid" to wifiInfo.bssid,
                        "ipAddress" to getWifiIPAddress()
                    ))
                }
            }
        } catch (e: Exception) {
            result.success(mapOf(
                "availability" to "unknown",
                "ssid" to null,
                "bssid" to null,
                "ipAddress" to null
            ))
        }
    }

    private fun getWifiIPAddress(): String? {
        return try {
            val interfaces = NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val networkInterface = interfaces.nextElement()
                val addresses = networkInterface.inetAddresses
                while (addresses.hasMoreElements()) {
                    val address = addresses.nextElement()
                    if (!address.isLoopbackAddress && address is InetAddress && address.hostAddress?.indexOf(':') == -1) {
                        return address.hostAddress
                    }
                }
            }
            null
        } catch (e: Exception) {
            null
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
    
    // ActivityAware implementation
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
    
    // Permission request handling
    private fun requestLocationPermission(result: Result, methodName: String) {
        pendingResult = result
        pendingMethodCall = MethodCall(methodName, null)
        
        activity?.let {
            ActivityCompat.requestPermissions(
                it,
                arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
                PERMISSION_REQUEST_CODE
            )
        } ?: result.success(mapOf(
            "availability" to "permissionDenied",
            "ssid" to null,
            "bssid" to null,
            "ipAddress" to null
        ))
    }
    
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && 
                         grantResults[0] == PackageManager.PERMISSION_GRANTED
            
            if (granted) {
                // Permission granted, retry the original method call
                pendingMethodCall?.let { call ->
                    pendingResult?.let { result ->
                        when (call.method) {
                            "getWifiInfo" -> getWifiInfo(result)
                        }
                    }
                }
            } else {
                // Permission denied
                pendingResult?.success(mapOf(
                    "availability" to "permissionDenied",
                    "ssid" to null,
                    "bssid" to null,
                    "ipAddress" to null
                ))
            }
            
            pendingResult = null
            pendingMethodCall = null
            return true
        }
        return false
    }
    
    private fun hasLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }
    
    private fun isLocationServiceEnabled(): Boolean {
        val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        return locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
               locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
    }
}
```

### 3. Update iOS Implementation (`ios/Classes/WifiInfoEnhancedPlugin.swift`)

**BREAKING CHANGES:** Replace existing methods with new `getWifiInfo` method.

```swift
import Flutter
import UIKit
import SystemConfiguration.CaptiveNetwork
import CoreLocation

public class WifiInfoEnhancedPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager?
    private var result: FlutterResult?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "wifi_info_enhanced", binaryMessenger: registrar.messenger())
        let instance = WifiInfoEnhancedPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getWifiInfo":
            getWifiInfo(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func getWifiInfo(result: @escaping FlutterResult) {
        self.result = result
        
        // Check location permissions
        if CLLocationManager.locationServicesEnabled() {
            let status = CLLocationManager.authorizationStatus()
            switch status {
            case .authorizedWhenInUse:
                // Permissions granted, getting WiFi info
                getCurrentWifiInfo()
            case .authorizedAlways:
                // Permissions granted, getting WiFi info
                getCurrentWifiInfo()
            case .denied, .restricted:
                // Permissions denied
                result([
                    "availability": "permissionDenied",
                    "ssid": NSNull(),
                    "bssid": NSNull(),
                    "ipAddress": getWifiIPAddress() ?? NSNull()
                ])
            case .notDetermined:
                // Request permissions for app usage only
                requestLocationPermission()
            @unknown default:
                result([
                    "availability": "unknown",
                    "ssid": NSNull(),
                    "bssid": NSNull(),
                    "ipAddress": NSNull()
                ])
            }
        } else {
            result([
                "availability": "locationDisabled",
                "ssid": NSNull(),
                "bssid": NSNull(),
                "ipAddress": getWifiIPAddress() ?? NSNull()
            ])
        }
    }
    
    private func getWifiIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            
            // Check IPv4 interface
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" { // Wi-Fi interface
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                              &hostname, socklen_t(hostname.count),
                              nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        
        freeifaddrs(ifaddr)
        return address
    }
    
    private func requestLocationPermission() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        // Request permission for app usage only
        locationManager?.requestWhenInUseAuthorization()
    }
    
    private func getCurrentWifiInfo() {
        guard let interfaces = CNCopySupportedInterfaces() as? [String] else {
            result?([
                "availability": "notConnected",
                "ssid": NSNull(),
                "bssid": NSNull(),
                "ipAddress": getWifiIPAddress() ?? NSNull()
            ])
            return
        }
        
        for interface in interfaces {
            if let info = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any] {
                let ssid = info["SSID"] as? String
                let bssid = info["BSSID"] as? String
                
                if ssid != nil {
                    result?([
                        "availability": "available",
                        "ssid": ssid!,
                        "bssid": bssid ?? NSNull(),
                        "ipAddress": getWifiIPAddress() ?? NSNull()
                    ])
                } else {
                    result?([
                        "availability": "restrictedByOs",
                        "ssid": NSNull(),
                        "bssid": NSNull(),
                        "ipAddress": getWifiIPAddress() ?? NSNull()
                    ])
                }
                return
            }
        }
        
        result?([
            "availability": "notConnected",
            "ssid": NSNull(),
            "bssid": NSNull(),
            "ipAddress": getWifiIPAddress() ?? NSNull()
        ])
    }
    
    // MARK: - CLLocationManagerDelegate
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse:
            // Permissions granted, getting WiFi information
            getCurrentWifiInfo()
        case .authorizedAlways:
            // Permissions granted, getting WiFi information
            getCurrentWifiInfo()
        case .denied, .restricted:
            result?([
                "availability": "permissionDenied",
                "ssid": NSNull(),
                "bssid": NSNull(),
                "ipAddress": getWifiIPAddress() ?? NSNull()
            ])
        case .notDetermined:
            break
        @unknown default:
            result?([
                "availability": "unknown",
                "ssid": NSNull(),
                "bssid": NSNull(),
                "ipAddress": NSNull()
            ])
        }
    }
}
```

### 4. Update Version and Documentation

**Update `pubspec.yaml`:**
```yaml
name: wifi_info_enhanced
description: Flutter plugin for getting WiFi information with improved iOS and Android support
version: 2.0.0  # BREAKING CHANGES
homepage: https://github.com/alxmoroz/flutter_wifi_info_enhanced
```

**Update `CHANGELOG.md`:**
```markdown
## [2.0.0] - 2025-01-XX

### BREAKING CHANGES
- Removed `getWifiName()`, `getWifiBSSID()`, and `getWifiIPAddress()` methods
- Added new `getWifiInfo()` method that returns structured `WifiInfo` object
- Added `WifiAvailability` enum for type-safe status checking
- Added `WifiInfo` class with `availability`, `ssid`, `bssid`, `ipAddress` fields

### Added
- `WifiAvailability` enum with states: `available`, `restrictedByOs`, `locationDisabled`, `permissionDenied`, `notConnected`, `unknown`
- `WifiInfo` class with convenience getters `isAvailable` and `isConnected`
- Comprehensive WiFi status detection for both Android and iOS
- Better error handling and status reporting

### Migration Guide
Replace:
```dart
String? ssid = await WifiInfoEnhanced.getWifiName();
String? bssid = await WifiInfoEnhanced.getWifiBSSID();
String? ip = await WifiInfoEnhanced.getWifiIPAddress();
```

With:
```dart
WifiInfo info = await WifiInfoEnhanced.getWifiInfo();
String? ssid = info.ssid;
String? bssid = info.bssid;
String? ip = info.ipAddress;
WifiAvailability status = info.availability;
```
```

**Update `README.md`:**
```markdown
# wifi_info_enhanced

A Flutter plugin for getting WiFi information with improved iOS and Android support.

## Features

- Get detailed WiFi connection information
- Type-safe status checking with `WifiAvailability` enum
- Automatic permission handling for location services
- Support for Android 10+ privacy restrictions
- Support for iOS 13+ location requirements

## Usage

```dart
import 'package:wifi_info_enhanced/wifi_info_enhanced.dart';

// Get comprehensive WiFi information
WifiInfo info = await WifiInfoEnhanced.getWifiInfo();

// Check availability
if (info.isAvailable) {
  print('Connected to: ${info.ssid}');
  print('BSSID: ${info.bssid}');
  print('IP: ${info.ipAddress}');
} else {
  // Handle different unavailable states
  switch (info.availability) {
    case WifiAvailability.restrictedByOs:
      print('WiFi connected but SSID hidden by OS');
      break;
    case WifiAvailability.locationDisabled:
      print('Enable location services to see WiFi name');
      break;
    case WifiAvailability.permissionDenied:
      print('Location permission required');
      break;
    case WifiAvailability.notConnected:
      print('WiFi not connected');
      break;
    case WifiAvailability.unknown:
      print('Unknown WiFi state');
      break;
  }
}
```

## Permissions

### Android
- `ACCESS_FINE_LOCATION` - Required for Android 10+ to access WiFi information
- Automatically requested when needed

### iOS
- Location permission - Required for iOS 13+ to access WiFi information
- Automatically requested when needed

## Platform Support

- ✅ Android (API 21+)
- ✅ iOS (iOS 12+)

## Breaking Changes in v2.0.0

This version introduces breaking changes. See [CHANGELOG.md](CHANGELOG.md) for migration guide.
```

## Implementation Notes

1. **Single Method Approach**: Instead of three separate methods, we now have one comprehensive `getWifiInfo()` method that returns all information at once.

2. **Type Safety**: Using enum `WifiAvailability` instead of magic strings eliminates the possibility of conflicts with actual SSID names.

3. **Structured Data**: The `WifiInfo` class provides a clean, typed interface for accessing WiFi information.

4. **Better Error Handling**: Each platform now provides detailed status information about why WiFi data might be unavailable.

5. **Permission Handling**: The plugin automatically handles location permission requests on both platforms.

## Testing

After implementing these changes, test the following scenarios:

### Android
- [ ] WiFi connected with SSID available
- [ ] WiFi connected but SSID hidden (Android 10+)
- [ ] Location services disabled
- [ ] Location permission denied
- [ ] WiFi not connected
- [ ] No location permission granted

### iOS
- [ ] WiFi connected with SSID available
- [ ] WiFi connected but SSID hidden (iOS 13+)
- [ ] Location services disabled
- [ ] Location permission denied
- [ ] WiFi not connected
- [ ] No location permission granted

## Client Code Migration

Clients using the old API should migrate to the new API:

```dart
// Old way (v1.x)
String? ssid = await WifiInfoEnhanced.getWifiName();
if (ssid == 'CONNECTED_BUT_HIDDEN') {
  // Handle hidden SSID
} else if (ssid == 'LOCATION_DISABLED') {
  // Handle location disabled
}

// New way (v2.0+)
WifiInfo info = await WifiInfoEnhanced.getWifiInfo();
switch (info.availability) {
  case WifiAvailability.restrictedByOs:
    // Handle hidden SSID
    break;
  case WifiAvailability.locationDisabled:
    // Handle location disabled
    break;
  case WifiAvailability.available:
    print('Connected to: ${info.ssid}');
    break;
}
```
