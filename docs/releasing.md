# Release runbook

## One-time GitHub setup

Create an Android upload keystore and store the base64-encoded keystore in the `ANDROID_KEYSTORE_BASE64` Actions secret. Store the complete `key.properties` contents in `ANDROID_KEY_PROPERTIES`; the password must remain inside that secret and must not be duplicated in a separate repository variable. **Do not pass `GEMINI_API_KEYS`, `SARVAM_API_KEYS`, or `TAVILY_API_KEYS` to a public Android build.** These credentials are recoverable from an APK. Put them in a secure backend proxy instead; the current production workflows intentionally omit them so the public release cannot leak provider credentials.

## Versioning

Update `version:` in `pubspec.yaml` using semantic versioning and commit the change. Create and push an annotated tag:

```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

The tag workflow validates the project, builds a signed `app-release.aab`, uploads it as a workflow artifact, and attaches it to a GitHub Release. A failed signing or quality check blocks publication. The workflow restores the keystore at `android/app/upload-keystore.jks`, matching the Gradle signing configuration.

## Play Store release gate

Before uploading the AAB to Google Play, complete the following checks:

1. Deploy and test the Appwrite Functions required by `docs/production-setup.md` if cloud Documents/Google Drive is enabled.
2. Test the IME on at least one Android 13-or-newer device and one older supported device, including WhatsApp, Telegram, a browser field, gesture navigation, and three-button navigation where available.
3. Verify microphone permission, Native/Roman output, all selectable language layouts, manual translation, document unlinking, URI permission revocation, OAuth cancellation, and lockout expiry.
4. Publish a public privacy-policy URL that matches the Play Console Data safety declaration and names every network provider used by voice, translation, AI, search, or Documents.
5. Upload the signed AAB from the tag workflow to an internal Play testing track before production rollout.

## Rollback

GitHub Releases are immutable artifacts. If a release is defective, mark it as a pre-release or draft and publish a corrected patch version. Do not delete tags or rewrite the `main` branch history.
