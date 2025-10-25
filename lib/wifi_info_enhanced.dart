// Copyright (c) 2025. Alexandr Moroz

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A Flutter plugin for getting WiFi information with improved iOS and Android support.
///
/// Note: On iOS 13+ and Android 10+, location permissions are required to access WiFi information.
/// Permissions are requested automatically by the native code when needed.
class WifiInfoEnhanced {
  static const MethodChannel _channel = MethodChannel('wifi_info_enhanced');

  /// Get the current WiFi network name (SSID).
  ///
  /// Returns the SSID of the connected WiFi network, or `null` if not available.
  ///
  /// Platform support: iOS and Android.
  /// Note: On iOS 13+ and Android 10+, location permission is required.
  /// Permission will be requested automatically if not granted.
  static Future<String?> getWifiName() async {
    try {
      if (Platform.isIOS || Platform.isAndroid) {
        final String? wifiName = await _channel.invokeMethod('getWifiName');
        return wifiName;
      }
      return null;
    } on PlatformException catch (e) {
      if (kDebugMode) print('Error getting WiFi name: ${e.message}');
      return null;
    }
  }

  /// Get the BSSID (MAC address) of the current WiFi network.
  ///
  /// Returns the BSSID of the connected WiFi network, or `null` if not available.
  ///
  /// Platform support: iOS and Android.
  /// Note: On iOS 13+ and Android 10+, location permission is required.
  /// Permission will be requested automatically if not granted.
  static Future<String?> getWifiBSSID() async {
    try {
      if (Platform.isIOS || Platform.isAndroid) {
        final String? bssid = await _channel.invokeMethod('getWifiBSSID');
        return bssid;
      }
      return null;
    } on PlatformException catch (e) {
      if (kDebugMode) print('Error getting WiFi BSSID: ${e.message}');
      return null;
    }
  }

  /// Get the IP address of the device in the WiFi network.
  ///
  /// Returns the local IP address, or `null` if not available.
  ///
  /// Platform support: iOS and Android.
  static Future<String?> getWifiIPAddress() async {
    try {
      if (Platform.isIOS || Platform.isAndroid) {
        final String? ipAddress = await _channel.invokeMethod('getWifiIPAddress');
        return ipAddress;
      }
      return null;
    } on PlatformException catch (e) {
      if (kDebugMode) print('Error getting WiFi IP address: ${e.message}');
      return null;
    }
  }
}
