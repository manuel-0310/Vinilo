package com.manuelcastillo.vinilo

import android.Manifest
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Canal `vinilo/share` (ShareService en Dart):
        // - `share`: la hoja del sistema con el texto y el enlace.
        // - `shareImage`: la hoja del sistema con la imagen (PNG), el texto y
        //   el enlace.
        // - `instagramStory`: el editor de historias de Instagram con la imagen
        //   de fondo; false si Instagram no está (Dart cae a `shareImage`).
        // - `saveImage`: guarda la imagen en Imágenes/Vinilo.
        // Las imágenes se sirven con ShareImageProvider (sin androidx).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vinilo/share")
            .setMethodCallHandler { call, result ->
                val text = listOfNotNull(call.argument<String>("text"), call.argument<String>("url"))
                    .filter { it.isNotBlank() }
                    .joinToString("\n")
                val png = call.argument<ByteArray>("png")
                when (call.method) {
                    "share" -> {
                        val send = Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TEXT, text)
                        }
                        startActivity(Intent.createChooser(send, null))
                        result.success(true)
                    }
                    "shareImage" -> {
                        if (png == null) {
                            result.success(false)
                        } else {
                            val uri = writeShareImage(png)
                            val send = Intent(Intent.ACTION_SEND).apply {
                                type = "image/png"
                                putExtra(Intent.EXTRA_STREAM, uri)
                                if (text.isNotEmpty()) putExtra(Intent.EXTRA_TEXT, text)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            startActivity(Intent.createChooser(send, null).apply {
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            })
                            result.success(true)
                        }
                    }
                    "instagramStory" -> result.success(png != null && instagramStory(png, call.argument<String>("appId")))
                    "saveImage" -> {
                        if (png == null) {
                            result.error("failed", null, null)
                        } else {
                            saveImage(png, result)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /// Escribe el PNG en la caché (una sola imagen a la vez) y devuelve su
    /// content:// para otras apps.
    private fun writeShareImage(png: ByteArray): Uri {
        val dir = File(cacheDir, ShareImageProvider.DIR).apply { mkdirs() }
        dir.listFiles()?.forEach { it.delete() }
        val file = File(dir, "vinilo-${System.currentTimeMillis()}.png")
        file.writeBytes(png)
        return ShareImageProvider.uriFor(this, file.name)
    }

    private fun instagramStory(png: ByteArray, appId: String?): Boolean {
        val uri = writeShareImage(png)
        val intent = Intent("com.instagram.share.ADD_TO_STORY").apply {
            setDataAndType(uri, "image/png")
            if (!appId.isNullOrEmpty()) putExtra("source_application", appId)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        grantUriPermission("com.instagram.android", uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        if (intent.resolveActivity(packageManager) == null) return false
        startActivity(intent)
        return true
    }

    private fun saveImage(png: ByteArray, result: MethodChannel.Result) {
        val name = "vinilo-${System.currentTimeMillis()}.png"
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val values = ContentValues().apply {
                    put(MediaStore.Images.Media.DISPLAY_NAME, name)
                    put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                    put(MediaStore.Images.Media.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/Vinilo")
                }
                val uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                    ?: throw IllegalStateException("insert")
                contentResolver.openOutputStream(uri)?.use { it.write(png) }
                    ?: throw IllegalStateException("stream")
            } else {
                // Android 9 o anterior: hace falta el permiso de escritura.
                if (checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
                    requestPermissions(arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE), 7)
                    result.error("denied", null, null)
                    return
                }
                @Suppress("DEPRECATION")
                val dir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), "Vinilo")
                dir.mkdirs()
                val file = File(dir, name)
                file.writeBytes(png)
                @Suppress("DEPRECATION")
                sendBroadcast(Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, Uri.fromFile(file)))
            }
            result.success(true)
        } catch (e: Exception) {
            result.error("failed", e.message, null)
        }
    }
}
