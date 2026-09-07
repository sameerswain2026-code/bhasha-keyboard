# Bhasha Keyboard Production Audit

## Executive conclusion

Bhasha Keyboard has a substantial Flutter and Android IME implementation. The repository already includes multilingual layouts, transliteration, suggestions, voice modes, emoji, stickers, GIF sharing, clipboard history, text editing, themes, one-handed mode, floating mode, onboarding, optional AI integrations, tests, and GitHub Actions validation. The current codebase is not yet equivalent to a fully certified Play Store release because device-matrix testing, release signing secrets, provider backend/privacy decisions, store listing assets, and a complete public privacy policy remain operational release requirements.

The audited branch received a production-hardening commit that preserves the existing feature architecture and passed the repository CI pipeline.

The follow-up integration also brought the previously isolated Documents feature branch into `main`, restored the IME lifecycle and writing-tool APIs that had been overwritten during the merge, and added a responsive Manual Translate panel. Native Transcribe language selection now synchronizes the visible keyboard language/script, so selecting Hindi (or another supported language) with Native output no longer leaves an English alphabet keyboard on screen.

## Audit scope

The review covered the Flutter application, the Android launcher and input-method service, the Flutter-to-InputConnection bridge, persistence, setup flow, release Gradle configuration, CI workflows, tests, privacy notes, and release documentation. The primary product risk areas were treated as input correctness, release safety, user data handling, accessibility, and Android lifecycle behavior.

## Implemented fixes

| Area | Finding | Implemented change | Status |
| --- | --- | --- | --- |
| Release signing | The release build type could fall back to the debug keystore. The existing guard covered `assembleRelease` but not `bundleRelease`. | Release signing now always uses the explicit release signing configuration, and both APK and AAB release tasks fail early when `android/key.properties` is absent. | Complete |
| Java compatibility | Android compilation targeted Java 11 while the documented release environment uses Java 17. | Android and Kotlin compilation targets are aligned to Java 17. | Complete |
| Android data safety | The application did not explicitly disable backup or cleartext traffic. | Android backup is disabled, right-to-left support is declared, and cleartext traffic is disabled by default. | Complete |
| Keyboard feedback | `KeyWidget` triggered haptic feedback directly, even when the user had disabled haptics in Settings. | Direct widget haptics were removed; controller-level feedback remains the single setting-aware feedback path. | Complete |
| Accessibility | Individual keys had no semantic button labels for accessibility services. | Keys now expose Flutter `Semantics` button metadata and readable labels. | Complete |
| Writing tools safety | Selected-text tools could treat clipboard contents as selected host text when no host selection existed. This could cause an unexpected rewrite or replacement. | The IME bridge now returns only actual host-selected text. Clipboard paste remains an explicit action. | Complete |
| Documents component | The secure document workflow existed only on a feature branch and was absent from `main`. | Documents manager, Android auth activity, system picker/URI handling, metadata repository, keyboard panel, command upload flow, tests, and production setup documentation are now integrated. | Complete in code; external Appwrite Functions still required for cloud OAuth/Drive production |
| Native language keyboard | Transcribe Native/Roman selection did not change the visible alphabet keyboard. | Transcribe language/style selection now updates the typing language and script, with safe capability guards. | Complete |
| Manual translation | Translation was available mainly for host selection/voice flows, with no explicit text-entry workspace. | Added a responsive Manual Translate tool with source/target selectors, in-panel input keyboard, result preview, copy, and insert actions. | Complete |

## Existing strengths confirmed

The controller already queues preferences written before asynchronous `SharedPreferences` initialization completes. The IME bridge serializes host edits, resynchronizes after external paste/cut/autocorrect changes, handles cursor-aware replacement, and accounts for surrogate pairs. The Android service resets transient keyboard state when a new host field receives focus. Release automation requires signing secrets in CI, and the repository does not track local keystores or `key.properties`.

The test suite covers core insertion, cursor positioning, deletion, selection, emoji deletion, swipe deletion, caps lock, enter actions, language metadata, transliteration, voice behavior, panels, setup flow, and AI command behavior. CI also runs formatting checks, static analysis, tests with coverage, and a debug APK build.

## Verification

The pushed commit passed GitHub Actions CI. The successful run completed the following checks:

| Check | Result |
| --- | --- |
| Dart formatting check | Passed |
| `flutter analyze` | Passed |
| `flutter test --coverage` | Passed |
| `flutter build apk --debug` | Passed |

The CI runner reported a non-blocking GitHub Actions annotation that some actions target Node.js 20 while the runner is forcing Node.js 24. This is an infrastructure warning rather than an application failure and should be addressed when the workflow action versions provide a stable Node.js 24-compatible migration path.

## Remaining release requirements

A production Play Store release still requires a real signed upload keystore and validated GitHub secrets. The release workflow intentionally refuses to publish an unsigned or debug-signed artifact. A physical-device test matrix is also required because an Android IME depends on OEM behavior, navigation mode, screen density, permission state, host editor implementation, and Android version. At minimum, test Android 6, Android 10, Android 13, and Android 15 or newer on both gesture and three-button navigation where available.

The repository's privacy note is not yet a complete public privacy policy. Before enabling network-backed voice, AI, or search providers for Play Store users, publish a policy that identifies every provider, explains what text or audio leaves the device, states retention and deletion behavior, provides a support contact, and matches the Play Console Data safety declaration. Provider API keys should not be shipped directly in a public consumer APK; a controlled backend proxy or a deliberately disabled provider configuration is required.

The Documents UI is now present in the release branch, but its cloud portion must remain gated until the server-side Appwrite Functions described in `docs/production-setup.md` are deployed and tested. Local Android document linking and host-app attachment fallback do not require those Functions.

The Play Store release process also needs final store assets, application screenshots, content declarations, target-API compliance confirmation, an app signing plan, crash reporting configuration if desired, and a privacy-policy URL. These are release operations rather than safe assumptions that can be completed from the repository alone.

## Commit

The implemented changes are in commits `d2739b1` and `bfbb15f`, pushed to the connected repository's `main` branch.

## Recommended next phase

The next engineering phase should add Android instrumentation tests around the IME service and host selection synchronization, run a physical-device compatibility matrix, complete the privacy policy and provider architecture, add release artifact validation for the signed AAB, and perform a dedicated visual pass across small phones, tablets, dark mode, large font settings, RTL Urdu/Kashmiri/Sindhi, and low-memory devices.

## References

[1]: https://developer.android.com/develop/ui/views/touch-and-input/creating-an-input-method "Android input method documentation"
[2]: https://developer.android.com/privacy-and-security/risks/backup "Android backup and restore security guidance"
[3]: https://developer.android.com/privacy-and-security/security-config "Android network security configuration guidance"
[4]: https://support.google.com/googleplay/android-developer/answer/9859455 "Google Play app quality and release guidance"
[5]: https://support.google.com/googleplay/android-developer/answer/10787469 "Google Play Data safety section guidance"
