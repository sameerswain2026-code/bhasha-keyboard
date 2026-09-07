package com.bhashakeyboard.ime

import android.app.Activity
import android.app.KeyguardManager
import android.content.Intent
import android.os.Bundle

/** Transparent, one-shot device-credential gate used by the IME document flow. */
class DocumentAuthActivity : Activity() {
    companion object { const val REQUEST_CODE = 8103 }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val keyguard = getSystemService(KEYGUARD_SERVICE) as KeyguardManager
        if (!keyguard.isKeyguardSecure) {
            finishWith(false)
            return
        }
        startActivityForResult(
            keyguard.createConfirmDeviceCredentialIntent(
                "Unlock document",
                "Confirm your device credential to share this document"
            ),
            REQUEST_CODE
        )
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE) finishWith(resultCode == RESULT_OK)
    }

    private fun finishWith(success: Boolean) {
        sendBroadcast(Intent("com.bhashakeyboard.DOCUMENT_AUTH").apply {
            setPackage(packageName)
            putExtra("authenticated", success)
        })
        finish()
    }
}
