package com.manuelcastillo.vinilo

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Canal `vinilo/share`: la hoja de compartir del sistema con el texto
        // y el enlace que manda Dart (ShareService).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vinilo/share")
            .setMethodCallHandler { call, result ->
                if (call.method != "share") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val body = listOfNotNull(call.argument<String>("text"), call.argument<String>("url"))
                    .filter { it.isNotBlank() }
                    .joinToString("\n")
                val send = Intent(Intent.ACTION_SEND).apply {
                    type = "text/plain"
                    putExtra(Intent.EXTRA_TEXT, body)
                }
                startActivity(Intent.createChooser(send, null))
                result.success(true)
            }
    }
}
