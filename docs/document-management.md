# Secure Cloud-Linked Document Management

Bhasha Keyboard stores **references, not documents**. A user links a file through Android's `ACTION_OPEN_DOCUMENT` picker and explicitly grants read access. Google Drive and other installed document providers can appear in that picker. The app stores only the provider-backed `content://` URI, display name, MIME type, label, and link timestamp in local preferences.

The voice command path reuses the existing `VoiceEngine` and `KeyboardController`. Commands such as **“Upload my resume”** are parsed by `DocumentCommand` before the existing Gemini/Sarvam assistant fallback. The matched label selects a linked reference; the document manager then requests device-credential authentication and asks Android to commit the provider URI to the current host field through `InputConnection.commitContent`. Bhasha never reads, uploads, caches, or duplicates the document bytes.

When the current host application does not support Android rich-content insertion, the capability returns a graceful status message instructing the user to choose the file using that application's own picker. Authentication from a system IME service is deliberately fail-closed because an IME cannot safely host an activity result or biometric prompt in every Android version and OEM environment. The launcher activity supports device-credential authentication for flows initiated from the Bhasha app. No OTP is generated or stored by Bhasha; an external provider may require its own sign-in or verification flow.

## User flow

1. Open **Tools → Documents** in the Bhasha app or keyboard.
2. Choose a label such as **Resume**, **Education**, or **General**.
3. Select a file from Google Drive or another Android document provider.
4. To use it, say **“Upload my resume”** while voice typing.
5. Confirm the device credential when Android presents the authentication step.
6. If the host app rejects rich content, use its normal file picker instead.

Unlinking removes the local metadata and releases the persisted URI permission. It does not delete the user's cloud file.

## Security properties

- No Bhasha backend or database is involved.
- No document bytes are placed in logs, preferences, analytics, or AI prompts.
- Provider permissions are requested only through Android's user-facing picker.
- The operation is fail-closed when the device is not secured or the platform cannot authenticate.
- Labels are local metadata and can be removed without affecting the source file.
