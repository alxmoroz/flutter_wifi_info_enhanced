package team.moroz.wifi_info_plus

import android.content.Context
import android.net.wifi.WifiManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.net.InetAddress
import java.net.NetworkInterface

class WifiInfoPlusPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel : MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "wifi_info_plus")
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
            val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val wifiInfo = wifiManager.connectionInfo
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // На Android 10+ требуется специальное разрешение
                val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
                val network = connectivityManager.activeNetwork
                val capabilities = connectivityManager.getNetworkCapabilities(network)
                
                if (capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true) {
                    // WiFi подключен, но SSID может быть недоступен
                    result.success(wifiInfo.ssid?.replace("\"", ""))
                } else {
                    result.success(null)
                }
            } else {
                // На старых версиях Android
                val ssid = wifiInfo.ssid
                result.success(if (ssid == "<unknown ssid>") null else ssid?.replace("\"", ""))
            }
        } catch (e: Exception) {
            result.success(null)
        }
    }

    private fun getWifiBSSID(result: Result) {
        try {
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
}
