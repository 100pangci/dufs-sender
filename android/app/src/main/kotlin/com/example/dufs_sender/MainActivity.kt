package com.example.dufs_sender

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.provider.DocumentsContract
import androidx.activity.result.contract.ActivityResultContracts
import androidx.annotation.NonNull
import androidx.core.content.FileProvider
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "dufs_sender/file_helper"
    private var pickDirResult: MethodChannel.Result? = null

    private val pickDirLauncher = registerForActivityResult(
        ActivityResultContracts.OpenDocumentTree()
    ) { uri ->
        val pending = pickDirResult
        pickDirResult = null
        if (uri != null) {
            val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            try { contentResolver.takePersistableUriPermission(uri, flags) } catch (_: Exception) {}
            pending?.success(uri.toString())
        } else {
            pending?.success(null)
        }
    }

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
                    "listDirectory" -> {
                        val uriStr = call.argument<String>("uri")
                        if (uriStr == null) {
                            result.error("INVALID_ARG", "URI is null", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val files = listDirectory(uriStr)
                            result.success(files)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }
                    "pickDirectory" -> {
                        pickDirResult = result
                        pickDirLauncher.launch(null)
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

    private fun listDirectory(uriStr: String): List<Map<String, Any?>> {
        val uri = Uri.parse(uriStr)

        takeUriReadPermission(uri)

        var result = tryContentResolver(uri)
        if (result != null && result.isNotEmpty()) return result

        result = tryAsDocumentFile(uri)
        if (result != null && result.isNotEmpty()) return result

        return emptyList()
    }

    private fun takeUriReadPermission(uri: Uri) {
        try {
            contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        } catch (_: Exception) {}
    }

    private fun tryContentResolver(uri: Uri): List<Map<String, Any?>>? {
        if (!DocumentsContract.isTreeUri(uri)) return null
        return try {
            val treeDocId = DocumentsContract.getTreeDocumentId(uri)
            listViaDocumentsContract(uri, treeDocId, "")
        } catch (_: Exception) {
            null
        }
    }

    private fun tryAsDocumentFile(uri: Uri): List<Map<String, Any?>>? {
        if (DocumentsContract.isTreeUri(uri)) {
            val doc = DocumentFile.fromTreeUri(this, uri)
            if (doc != null && doc.isDirectory) {
                return listFilesRecursive(doc, "")
            }
        }

        try {
            val treeDocId = DocumentsContract.getTreeDocumentId(uri)
            val treeUri = DocumentsContract.buildDocumentUriUsingTree(uri, treeDocId)
            takeUriReadPermission(treeUri)
            val doc = DocumentFile.fromTreeUri(this, treeUri)
            if (doc != null && doc.isDirectory) {
                return listFilesRecursive(doc, "")
            }
        } catch (_: Exception) {}

        try {
            val doc = DocumentFile.fromSingleUri(this, uri)
            if (doc != null && doc.isDirectory) {
                return listFilesRecursive(doc, "")
            }
        } catch (_: Exception) {}

        return null
    }

    private fun listViaDocumentsContract(
        treeUri: Uri,
        parentDocId: String,
        relativePrefix: String
    ): List<Map<String, Any?>> {
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, parentDocId)
        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_SIZE,
        )

        val results = mutableListOf<Map<String, Any?>>()
        val cursor = contentResolver.query(childrenUri, projection, null, null, null)
        cursor?.use { c ->
            val idIdx = c.getColumnIndex(DocumentsContract.Document.COLUMN_DOCUMENT_ID)
            val nameIdx = c.getColumnIndex(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
            val mimeIdx = c.getColumnIndex(DocumentsContract.Document.COLUMN_MIME_TYPE)
            val sizeIdx = c.getColumnIndex(DocumentsContract.Document.COLUMN_SIZE)

            while (c.moveToNext()) {
                val docId = if (idIdx >= 0) c.getString(idIdx) else null ?: continue
                val name = if (nameIdx >= 0) c.getString(nameIdx) else "unknown"
                val mimeType = if (mimeIdx >= 0) c.getString(mimeIdx) else ""
                val size = if (sizeIdx >= 0 && !c.isNull(sizeIdx)) c.getLong(sizeIdx) else null
                val path = if (relativePrefix.isEmpty()) name else "$relativePrefix/$name"

                if (mimeType == DocumentsContract.Document.MIME_TYPE_DIR) {
                    results.addAll(listViaDocumentsContract(treeUri, docId, path))
                } else {
                    val docUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, docId)
                    results.add(mapOf(
                        "name" to name,
                        "uri" to docUri.toString(),
                        "isDirectory" to false,
                        "size" to size,
                        "relativePath" to path,
                    ))
                }
            }
        }
        return results
    }

    private fun listFilesRecursive(dir: DocumentFile, prefix: String): List<Map<String, Any?>> {
        val results = mutableListOf<Map<String, Any?>>()
        val children = dir.listFiles() ?: return results
        for (child in children) {
            if (child.isDirectory) {
                val subPrefix = if (prefix.isEmpty()) {
                    child.name ?: ""
                } else {
                    "$prefix/${child.name ?: ""}"
                }
                results.addAll(listFilesRecursive(child, subPrefix))
            } else if (child.isFile) {
                val info = mutableMapOf<String, Any?>()
                info["name"] = child.name ?: "unknown"
                info["uri"] = child.uri.toString()
                info["isDirectory"] = false
                info["size"] = child.length()
                info["relativePath"] = if (prefix.isEmpty()) {
                    child.name ?: ""
                } else {
                    "$prefix/${child.name ?: ""}"
                }
                results.add(info)
            }
        }
        return results
    }
}
