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
            
            // Check if WiFi is connected
            val isWifiConnected = capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true
            
            if (!isWifiConnected) {
                val ipAddress = getWifiIPAddress()
                result.success(mapOf(
                    "availability" to "notConnected",
                    "ssid" to null,
                    "bssid" to null,
                    "ipAddress" to ipAddress
                ))
                return
            }
            
            // Check location permission for Android 10+
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                if (!hasLocationPermission()) {
                    // Request permission if Activity is available
                    if (activity != null) {
                        requestLocationPermission(result)
                        return
                    } else {
                        val ipAddress = getWifiIPAddress()
                        result.success(mapOf(
                            "availability" to "permissionDenied",
                            "ssid" to null,
                            "bssid" to null,
                            "ipAddress" to ipAddress
                        ))
                        return
                    }
                }
                
                if (!isLocationServiceEnabled()) {
                    val ipAddress = getWifiIPAddress()
                    result.success(mapOf(
                        "availability" to "locationDisabled",
                        "ssid" to null,
                        "bssid" to null,
                        "ipAddress" to ipAddress
                    ))
                    return
                }
            }
            
            val wifiInfo = wifiManager.connectionInfo
            val ipAddress = getWifiIPAddress()
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // On Android 10+ special permission is required
                val ssid = wifiInfo.ssid
                val bssid = wifiInfo.bssid
                
                if (ssid == "<unknown ssid>" || ssid == null || ssid.isEmpty()) {
                    result.success(mapOf(
                        "availability" to "restrictedByOs",
                        "ssid" to null,
                        "bssid" to bssid,
                        "ipAddress" to ipAddress
                    ))
                } else {
                    result.success(mapOf(
                        "availability" to "available",
                        "ssid" to ssid.replace("\"", ""),
                        "bssid" to bssid,
                        "ipAddress" to ipAddress
                    ))
                }
            } else {
                // On older Android versions
                val ssid = wifiInfo.ssid
                val bssid = wifiInfo.bssid
                
                if (ssid == "<unknown ssid>") {
                    result.success(mapOf(
                        "availability" to "restrictedByOs",
                        "ssid" to null,
                        "bssid" to bssid,
                        "ipAddress" to ipAddress
                    ))
                } else {
                    result.success(mapOf(
                        "availability" to "available",
                        "ssid" to ssid?.replace("\"", ""),
                        "bssid" to bssid,
                        "ipAddress" to ipAddress
                    ))
                }
            }
        } catch (e: Exception) {
            val ipAddress = getWifiIPAddress()
            result.success(mapOf(
                "availability" to "unknown",
                "ssid" to null,
                "bssid" to null,
                "ipAddress" to ipAddress
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
    private fun requestLocationPermission(result: Result) {
        pendingResult = result
        
        activity?.let {
            ActivityCompat.requestPermissions(
                it,
                arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
                PERMISSION_REQUEST_CODE
            )
        } ?: run {
            val ipAddress = getWifiIPAddress()
            result.success(mapOf(
                "availability" to "permissionDenied",
                "ssid" to null,
                "bssid" to null,
                "ipAddress" to ipAddress
            ))
        }
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
                pendingResult?.let { result ->
                    getWifiInfo(result)
                }
            } else {
                // Permission denied
                val ipAddress = getWifiIPAddress()
                pendingResult?.success(mapOf(
                    "availability" to "permissionDenied",
                    "ssid" to null,
                    "bssid" to null,
                    "ipAddress" to ipAddress
                ))
            }
            
            pendingResult = null
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