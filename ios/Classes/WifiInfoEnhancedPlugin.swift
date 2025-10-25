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
        case "getWifiName":
            getWifiName(result: result)
        case "getWifiBSSID":
            getWifiBSSID(result: result)
        case "getWifiIPAddress":
            getWifiIPAddress(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func getWifiName(result: @escaping FlutterResult) {
        self.result = result
        
        // Check location permissions
        if CLLocationManager.locationServicesEnabled() {
            let status = CLLocationManager.authorizationStatus()
            switch status {
            case .authorizedWhenInUse:
                // Permissions granted, getting SSID
                getCurrentWifiSSID()
            case .authorizedAlways:
                // Permissions granted, getting SSID
                getCurrentWifiSSID()
            case .denied, .restricted:
                // Permissions denied
                result(nil)
            case .notDetermined:
                // Request permissions for app usage only
                requestLocationPermission()
            @unknown default:
                result(nil)
            }
        } else {
            result(nil)
        }
    }
    
    private func getWifiBSSID(result: @escaping FlutterResult) {
        self.result = result
        
        if CLLocationManager.locationServicesEnabled() {
            let status = CLLocationManager.authorizationStatus()
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                getCurrentWifiBSSID()
            case .denied, .restricted:
                result(nil)
            case .notDetermined:
                requestLocationPermission()
            @unknown default:
                result(nil)
            }
        } else {
            result(nil)
        }
    }
    
    private func getWifiIPAddress(result: @escaping FlutterResult) {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0 else { return }
        guard let firstAddr = ifaddr else { return }
        
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
        result(address)
    }
    
    private func requestLocationPermission() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        // Request permission for app usage only
        locationManager?.requestWhenInUseAuthorization()
    }
    
    private func getCurrentWifiSSID() {
        guard let interfaces = CNCopySupportedInterfaces() as? [String] else {
            result?(nil)
            return
        }
        
        for interface in interfaces {
            if let info = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any] {
                let ssid = info["SSID"] as? String
                result?(ssid)
                return
            }
        }
        
        result?(nil)
    }
    
    private func getCurrentWifiBSSID() {
        guard let interfaces = CNCopySupportedInterfaces() as? [String] else {
            result?(nil)
            return
        }
        
        for interface in interfaces {
            if let info = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any] {
                let bssid = info["BSSID"] as? String
                result?(bssid)
                return
            }
        }
        
        result?(nil)
    }
    
    // MARK: - CLLocationManagerDelegate
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse:
            // Permissions granted, getting WiFi information
            getCurrentWifiSSID()
        case .authorizedAlways:
            // Permissions granted, getting WiFi information
            getCurrentWifiSSID()
        case .denied, .restricted:
            result?(nil)
        case .notDetermined:
            break
        @unknown default:
            result?(nil)
        }
    }
}
