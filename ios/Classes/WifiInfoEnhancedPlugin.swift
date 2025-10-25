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
        
        // Check if WiFi is connected
        guard let interfaces = CNCopySupportedInterfaces() as? [String] else {
            let ipAddress = getWifiIPAddress()
            result([
                "availability": "notConnected",
                "ssid": nil,
                "bssid": nil,
                "ipAddress": ipAddress
            ])
            return
        }
        
        // Check location permissions
        if CLLocationManager.locationServicesEnabled() {
            let status = CLLocationManager.authorizationStatus()
            switch status {
            case .authorizedWhenInUse:
                // Permissions granted, getting WiFi information
                getCurrentWifiInfo()
            case .authorizedAlways:
                // Permissions granted, getting WiFi information
                getCurrentWifiInfo()
            case .denied, .restricted:
                // Permissions denied
                let ipAddress = getWifiIPAddress()
                result([
                    "availability": "permissionDenied",
                    "ssid": nil,
                    "bssid": nil,
                    "ipAddress": ipAddress
                ])
            case .notDetermined:
                // Request permissions for app usage only
                requestLocationPermission()
            @unknown default:
                let ipAddress = getWifiIPAddress()
                result([
                    "availability": "unknown",
                    "ssid": nil,
                    "bssid": nil,
                    "ipAddress": ipAddress
                ])
            }
        } else {
            let ipAddress = getWifiIPAddress()
            result([
                "availability": "locationDisabled",
                "ssid": nil,
                "bssid": nil,
                "ipAddress": ipAddress
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
            let ipAddress = getWifiIPAddress()
            result?([
                "availability": "notConnected",
                "ssid": nil,
                "bssid": nil,
                "ipAddress": ipAddress
            ])
            return
        }
        
        for interface in interfaces {
            if let info = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any] {
                let ssid = info["SSID"] as? String
                let bssid = info["BSSID"] as? String
                let ipAddress = getWifiIPAddress()
                
                if let ssid = ssid, !ssid.isEmpty {
                    result?([
                        "availability": "available",
                        "ssid": ssid,
                        "bssid": bssid,
                        "ipAddress": ipAddress
                    ])
                } else {
                    result?([
                        "availability": "restrictedByOs",
                        "ssid": nil,
                        "bssid": bssid,
                        "ipAddress": ipAddress
                    ])
                }
                return
            }
        }
        
        // No WiFi interface found
        let ipAddress = getWifiIPAddress()
        result?([
            "availability": "notConnected",
            "ssid": nil,
            "bssid": nil,
            "ipAddress": ipAddress
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
            let ipAddress = getWifiIPAddress()
            result?([
                "availability": "permissionDenied",
                "ssid": nil,
                "bssid": nil,
                "ipAddress": ipAddress
            ])
        case .notDetermined:
            break
        @unknown default:
            let ipAddress = getWifiIPAddress()
            result?([
                "availability": "unknown",
                "ssid": nil,
                "bssid": nil,
                "ipAddress": ipAddress
            ])
        }
    }
}