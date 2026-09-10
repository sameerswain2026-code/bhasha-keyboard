# Bhasha Keyboard — Branch and Production Audit

**Date:** 10 September 2026  
**Repository:** `sameerswain2026-code/bhasha-keyboard`  
**Consolidated branch:** `feat/secure-cloud-linked-documents`  
**Final validated commit:** `e11bedbcf4f0de9cfe2c8ce4083fd35d2e0748af`

## Executive summary

All currently visible local and remote branches were inventoried and compared against `origin/main`. The repository does not require a wholesale rewrite or a blind merge of every branch. The historical research and backup branches are already ancestors of the current mainline, while both arena branches have already been merged into main. The safe production path was therefore to preserve the secure document/gateway branch, fast-forward it with the current mainline dashboard/theme integration, retain the previously validated IME feedback and document-picker fixes, and publish the resulting consolidated candidate.

The consolidated branch passed Flutter analysis, the complete Flutter test suite, backend gateway tests, JavaScript syntax checks, and the signed Android production workflow. The signed workflow built and verified both the ARM64 release APK and the production AAB.

## Branch inventory and decision

| Branch | Current tip / relation | Findings | Production decision |
|---|---|---|---|
| `origin/main` | `f1a5722` | Current integration branch. Includes the arena dashboard/theme work and duplicate `_StatusChip` compile fix. | Used as the current mainline base. |
| `origin/feat/secure-cloud-linked-documents` | `a46e153` before consolidation | Contains secure Appwrite AI/Drive gateway work, gateway tests, and release hardening. | Preserved; consolidated with current mainline and IME fixes. |
| `origin/arena/01a088fc-bhasha-keyboard` | `05c27af` | Gateway hardening and release checks. Already an ancestor of `origin/main`. | No separate merge required. |
| `origin/arena/01a0894d-bhasha-keyboard` | `2e90343` | Dashboard/themes/cloud controls plus the `_StatusChip` compile correction. Already merged into `origin/main`. | No separate merge required. |
| `origin/copilot/deep-research-global-problems` | `7708916` | Historical research branch; it is already an ancestor of current main and adds no commits beyond main. | Retain for history; do not merge again. |
| `backup/pre-documents-merge` | `2e46f5b` | Historical backup branch; it is already an ancestor of current main. | Retain as backup; do not merge again. |

## Changes consolidated

The production candidate retains the existing architecture and combines the following validated work:

- Secure Appwrite gateway boundary for AI and Drive-related operations, with request validation, allowlists, response limits, encrypted refresh-token handling, and gateway tests.
- Branded dashboard, theme catalog, document workspace, and existing onboarding/application flow.
- 22-language native inventory and Roman input paths.
- IME keyboard responsiveness fix for narrow and one-handed layouts.
- Sound feedback routed through the Android IME `AudioManager` key-click effect, with Flutter fallback.
- Haptic throttling corrected so sound is not skipped when a haptic pulse is rate-limited.
- Document picker bridge from the IME service to the companion Activity, allowing the Android picker to open without depending on an in-panel text field.
- Accessible theme-control test updated to use the production tooltip/semantics contract.

## Validation evidence

The following checks passed on the final candidate:

| Check | Result |
|---|---|
| `flutter analyze` | Passed |
| `flutter test` | Passed; 183 tests completed successfully |
| `npm ci` in `functions/` | Passed; 0 vulnerabilities reported by npm audit |
| `npm test` in `functions/` | Passed; 9 gateway security tests |
| `npm run check` in `functions/` | Passed for both gateway entrypoints |
| `git diff --check` | Passed |
| Signed production workflow `34439523666` | Passed |
| Signed ARM64 APK build and signature verification | Passed in workflow |
| Signed production AAB build and verification | Passed in workflow |

The workflow also validated the backend gateways before building the Android artifacts. GitHub Actions emitted only action-runtime deprecation warnings for Node.js 20-targeting actions and `setup-java@v4`; these are maintenance warnings, not build failures.

## Remaining release gates

A successful build does not by itself complete public Play Store release. The following external gates remain environment-dependent and must be completed before claiming full cloud-connected production readiness:

1. Deploy the Appwrite Functions from `functions/` and configure their production secrets in Appwrite, not in the APK.
2. Verify Appwrite collection row security and non-owner access denial with two real accounts.
3. Complete Google OAuth provider configuration, signing-certificate verification, and a real test-account login.
4. Test the IME on physical Android devices across at least one recent Android version and one OEM variant, including keyboard enable/select, haptics, sound, microphone permission, document picker, file sharing, and back navigation.
5. Verify Google Drive `drive.file` behavior and revocation after sign-out.
6. Complete Play Console data-safety, privacy-policy, account-deletion, content-rating, app-access, and closed-testing requirements.

The branch is therefore a **validated release candidate**. It should not be marketed as a fully cloud-connected production service until the external Appwrite, OAuth, Drive, device-QA, and Play Console gates above are completed.

## Reproduction commands

```bash
cd bhasha-keyboard
export PATH=/home/ubuntu/tools/flutter/bin:$PATH
flutter analyze
flutter test
(cd functions && npm ci && npm test && npm run check)
```

For the signed build, use the repository's `production-build.yml` workflow with the required signing secrets configured in GitHub Actions.

## Final branch state

The consolidated branch is `feat/secure-cloud-linked-documents` at commit `e11bedb`. Historical branches were not deleted or rewritten. They remain available for traceability, while the consolidated branch is the recommended release-candidate source until a final release branch/tag is created after external release gates pass.

> Important: real-device IME behavior, Appwrite deployment, OAuth/Drive configuration, and Play Console review are external gates. CI can validate the build and code paths but cannot replace those tests.
/home/ubuntu/bhasha-keyboard/docs/branch-production-audit-2026-09-10.md
</content>We need not read. Need commit report push. Then download artifacts. Use parallel? mutating order maybe commit then download independent but can batch? Since push required before final perhaps do commit push and download separate maybe parallel read-only? artifact download external. Do commit push first. Then download. Use exec. 彩神争霸网站? We can use exec.os. Need not attach source? User asked app production, link APK AAB useful. Also report link. Let's commit. Then download using gh api artifact name. Ensure no malformed command. Use a clean session. Upshot final answer in Hindi concise but detailed. Need maybe mark todo complete after artifact. Let's commit/push. Then artifact download. Use functions.exec. (No issue)..executor to=functions.exec code ㊉”】【commentary 代 񟿿 〔tool〕 需要 brevity 1 sentence: 
