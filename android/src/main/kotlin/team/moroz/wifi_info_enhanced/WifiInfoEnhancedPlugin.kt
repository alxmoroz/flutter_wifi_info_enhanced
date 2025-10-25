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
            "getWifiName" -> {
                getWifiName(result)
            }
            "getWifiBSSID" -> {
                getWifiBSSID(result)
            }
            "getWifiIPAddress" -> {
                getWifiIPAddress(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun getWifiName(result: Result) {
        try {
            // Check location permission for Android 10+
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                if (!hasLocationPermission()) {
                    // Request permission if Activity is available
                    if (activity != null) {
                        requestLocationPermission(result, "getWifiName")
                        return
                    } else {
                        result.success(null)
                        return
                    }
                }
                
                if (!isLocationServiceEnabled()) {
                    result.success(null)
                    return
                }
            }
            
            val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val wifiInfo = wifiManager.connectionInfo
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // On Android 10+ special permission is required
                val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
                val network = connectivityManager.activeNetwork
                val capabilities = connectivityManager.getNetworkCapabilities(network)
                
                if (capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true) {
                    // WiFi is connected, but SSID may be unavailable
                    val ssid = wifiInfo.ssid
                    if (ssid == "<unknown ssid>" || ssid == null || ssid.isEmpty()) {
                        result.success(null)
                    } else {
                        result.success(ssid.replace("\"", ""))
                    }
                } else {
                    result.success(null)
                }
            } else {
                // On older Android versions
                val ssid = wifiInfo.ssid
                result.success(if (ssid == "<unknown ssid>") null else ssid?.replace("\"", ""))
            }
        } catch (e: Exception) {
            result.success(null)
        }
    }

    private fun getWifiBSSID(result: Result) {
        try {
            // Check location permission for Android 10+
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                if (!hasLocationPermission()) {
                    // Request permission if Activity is available
                    if (activity != null) {
                        requestLocationPermission(result, "getWifiBSSID")
                        return
                    } else {
                        result.success(null)
                        return
                    }
                }
                
                if (!isLocationServiceEnabled()) {
                    result.success(null)
                    return
                }
            }
            
            val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val wifiInfo = wifiManager.connectionInfo
            result.success(wifiInfo.bssid)
        } catch (e: Exception) {
            result.success(null)
        }
    }

    private fun getWifiIPAddress(result: Result) {
        try {
            val interfaces = NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val networkInterface = interfaces.nextElement()
                val addresses = networkInterface.inetAddresses
                while (addresses.hasMoreElements()) {
                    val address = addresses.nextElement()
                    if (!address.isLoopbackAddress && address is InetAddress && address.hostAddress?.indexOf(':') == -1) {
                        result.success(address.hostAddress)
                        return
                    }
                }
            }
            result.success(null)
        } catch (e: Exception) {
            result.success(null)
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
        } ?: result.success(null)
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
                            "getWifiName" -> getWifiName(result)
                            "getWifiBSSID" -> getWifiBSSID(result)
                        }
                    }
                }
            } else {
                // Permission denied
                pendingResult?.success(null)
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
