package com.bhashakeyboard.ime

import android.Manifest
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.VibrationEffect
import android.os.Vibrator
import android.content.pm.PackageManager
import android.provider.Settings
import android.provider.OpenableColumns
import android.view.inputmethod.InputMethodManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/** Launcher/setup activity and the only place where document linking/auth UI runs. */
class MainActivity : FlutterActivity() {
    private var micStream: MicStreamHandler? = null
    private var pendingDocumentResult: MethodChannel.Result? = null
    private val documentRequestCode = 8101
    private val authRequestCode = 8102

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "bhasha/system")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openImeSettings" -> { startActivity(Intent(Settings.ACTION_INPUT_METHOD_SETTINGS)); result.success(true) }
                    "showImePicker" -> { (getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager).showInputMethodPicker(); result.success(true) }
                    "isImeEnabled" -> result.success(isImeEnabled())
                    "isImeSelected" -> result.success(isImeSelected())
                    "hasMicPermission" -> result.success(hasMic())
                    "requestMicPermission" -> { if (!hasMic()) ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.RECORD_AUDIO), 7001); result.success(hasMic()) }
                    "startMic" -> { if (hasMic()) { micStream?.startRecording(); result.success(true) } else result.success(false) }
                    "stopMic" -> { micStream?.stopRecording(); result.success(true) }
                    "haptic" -> result.success(vibrate(call.argument<Int>("durationMs"), call.argument<Int>("amplitude")))
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "bhasha/documents")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickDocument" -> {
                        pendingDocumentResult = result
                        startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                            type = "*/*"
                            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("application/pdf", "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "text/plain", "image/*"))
                        }, documentRequestCode)
                    }
                    "authenticateDocument" -> authenticateDocument(result)
                    "commitDocument" -> {
                        val uri = call.argument<String>("uri")?.let(Uri::parse)
                        if (uri == null) { result.success(false) } else {
                            startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).apply {
                                type = call.argument<String>("mimeType") ?: "application/octet-stream"
                                putExtra(Intent.EXTRA_STREAM, uri)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }, "Share document securely"))
                            result.success(true)
                        }
                    }
                    "releaseDocument" -> result.success(true)
                    "openDocumentManager" -> result.success(true)
                    else -> result.notImplemented()
                }
            }
        micStream = MicStreamHandler()
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "bhasha/mic").setStreamHandler(micStream)
        handleImeIntent(intent)
        handleMicPermissionIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleImeIntent(intent)
        handleMicPermissionIntent(intent)
    }

    private fun handleMicPermissionIntent(intent: Intent?) {
        if (intent?.action != "com.bhashakeyboard.REQUEST_MIC_PERMISSION") return
        if (!hasMic()) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.RECORD_AUDIO),
                7001,
            )
        }
    }

    private fun handleImeIntent(intent: Intent?) {
        if (intent?.action != "com.bhashakeyboard.OPEN_DOCUMENT_PICKER") return
        startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            type = "*/*"
            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf(
                "application/pdf",
                "application/msword",
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                "text/plain",
                "image/*",
            ))
        }, documentRequestCode)
    }

    private fun authenticateDocument(result: MethodChannel.Result) {
        val keyguard = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        if (!keyguard.isKeyguardSecure) { result.success(false); return }
        pendingDocumentResult = result
        startActivityForResult(keyguard.createConfirmDeviceCredentialIntent("Unlock document", "Confirm your device credential to continue"), authRequestCode)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == documentRequestCode) {
            val uri = data?.data
            if (resultCode != RESULT_OK || uri == null) {
                pendingDocumentResult?.success(null)
                pendingDocumentResult = null
                sendBroadcast(Intent("com.bhashakeyboard.DOCUMENT_PICK").apply {
                    setPackage(packageName)
                })
                return
            }
            try { contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION) } catch (_: SecurityException) {}
            val name = displayName(uri)
            val mime = contentResolver.getType(uri) ?: "application/octet-stream"
            pendingDocumentResult?.success(mapOf("uri" to uri.toString(), "displayName" to name, "mimeType" to mime))
            pendingDocumentResult = null
            sendBroadcast(Intent("com.bhashakeyboard.DOCUMENT_PICK").apply {
                setPackage(packageName)
                putExtra("uri", uri.toString())
                putExtra("displayName", name)
                putExtra("mimeType", mime)
            })
        } else if (requestCode == authRequestCode) {
            val result = pendingDocumentResult ?: return
            pendingDocumentResult = null
            result.success(resultCode == RESULT_OK)
        }
    }

    private fun isImeEnabled(): Boolean = (getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager).enabledInputMethodList.any { it.packageName == packageName }
    private fun isImeSelected(): Boolean = (Settings.Secure.getString(contentResolver, Settings.Secure.DEFAULT_INPUT_METHOD) ?: "").startsWith(packageName)
    private fun hasMic(): Boolean = ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED

    private fun vibrate(durationValue: Int?, amplitudeValue: Int?): Boolean {
        val duration = (durationValue ?: 12).coerceIn(1, 50).toLong()
        val amplitude = (amplitudeValue ?: 70).coerceIn(1, 255)
        val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator ?: return false
        if (!vibrator.hasVibrator()) return false
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createOneShot(duration, amplitude))
        } else {
            @Suppress("DEPRECATION") vibrator.vibrate(duration)
        }
        return true
    }

    private fun displayName(uri: Uri): String {
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) return cursor.getString(0) ?: "Document"
        }
        return uri.lastPathSegment ?: "Document"
    }

    override fun onDestroy() { micStream?.stopRecording(); super.onDestroy() }
}
