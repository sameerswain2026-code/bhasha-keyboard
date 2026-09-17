# Bhasha Keyboard Refactor Report

## Scope completed

The document and Google Drive feature stack was removed from the Android and Flutter product path. This includes the document manager, Appwrite document repository, Drive workspace, documents panel, document-auth activity, native document channels, Drive gateway Function, database/document-link configuration, and Drive-only tests/dependencies.

The remaining product path is local-first and retains the multilingual keyboard, native/Roman layouts, voice pipeline, translation, AI Assistant, GIFs, stickers, emoji, clipboard, text editing, resize, themes, floating/one-handed modes, settings, and the existing IME bridge. The companion onboarding/dashboard was simplified to avoid account or document setup and keeps Bhasha branding.

## Validation

The reduced server-side AI Function passed six Node tests and `node --check`. The Android manifest parses as XML, Kotlin brace counts are balanced for `MainActivity.kt` and `BhashaImeService.kt`, and `git diff --check` passes.

The supplied comparison APK was found at `/home/ubuntu/upload/DOC-20260907-WA0022.apk` and is 20 MB. It was inspected for package assets and confirmed to contain the Flutter keyboard/sticker assets.

## Release blocker

The sandbox does not have the Flutter SDK or Dart SDK, and the repository does not include a Gradle wrapper. Therefore, a new APK/AAB was not produced in this environment. Before Play Store release, run `flutter pub get`, `dart format`, `flutter analyze`, `flutter test`, and `flutter build appbundle --release` on a Flutter 3.35+/Dart 3.9+ environment, then test the IME on Android 13+ and an older supported Android version in WhatsApp, Telegram, browser fields, microphone permission flows, translation, all language layouts, clipboard, resize, and editor actions.

## Changed repository

The working tree contains the requested refactor and is ready for Flutter-based validation and commit.
