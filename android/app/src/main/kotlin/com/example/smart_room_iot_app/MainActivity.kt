package com.example.smart_room_iot_app

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "smart_room_iot_app/config",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "googleMapsApiKey" -> result.success(googleMapsApiKey())
                else -> result.notImplemented()
            }
        }
    }

    private fun googleMapsApiKey(): String {
        val appInfo = packageManager.getApplicationInfo(
            packageName,
            PackageManager.GET_META_DATA,
        )

        return appInfo.metaData
            ?.getString("com.google.android.geo.API_KEY")
            .orEmpty()
    }
}
