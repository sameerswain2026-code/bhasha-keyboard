# Bhasha Keyboard — P0 Gate Evidence

**Date:** 9 September 2026  
**Branch:** `feat/secure-cloud-linked-documents`  
**Release commit:** `86de4cd57b11267a4357a9e3b9907309fa0c0e08`

## Verified in the repository/session

| Gate | Result | Evidence |
|---|---|---|
| Correct source branch | Pass | `feat/secure-cloud-linked-documents` tracks `origin/feat/secure-cloud-linked-documents` |
| Flutter formatting and analysis | Pass | GitHub Actions production run `34341745565` |
| Flutter tests | Pass | GitHub Actions production run `34341745565`; all tests passed |
| Signed ARM64 APK | Pass | Artifact from run `34341745565`; SHA-256 `b802e6f68b4d0858f12f2d84f793ca5f11358445e60e29ee5b7d250335b57dc8` |
| Signed production AAB | Pass | Artifact from run `34341745565`; SHA-256 `353fad0248d2258e05909ec9ad4bafbf5db0f14f3ddfcd2120a258b08e54810e` |
| Anonymous Function execution blocked | Pass | Direct unauthenticated POST probes to both deployed Function execution endpoints returned HTTP `401` |
| Function source boundary | Pass at source level | Both Functions require `x-appwrite-user-jwt`; provider and OAuth secrets are read from server-side environment variables |

## Function probe details

The following public Function IDs were probed without credentials:

- `drive-gateway`: `6aa12c14001ddeb260df`
- `ai-gateway`: `6aa13043002cddfbdc72`

Both Appwrite execution endpoints returned `HTTP 401`. This proves that an unauthenticated request cannot execute either Function. It does **not** prove that authenticated execution, provider configuration, or Appwrite table permissions are correct.

## Still blocked on external evidence

The following gates cannot be truthfully marked complete from this sandbox because they require a real logged-in Appwrite/Google account, Android hardware, or Play Console access:

1. Authenticated execution of both Functions with a real user session.
2. Google OAuth success, cancellation, relaunch, expiry and revoke behavior.
3. Non-owner account isolation for `document-links` and `google-drive-tokens`.
4. Drive token expiry, revoke, deleted-file, quota and network-failure behavior.
5. Physical Android QA for IME selection, third-party editor behavior, haptics, media insertion, voice lifecycle, biometrics/PIN, RTL/native scripts and lockout.
6. Google Play Internal Testing upload and pre-launch report.

## Release artifacts

The successful production workflow is [GitHub Actions run 34341745565](https://github.com/sameerswain2026-code/bhasha-keyboard/actions/runs/34341745565). The signed AAB from this run is the candidate for Play Internal Testing. Public release should wait until the external gates above have evidence.

## Required user-side next actions

Install the signed APK on one Android 13-or-newer device and one older supported device. Complete `docs/device-qa-template.md`, including screenshots or recordings for OAuth, documents, haptics, media and lockout. Then upload the exact signed AAB from run `34341745565` to Play Console Internal Testing and retain the Play pre-launch report.

Never paste OAuth client secrets, refresh tokens, provider keys or Appwrite API keys into chat, issues, screenshots or repository files.
