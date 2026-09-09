# Bhasha Keyboard — Release Status Report

**तारीख:** 9 September 2026  
**Branch:** `feat/secure-cloud-linked-documents`  
**Latest source commit before this report:** `b8cc46c`

## Executive summary

Bhasha Keyboard का source code, signed Android build workflow, secure document architecture, Appwrite Function source, and deployment documentation तैयार हैं। User-provided confirmation के अनुसार Appwrite token table, both Functions, Function environment variables, and GitHub repository variables save हो चुके हैं।

Public Google Play release अभी तुरंत mark नहीं की जा सकती, क्योंकि final Function-integrated build और physical-device validation का evidence अभी उपलब्ध नहीं है। Latest CI run में दो analyzer errors मिले थे; दोनों इस report के साथ fix किए गए हैं और नया CI run अब फिर चलाना होगा।

## Completed work

| क्षेत्र | स्थिति | प्रमाण/टिप्पणी |
|---|---|---|
| Flutter Android keyboard | Implemented | Existing IME architecture extended; separate assistant/microphone architecture नहीं बनाया गया |
| Native IME haptics | Implemented | Native `InputMethodService` vibration bridge added |
| Keyboard resizing | Implemented | Android IME surface resize path added |
| 22-language layout direction | Implemented in source | Native/Roman layout selection and target-language synchronization added; physical-device evidence बाकी |
| Translation auto-target behavior | Implemented in source | Translation target live keyboard language से synchronized |
| GIF/sticker/media | Implemented in source | `commitContent` with picker/share fallback |
| AI writing tools | Implemented in source | Grammar, rewrite, tone, and reply flow uses existing AI architecture |
| Secure document metadata | Implemented | URI/reference metadata only; document bytes are not stored on Bhasha backend |
| Device authentication | Implemented in source | PIN/biometric gate and failed-attempt lockout path |
| Appwrite `document-links` table | User-confirmed complete | Existing metadata table |
| Appwrite `google-drive-tokens` table | User-confirmed complete | Must contain only encrypted refresh-token metadata |
| `drive-gateway` Function | User-confirmed deployed | Function ID: `6aa12c14001ddeb260df` |
| `ai-gateway` Function | User-confirmed deployed | Function ID: `6aa13043002cddfbdc72` |
| Function source | Complete | `functions/drive-gateway` and `functions/ai-gateway` |
| Provider key boundary | Improved | Gemini/Tavily route through Appwrite gateway when Function ID is present; keys must remain server-side |
| Release signing | Implemented | GitHub Actions restores release keystore and fails closed without it |
| APK/AAB workflow | Implemented | Signed ARM64 APK and App Bundle workflow exists |
| Production documentation | Complete | Setup, privacy, release gates, and device QA documents added |

## Latest CI status

The previously successful signed build was GitHub Actions run [34191228364](https://github.com/sameerswain2026-code/bhasha-keyboard/actions/runs/34191228364), before the final gateway routing changes.

A later CI run found these analyzer issues:

1. `ExecutionStatus` was compared to a string in `appwrite_gateway_client.dart`.
2. A non-const `StateError` was created with `const` in `gemini_service.dart`.

Both issues are fixed in the current working tree. A new signed CI run must pass before treating the Function-integrated AAB as the release candidate.

A separate `action_required` run was associated with an unrelated merge commit (`e8210193...`) and had no jobs. It is not proof of a successful release build and should not be used as the release artifact.

## Remaining mandatory release work

### 1. Rebuild and verify the Function-integrated AAB

After this report commit is pushed, run the production workflow on `feat/secure-cloud-linked-documents`. The run must pass:

- `dart format .`
- `flutter analyze`
- `flutter test`
- signed ARM64 APK build
- signed production AAB build
- signed output verification

The AAB from this successful run becomes the candidate for Play internal testing.

### 2. Verify GitHub variables

The user has confirmed these variables were added:

```text
APPWRITE_DRIVE_GATEWAY_FUNCTION_ID=6aa12c14001ddeb260df
APPWRITE_AI_GATEWAY_FUNCTION_ID=6aa13043002cddfbdc72
```

The current GitHub CLI session returned HTTP 403 when attempting to list Actions variables, so their presence could not be independently verified from the sandbox. The workflow will provide the definitive build-time check once it runs.

### 3. Verify Appwrite Function configuration

For `drive-gateway`, verify:

- Runtime: Node.js 22
- Entrypoint: `index.js`
- Branch: `feat/secure-cloud-linked-documents`
- Root directory: `functions/drive-gateway`
- Build command: `npm install`
- Execute access: authenticated Appwrite users
- Appwrite, Google OAuth, and encryption variables saved

For `ai-gateway`, verify:

- Runtime: Node.js 22
- Entrypoint: `index.js`
- Branch: `feat/secure-cloud-linked-documents`
- Root directory: `functions/ai-gateway`
- Build command: `npm install`
- Execute access: authenticated Appwrite users
- Gemini, Sarvam, and Tavily variables saved

Do not enable anonymous guest execution for either Function.

### 4. Verify Google OAuth

In Appwrite and Google Cloud:

1. Enable Google provider in Appwrite.
2. Configure the exact Appwrite callback URL in Google Cloud.
3. Confirm Android package name `com.bhashakeyboard.ime`.
4. Add release and debug SHA-256 fingerprints.
5. Enable Google Drive API.
6. Use only the least-privilege `drive.file` scope.
7. Test login, cancellation, relaunch, expired session, and revoke.

### 5. Sarvam streaming limitation

Gemini and Tavily have an HTTP gateway path. The current Sarvam voice implementation uses a long-lived WebSocket. The deployed HTTP Function is not a WebSocket relay. Therefore, public Sarvam live voice must not use a Sarvam key embedded in the APK. Either deploy an authenticated WebSocket relay or disable public Sarvam streaming until that relay is available.

### 6. Physical-device QA

Complete the test matrix on one Android 13-or-newer device and one older supported device. The critical scenarios are haptics in third-party apps, Google OAuth deep link, biometric/PIN prompts, Google Drive picker, media `commitContent`, fallback picker, translation target keycaps, voice stop behavior, document lockout, and unlink permission revocation.

Use [the device QA template](device-qa-template.md) and retain screenshots or screen recordings for failed or important scenarios.

### 7. Play Console compliance

Before public rollout:

1. Publish a privacy policy URL.
2. Complete the Data Safety form based on deployed behavior.
3. Provide account/data deletion instructions.
4. Provide Google Drive unlink/revoke behavior.
5. Complete content rating and target audience forms.
6. Add app icon, feature graphic, screenshots, description, and support email.
7. Upload the signed AAB to Internal testing.
8. Test installation and upgrade from the internal track.
9. Fix any crash, OAuth, keyboard, or permission issues.
10. Move to closed testing or production only after internal testing passes.

## What is not required now

An advertising Function is not required for Play Store publication. AdMob can be added later, but it introduces consent, privacy, and Data Safety work. It should not delay the keyboard release.

A separate backend file-storage service is not required and should not be added. The privacy requirement is that document bytes remain in the user's Drive/provider; Appwrite stores only references and minimal metadata.

## Release decision

| Release level | Current decision |
|---|---|
| Source implementation complete | Yes |
| Appwrite Function source ready | Yes |
| Functions user-confirmed deployed | Yes |
| Function IDs user-confirmed saved in GitHub | Yes, not independently visible to current CLI token |
| Latest Function-integrated CI build passed | Not yet; analyzer fixes are now applied |
| Google OAuth physical-device test passed | Not evidenced yet |
| Haptics/media/document physical-device test passed | Not evidenced yet |
| Play internal testing upload | Not yet evidenced |
| Public Play Store release | Not yet safe to claim |

## Required next action

Run the production workflow again from the latest commit. If it passes, download the new signed AAB and upload it to Play Console Internal testing. Then complete the physical-device matrix before public rollout.

## References

[1]: https://appwrite.io/docs/products/functions "Appwrite Functions documentation"
[2]: https://appwrite.io/docs/products/auth/oauth2 "Appwrite OAuth2 documentation"
[3]: https://developers.google.com/drive/api/guides/about-sdk "Google Drive API documentation"
[4]: https://support.google.com/googleplay/android-developer/answer/9859152 "Google Play release guidance"
[5]: https://support.google.com/googleplay/android-developer/answer/10787469 "Google Play Data safety guidance"

**Prepared by:** Manus AI
