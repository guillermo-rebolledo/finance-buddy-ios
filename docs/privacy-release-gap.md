# Privacy reconciliation — September 15, 2026

The source, policy and declaration inventory have been reconciled. App Store Connect publication status is recorded in [release-status.md](release-status.md).

## What changed

- Google's integrated Sign-In 10.0.0 manifest declares more data and analytics purposes than the original four-row app inventory. The release label includes every vendor-declared type/purpose. The exact integration uses the standard SDK sign-in with no additional scopes or documented collection override; we have no evidence that its broader declarations can be excluded. This does not assert that every user supplies every optional profile field.
- The backend additionally retains Google profile-picture references (`better-auth` Google provider → `user.image`), financial-movement notes and category names, and session IP/user-agent fields. These now appear in the app's manifest and label as Photos or Videos, Other User Content, and Other Data Types. Hosting request/error diagnostics are covered as Other Diagnostic Data for App Functionality. All are linked to identity; none is used for tracking.
- The public policy distinguishes Google SDK analytics from Finance Buddy's own processing and explains session details, provider grants, operational logs/backups, exported-file retention and provider-account independence. It accurately distinguishes required Apple revocation from best-effort Google revocation.
- Build 15 adds four app manifest declarations without changing runtime code. Its 11 app/SDK manifests aggregate to 12 collected data types. SDK resources and required-reason declarations were preserved.

## Evidence

- Backend base matched the live deployment: `fe1c0df3450fde22804371bcae5e570a5a25582e`, including deletion #60 and policy/support #61.
- Policy source commit `2d1e53b9988745c4cedea78828ae08f4d256f1df`; [backend PR #67](https://github.com/guillermo-rebolledo/finance-buddy/pull/67).
- Initial deployed policy and native Apple-secret configuration: `dpl_CNJ4Zr8VQuhAGbcxaHhw3rRYoizi` on `https://financebuddy.tech`. Signed-out privacy/support pages return HTTP 200; updated SDK section confirmed present.
- `migrations/0001_auth.sql`, `src/lib/auth.ts`, `src/lib/account-deletion.ts`, and Better Auth 1.7.4's `createSession`/Google provider implementation substantiate storage and deletion behavior. No product-analytics dependency or initialization was found in either app.
- `artifacts/release-1.0-15/privacy-manifests.json` contains all archived manifests; `privacy-summary.json` aggregates types, purposes, linkage, tracking and source paths. This is a local manifest inventory, not an Xcode Organizer-generated report or a packet-level audit.

Final source integration: PR #67 merged as `5177bce` after both full CI suites passed (248 tests, 48 skipped). Main is deployed as `dpl_Ao8pXdgqTpxtrCS9xKXogZoZWPU1`; final public-page checks passed.

## Ongoing requirements

Revisit disclosures when SDK versions, scopes, backend storage, hosting logs or analytics change. Keep the live policy and App Store answers synchronized. Account deletion and provider revocation still require the owner's physical-device checks; a successful deployment alone does not establish those behaviors.

Sources: [Google versioned manifest](https://github.com/google/GoogleSignIn-iOS/blob/10.0.0/GoogleSignIn/Sources/Resources/PrivacyInfo.xcprivacy), [Google disclosure guidance](https://developers.google.com/identity/sign-in/ios/app-privacy), [Apple privacy definitions, including free-form content and retained IP data](https://developer.apple.com/app-store/app-privacy-details/), [Vercel runtime logs](https://vercel.com/docs/logs/runtime), [Google privacy policy](https://policies.google.com/privacy).
