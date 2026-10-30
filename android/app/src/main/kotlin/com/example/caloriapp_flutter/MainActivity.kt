package com.example.caloriapp_flutter

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import kotlin.math.max

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.caloriapp_flutter/comunidade_platform"
    private val pickImageRequestCode = 9041
    private var pendingPickResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickImage" -> {
                        if (pendingPickResult != null) {
                            result.error("ALREADY_ACTIVE", "Seletor de imagem já está aberto", null)
                            return@setMethodCallHandler
                        }
                        pendingPickResult = result
                        try {
                            val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                                type = "image/*"
                                addCategory(Intent.CATEGORY_OPENABLE)
                            }
                            startActivityForResult(
                                Intent.createChooser(intent, "Selecionar foto do prato"),
                                pickImageRequestCode
                            )
                        } catch (e: Exception) {
                            pendingPickResult = null
                            result.success(null)
                        }
                    }
                    "openUrl" -> {
                        val url = call.argument<String>("url")
                        if (url.isNullOrBlank()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickImageRequestCode) return

        val callback = pendingPickResult
        pendingPickResult = null
        if (callback == null) return

        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            callback.success(null)
            return
        }

        val uri: Uri = data.data!!
        try {
            val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() }
            if (bytes == null || bytes.isEmpty()) {
                callback.success(null)
                return
            }

            val decoded = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            if (decoded != null) {
                val maxDim = max(decoded.width, decoded.height)
                val finalBitmap = if (maxDim > 1080) {
                    val scale = 1080f / maxDim.toFloat()
                    val w = (decoded.width * scale).toInt().coerceAtLeast(1)
                    val h = (decoded.height * scale).toInt().coerceAtLeast(1)
                    Bitmap.createScaledBitmap(decoded, w, h, true)
                } else {
                    decoded
                }
                val out = ByteArrayOutputStream()
                finalBitmap.compress(Bitmap.CompressFormat.JPEG, 82, out)
                val base64Str = Base64.encodeToString(out.toByteArray(), Base64.NO_WRAP)
                callback.success("data:image/jpeg;base64,$base64Str")
            } else {
                val base64Str = Base64.encodeToString(bytes, Base64.NO_WRAP)
                callback.success("data:image/jpeg;base64,$base64Str")
            }
        } catch (e: Exception) {
            callback.success(null)
        }
    }
}
