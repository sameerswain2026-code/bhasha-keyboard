package com.bhashakeyboard.ime

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.provider.Settings
import android.view.inputmethod.InputMethodManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var micStream: MicStreamHandler? = null
    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        MethodChannel(engine.dartExecutor.binaryMessenger, "bhasha/system").setMethodCallHandler { call, result ->
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
        micStream = MicStreamHandler()
        EventChannel(engine.dartExecutor.binaryMessenger, "bhasha/mic").setStreamHandler(micStream)
    }
    private fun isImeEnabled() = (getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager).enabledInputMethodList.any { it.packageName == packageName }
    private fun isImeSelected() = (Settings.Secure.getString(contentResolver, Settings.Secure.DEFAULT_INPUT_METHOD) ?: "").startsWith(packageName)
    private fun hasMic() = ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
    private fun vibrate(d: Int?, a: Int?): Boolean { val v = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator ?: return false; if (!v.hasVibrator()) return false; val ms=(d?:12).coerceIn(1,50).toLong(); if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) v.vibrate(VibrationEffect.createOneShot(ms,(a?:70).coerceIn(1,255))) else @Suppress("DEPRECATION") v.vibrate(ms); return true }
    override fun onDestroy() { micStream?.stopRecording(); super.onDestroy() }
}
