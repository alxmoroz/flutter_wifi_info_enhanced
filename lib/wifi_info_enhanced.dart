// Copyright (c) 2025. Alexandr Moroz

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// WiFi availability status
enum WifiAvailability {
  /// WiFi connected and information is available
  available,

  /// WiFi connected, but SSID is hidden due to OS restrictions (Android 10+/iOS 13+)
  restrictedByOs,

  /// Location services disabled (required for WiFi access on Android 10+/iOS 13+)
  locationDisabled,

  /// No permission to access location
  permissionDenied,

  /// WiFi not connected
  notConnected,

  /// Unknown state or error
  unknown,
}

/// Detailed WiFi connection information
class WifiInfo {
  final WifiAvailability availability;
  final String? ssid;        // only if availability == available
  final String? bssid;       // only if availability == available
  final String? ipAddress;   // may be available even if SSID is not

  const WifiInfo({
    required this.availability,
    this.ssid,
    this.bssid,
    this.ipAddress,
  });

  /// WiFi connected and information is available
  bool get isAvailable => availability == WifiAvailability.available;

  /// WiFi connected (regardless of SSID availability)
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