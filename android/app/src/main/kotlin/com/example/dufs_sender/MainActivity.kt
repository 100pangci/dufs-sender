package com.example.dufs_sender

import android.content.ContentValues
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.OpenableColumns
import androidx.annotation.NonNull
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "dufs_sender/file_helper"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getFileInfo" -> {
                        val uriStr = call.argument<String>("uri")
                        if (uriStr == null) {
                            result.error("INVALID_ARG", "URI is null", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val uri = Uri.parse(uriStr)
                            val info = getFileInfo(uri)
                            result.success(info)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }
                    "copyToTemp" -> {
                        val uriStr = call.argument<String>("uri")
                        val destDir = call.argument<String>("destDir")
                        if (uriStr == null || destDir == null) {
                            result.error("INVALID_ARG", "URI or destDir is null", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val path = copyToTemp(uriStr, destDir)
                            result.success(path)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }
                    "getFileSize" -> {
                        val uriStr = call.argument<String>("uri")
                        if (uriStr == null) {
                            result.error("INVALID_ARG", "URI is null", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val uri = Uri.parse(uriStr)
                            val size = getFileSize(uri)
                            result.success(size)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun getFileInfo(uri: Uri): Map<String, Any?> {
        val info = mutableMapOf<String, Any?>()
        val cursor = contentResolver.query(uri, null, null, null, null)
        cursor?.use {
            if (it.moveToFirst()) {
                val nameIndex = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (nameIndex >= 0) {
                    info["name"] = it.getString(nameIndex)
                }
                val sizeIndex = it.getColumnIndex(OpenableColumns.SIZE)
                if (sizeIndex >= 0) {
                    info["size"] = it.getLong(sizeIndex)
                }
            }
        }
        if (!info.containsKey("name")) {
            info["name"] = uri.lastPathSegment ?: "unknown"
        }
        if (!info.containsKey("size")) {
            info["size"] = -1L
        }
        return info
    }

    private fun getFileSize(uri: Uri): Long {
        val cursor = contentResolver.query(uri, null, null, null, null)
        cursor?.use {
            if (it.moveToFirst()) {
                val sizeIndex = it.getColumnIndex(OpenableColumns.SIZE)
                if (sizeIndex >= 0) {
                    return it.getLong(sizeIndex)
                }
            }
        }
        return -1L
    }

    private fun copyToTemp(uriStr: String, destDir: String): String? {
        val uri = Uri.parse(uriStr)

        val info = getFileInfo(uri)
        val fileName = info["name"] as? String ?: "unknown_file"
        val destFile = File(destDir, sanitizeFileName(fileName))

        val inputStream = contentResolver.openInputStream(uri)
        inputStream?.use { input ->
            FileOutputStream(destFile).use { output ->
                input.copyTo(output)
            }
        }

        return destFile.absolutePath
    }

    private fun sanitizeFileName(name: String): String {
        return name.replace(Regex("[/\\\\]"), "_")
    }
}
