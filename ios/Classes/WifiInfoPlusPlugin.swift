import Flutter
import UIKit
import SystemConfiguration.CaptiveNetwork
import CoreLocation

public class WifiInfoPlusPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager?
    private var result: FlutterResult?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "wifi_info_plus", binaryMessenger: registrar.messenger())
        let instance = WifiInfoPlusPlugin()
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
        
        print("WifiInfoPlus: getWifiName called")
        
        // Проверяем разрешения на геолокацию
        if CLLocationManager.locationServicesEnabled() {
            let status = CLLocationManager.authorizationStatus()
            print("WifiInfoPlus: Location status = \(status.rawValue)")
            
            switch status {
            case .authorizedWhenInUse:
                // Разрешения есть, получаем SSID
                print("WifiInfoPlus: Authorized when in use, getting SSID")
                getCurrentWifiSSID()
            case .authorizedAlways:
                // Разрешения есть, получаем SSID
                print("WifiInfoPlus: Authorized always, getting SSID")
                getCurrentWifiSSID()
            case .denied, .restricted:
                // Разрешения отклонены
                print("WifiInfoPlus: Location permission denied or restricted")
                result(nil)
            case .notDetermined:
                // Запрашиваем разрешения только на время использования
                print("WifiInfoPlus: Requesting location permission")
                requestLocationPermission()
            @unknown default:
                print("WifiInfoPlus: Unknown location status")
                result(nil)
            }
        } else {
            print("WifiInfoPlus: Location services not enabled")
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
            
            // Проверяем IPv4 интерфейс
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" { // Wi-Fi интерфейс
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
        // Запрашиваем разрешение только на время использования приложения
        locationManager?.requestWhenInUseAuthorization()
    }
    
    private func getCurrentWifiSSID() {
        print("WifiInfoPlus: getCurrentWifiSSID called")
        
        guard let interfaces = CNCopySupportedInterfaces() as? [String] else {
            print("WifiInfoPlus: CNCopySupportedInterfaces returned nil")
            result?(nil)
            return
        }
        
        print("WifiInfoPlus: Found \(interfaces.count) interfaces")
        
        for interface in interfaces {
            print("WifiInfoPlus: Checking interface: \(interface)")
            if let info = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any] {
                let ssid = info["SSID"] as? String
                print("WifiInfoPlus: Found SSID: \(ssid ?? "nil")")
                result?(ssid)
                return
            } else {
                print("WifiInfoPlus: CNCopyCurrentNetworkInfo returned nil for interface \(interface)")
            }
        }
        
        print("WifiInfoPlus: No SSID found")
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
            // Разрешения получены, получаем информацию о Wi-Fi
            getCurrentWifiSSID()
        case .authorizedAlways:
            // Разрешения получены, получаем информацию о Wi-Fi
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
