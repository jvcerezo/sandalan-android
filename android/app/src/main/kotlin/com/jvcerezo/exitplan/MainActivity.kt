package com.jvcerezo.exitplan

import android.view.WindowManager
import android.window.OnBackInvokedCallback
import android.window.OnBackInvokedDispatcher
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.jvcerezo.sandalan/secure"
    private val BACK_CHANNEL = "com.jvcerezo.sandalan/back"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Secure mode channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableSecure" -> {
                    window.setFlags(
                        WindowManager.LayoutParams.FLAG_SECURE,
                        WindowManager.LayoutParams.FLAG_SECURE
                    )
                    result.success(true)
                }
                "disableSecure" -> {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Register back handler for Android 13+ predictive back
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val backChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BACK_CHANNEL)
            onBackInvokedDispatcher.registerOnBackInvokedCallback(
                OnBackInvokedDispatcher.PRIORITY_DEFAULT
            ) {
                // Send back press to Flutter instead of closing the activity
                backChannel.invokeMethod("onBackPressed", null)
            }
        }
    }
}
