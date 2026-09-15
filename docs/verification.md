# Verification

## Release-gap follow-up — September 15, 2026

- Published the 12-type App Privacy label after reconciling app, backend and GoogleSignIn 10.0.0 declarations. App Store Connect confirmed “Published … by Guillermo Ortiz Rebolledo.” Added app-owned declarations for profile images, journal free text, stored session details and operational diagnostics.
- Version **1.0 (15)** changes only the privacy manifest and build number from 14. Release archive, build/version/configuration checks and signature verification passed; no archive warnings. Upload succeeded and processing completed. Selected 15 on the draft App Store version and added it to internal group **Release Testing**, with automatic distribution disabled. Existing 14 UI results remain the code-behavior evidence; a physical-device result for 15 is still pending.
- Corrected the public backend policy, including the distinction between Google SDK analytics and own processing, session data, logs/backups and actual provider revocation behavior. TypeScript and page ESLint passed; Vercel production build passed; public privacy/support return 200 and the corrected SDK section is present.
- Original deployment `fe1c0df` includes backend #60/#61. New policy commit `2d1e53b` is deployed as `dpl_CNJ4Zr8VQuhAGbcxaHhw3rRYoizi`, with source preserved in backend PR #67. Production has no configured minimum iOS build. An unauthenticated build-15 session request returns 200/null.
- Generated and configured the separate native Apple secret as Sensitive Production data, verified its signature/claims locally, and redeployed. Expiry: March 14, 2027, 18:57:24 UTC. No private key or JWT was printed or committed. Actual native authorization-code exchange/revocation is still an owner phone check.
- Saved content-rights answer, reviewer contact and review instructions. Free Apps Agreement and DSA status are Active; paid-app tax/banking notices were left unchanged. Review credentials are now saved in both App Store Connect forms; physical-phone test results remain outstanding.
- Submitted **1.0 (15)** to **Beta App Review** for Mexico Launch Testers on September 15, 2026. Confirmed **Waiting for Review**, one build and one tester (`gortiz.dev@gmail.com`). Automatic tester notification is enabled; the tester still shows **No Builds Available** while awaiting approval. No invitation was sent to the different Account Holder address.
- Verified the spare review account in a fresh private browser session using its password, without Touch ID, SMS or another verification prompt. Six fictional transactions, a repeating monthly MXN 16,000 budget and Learning category are saved. Sheets is connected with owner approval. September PDF and Sheets exports match the six entries and totals: income MXN 25,800.00, expenses after refunds MXN 8,535.25, net MXN 17,264.75. This is browser evidence, not a physical iPhone result.

- Google OAuth was still Testing with one allowed user. Saved public branding links, declared the existing identity and drive.file scopes (all non-sensitive), and switched to In production. Google reports no sensitive/restricted-scope verification requirement.
- Backend CI initially failed three expiry tests because their fixed real-clock offset did not account for prior simulated sign-in time. Corrected tests to advance eight days from the returned session creation time. All 39 applicable auth/native/public-page tests pass locally; both full CI reruns passed: 248 passed, 48 skipped. PR #67 was merged as `5177bce`; production deployment `dpl_Ao8pXdgqTpxtrCS9xKXogZoZWPU1` is Ready on main. Final requests using the actual `X-Finance-Buddy-Build: 15` header returned session 200/null and private endpoint 401/unauthenticated. Production auth code is unchanged.

Artifacts: `artifacts/release-1.0-15/` contains archive/upload logs, build settings, full manifest inventory and aggregate privacy summary. No public App Review submission or release occurred.

## Release preparation — September 15, 2026

See [release-status.md](release-status.md) for the live App Store record, completed settings, upload evidence and remaining blockers. This section supersedes the older “no build uploaded” status below; historical verification is retained.

- Created **Finance Buddy: Journal**, Apple ID **6812466832**. Saved listing copy, subtitle, Finance category, support/privacy URLs, MXN 0.00 pricing, Mexico-only availability, iPhone-only distribution and manual release. Completed the current age-rating questionnaire: **4+**.
- **1.0 (13)** archived and uploaded successfully. The baseline simulator suite completed with **85/86 tests passing**; the AX5 additional-screen audit identified an actual clipped amount (`1,250…`) in the entry editor. The macOS Core run passed **63 tests**.
- Fixed the amount field's layout and VoiceOver labeling; **1.0 (14)** archived with no build warnings, passed Release checks and code-signature verification, and uploaded successfully. All **four focused UI tests** passed: additional AX5 screens, largest-text app flow, light app flow, and entry creation/editing/deletion with period navigation. Inspected the AX5 result image showing the full `1,250.00` value.
- Verified the Release checker rejects invalid origin, ATS exceptions, bundle ID, version and build. Release no longer includes local Debug overrides.
- Captured six standard-size, light-mode screenshots from the fake-backed build 14 on iPhone 17 Pro Max / iOS 26.5, exported as opaque 1320 × 2868 JPEGs. Confirmed all six screenshots persist in App Store Connect after reloading, in Dashboard / Entries / Entry editor / Budgets / Categories / Export order. The 6.5-inch section inherits this set.
- Inspected the final archive's app/SDK privacy manifests. Google Sign-In adds declarations omitted from the previous privacy table, including analytics purposes. Corrected the submission guidance and prepared a policy amendment; the public policy has not been updated and App Privacy answers remain unpublished.
- Public Privacy and Support pages returned 200 signed out. Production's session endpoint returned 200/null for an unauthenticated build-13 request. Real sign-in, exports, provider revocation, account isolation, physical-device accessibility and the exact production minimum build remain unverified for build 14.
- No public App Review submission or release was performed. App Store Connect confirms uploads 13 and 14 are Complete, and build 14 is Ready to Submit in TestFlight. Tester setup, review credentials/contact and remaining account declarations are pending; no installs are recorded.

Artifacts: `artifacts/release-1.0-13/` (baseline and first upload) and `artifacts/release-1.0-14/` (corrected archive, upload log, focused `.xcresult`, screenshots and guard-check results). The original full test tool timed out while xcodebuild continued; the result was read from its completed `.xcresult`.

Recorded on September 13, 2026 using Xcode 26.6, Swift 6 strict concurrency, and iOS 26.5 / iOS 17.5 simulators. Minimum deployment target: iOS 17. App version: 1.0, build 12.

## Physical-device connection fix — September 14, 2026

- The physical-device Debug app embedded `http://localhost:3000`, pointing session restoration at the phone itself instead of the Mac backend. Debug now defaults to the production HTTPS origin, with localhost selected only for the simulator SDK. Optional SDK-specific development origins are documented in `Config/Local.xcconfig.example`.
- A signed Debug build for the connected iPhone 16 Pro Max succeeded and was installed. Its built Info.plist contains `https://financebuddy.tech`; an unauthenticated request from the Mac to that origin's session endpoint with build 12 returned HTTP 200 and `null`. Resolved Debug simulator settings still contain `http://localhost:3000`.
- Live on-phone sign-in and journal loading remain to be confirmed. The build reported an interface-orientation warning unrelated to this configuration change.

## Budgets (backend spec #46)

- Matched the additive contract on the backend's `main`: `GET /api/budgets?before=`, `PUT` and `DELETE /api/budgets?kind=&date=`, the `budget` view inside `GET /api/journal`, the optional `budget` in entry save replies, and the `period_ended` refusal code. Periods are always named by kind and date; the app never computes a period start.
- New core tests cover decoding a summary with, without, and with a null `budget`; the shared wording for left, over, under, left per day, and period labels; editor prefill from the resolved period, zero-allowed validation, ended periods, saving exactly the resolved period, promoting a one-off to repeating; list paging through Past with the cursor; stopping a span; and the entry reply carrying the shortest budgeted period. Client tests check the query parameters and JSON bodies of every budget request and that an unreadable `budget` in a confirmed save reply does not turn the save into an unconfirmed one.
- The in-memory fake keeps budget spans the way the server does (one-off precedence, closing a span at the period before a change, scheduled changes, stop from a period). Its Past listing walks a bounded window back rather than paging real history.
- Simulator run on iPhone 17e (iOS 26.5): all 51 Swift Testing core tests pass (eight of them new), the five view tests pass, and all 11 UI tests pass, including the new Budgets flow (set a monthly budget from Now, see the left figure update, stop the repeating budget through its confirmation, and see the dashboard card) and the entry toast that now reads "Entry saved. MXN 427.50 left this week." The largest-text and light accessibility audits include the Budgets tab and the budget form. Debug build has no compiler warnings.
- Not verified: live budgets against a deployed backend from the app. The fake models the contract, so the owner should set, change, stop, and remove a budget on the phone against production and compare with the web.

## Sign in with Apple integration

- Matched the native contract from backend PR #45: `provider: "apple"`, SHA-256 nonce in the Apple request, original nonce alongside the identity token in the backend request, and signed response-header storage only.
- All 41 core tests pass on macOS and iOS 26.5. The sign-in transport tests now exercise both providers; additional session tests cover provider forwarding, session restoration, and Apple refusal recovery.
- All five iOS view/integration tests pass, including the known SHA-256 vector and Apple cancellation, fresh-nonce retry, and failure presentation.
- Debug and Release simulator builds pass without compiler warnings. Both generated simulator entitlement files contain `com.apple.developer.applesignin = [Default]`.
- The full iOS 26.5 suite passes: 41 core tests, five view/integration tests, and 10 UI tests. Light and largest-text accessibility flows verify the sign-in screen, and both Apple and Google buttons are present after sign-out.
- After the final Apple button style adjustment, the light and largest-text dark screen audits were rerun successfully, and Release was rebuilt successfully. The system's outlined white button remains visible in either appearance.
- Live Apple authorization remains unverified. Complete the [README setup](../README.md#sign-in-with-apple), then test on a signed physical device: Share My Email continuity with the existing Google journal, Hide My Email isolation, cancellation/retry, relaunch restoration, and session revocation. Automated tests do not validate Apple Developer registration, provisioning, or deployed provider credentials.

## Confirmed

- Debug builds and installs on the iPhone 17 Pro simulator without compiler warnings.
- Release builds for the generic iOS Simulator destination without compiler warnings; the 39 core tests were rerun successfully when preparing the PR.
- The owner completed Google Sign-In against the local backend. The app restored the Keychain session after reinstalling an updated build and displayed the owner's journal.
- The local backend rejected build 1 with the update screen when its minimum was 12. Updating the app to build 12 restored access without lowering the backend's minimum.
- The 39 Swift Testing tests passed on macOS and in the iOS simulator during implementation. They cover decimal money, calendar dates, refusals, request headers, token replacement, retry identities, and store consistency.
- The complete iOS 26.5 suite now passes: 39 core tests, three Audio Graph descriptor tests, and all 10 UI tests. These include the original period Dynamic Type/clipping audit, entry/category regression flows, toast behavior, and the expanded light/AX5 accessibility flows. Debug and Release builds have no compiler warnings.
- Toast screenshots were inspected in dark mode, including an error above the keyboard and a success above the tab bar. Status messages do not become list rows.
- Debug uses localhost on simulators and the production HTTPS origin on physical devices, with a localhost-only ATS exception. Release uses the stable HTTPS production origin without that exception.
- The owner confirmed live app/web parity on September 13, 2026: entry/category changes and matching day, week, and month figures (user-reported verification).

Automated UI tests use the in-memory fake. Their entries and categories do not alter the owner's journal. Local OAuth configuration, build products, test reports, and screenshots are excluded from Git.

## Accessibility and iOS 17 follow-up

- Fixed the period jump label and category add controls so their text can wrap and their tappable areas remain at least 44 points high.
- Sign-in content now grows and scrolls at the largest accessibility size. Category editor titles and placeholder copy fit, and the entry Type picker uses a menu at accessibility sizes.
- Removed the fixed normal-font override from the fixture modifier so the app can respond to Dynamic Type changes during audits.
- Audio Graph descriptors now refresh their axes, series, summary, and direction when the loaded figures change. Three regression tests verify fresh data, exact monetary labels, negative values, both spending spans, and empty graphs.
- The broader UI audits cover text clipping, element descriptions, and tap areas in light mode and at AX5 in dark mode. They exercise entries, categories, settings, sign-in, entry/category editors, deletion, export refusal, unavailable, and upgrade screens, including scrolling. The original period/chart test retains its Dynamic Type audit and chart-table interaction.
- Captured screenshots were inspected for readable wrapping and scrolling. The app uses system controls and semantic colors; income amounts now use the primary text color for legibility. Reduce Motion disables the custom toast movement animation, and VoiceOver keeps toast messages available until dismissed.
- iOS 17.5 on an iPhone 15 simulator passed 39 core tests, three Audio Graph tests, and six UI flows: launch, entry CRUD/period navigation, category lifecycle/sign-out, category swipes, toast behavior, and largest-text tab traversal. The final category-button adjustment was then rebuilt and its lifecycle/swipe tests rerun successfully on iOS 17.5. This is runtime verification on iOS 17.5, not a claim that every iOS 17 patch release was tested.

The broad exploratory contrast/font audit reported system-control findings on both simulator versions. It is not claimed as a passing contrast certification; the committed broader flow tests cover clipping, descriptions, and tap targets, while font scaling is covered by the original audit and the largest-size fixtures. Audible VoiceOver and Audio Graph verification requires a physical device ([Apple testing guidance](https://developer.apple.com/documentation/accessibility/performing-accessibility-testing-for-your-app)).

## Remaining before completion

All remaining deployment, live PDF/Sheets, physical VoiceOver and audible Audio Graph checks are consolidated in the [TestFlight production checklist](app-store-submission.md#testflight-production-checklist). The backend's verification checklist remains authoritative for the deployment. Prior owner confirmations above do not establish that a new TestFlight build has passed.

## App Store readiness (#7)

### Automated verification

Recorded September 14, 2026 for version 1.0, build 12, with Xcode 26.6 and the iPhone 17e / iOS 26.5 simulator. This is local verification, not a TestFlight result.

- Release builds without `Config/Local.xcconfig`. The built app is iPhone only, contains the public Google identifiers and URL scheme, declares no non-exempt encryption, and includes the app privacy manifest. Project regeneration preserves the signing team and device family. The Release build after integrating the latest main has no compiler or orientation warnings.
- The Release assertion passes on the built bundle. Mutating device family, either Google client ID, reversed client ID, encryption declaration or manifest presence makes it fail with the corresponding setting named. Manifest data types, purposes, linkage and tracking match the submission kit.
- All 61 Swift Testing core tests and nine view/integration tests pass on iOS 26.5; core tests also pass on macOS. Tests cover deletion requests, token removal/retention, refusals, transport failure, the busy guard, journal reset, Apple code forwarding, no requested scopes, cancellation and failed authorization/revocation.
- All 14 UI/accessibility tests pass across the full run and focused reruns. The full run passed 13; the browser test was corrected for Safari’s iOS 26 “Close” label (with “Done” support for earlier versions) and passed on rerun. After screenshot inspection, the largest-text override was passed explicitly into the deletion sheet; both light and AX5 accessibility flows passed again, and the AX5 screenshots confirm readable wrapping and reachable buttons after scrolling. The final Release build also passes without warnings.
- Public `/privacy` and `/support` returned HTTP 200 without authentication on September 14, 2026. This does not prove provider revocation or production deletion works on a device.

### Production verification and submission — pending (#13)

Follow the [submission kit](app-store-submission.md#testflight-production-checklist). Issue #13 remains open until the owner completes its physical-device and account-side steps. No build was uploaded or submitted during this implementation, no real account was deleted, and no demo credentials were created or committed.

| Field | Result |
| --- | --- |
| TestFlight test date / tester | Pending |
| Uploaded version / build | Pending (local source is 1.0 / 12; increment before upload) |
| Physical iPhone / iOS version | Pending |
| Production deployment / minimum iOS build | Pending |
| Backend deletion #60 deployment and live revocation | Pending |
| Google / Apple Share My Email / Hide My Email | Pending |
| Session restore / Sign Out / Sign Out Everywhere | Pending |
| Financial movements / categories / budgets / web parity | Pending |
| PDF / Sheets / refusal recovery | Pending |
| Google-only / Apple-linked / shared-journal deletion | Pending |
| Fresh journal / starter categories / unrelated-account isolation | Pending |
| Web deletion invalidates iPhone / old exports retained | Pending |
| Privacy / Support links on physical device | Pending |
| VoiceOver / Audio Graph / largest text | Pending |
| Demo login and populated review journal | Pending |
| App Store Connect metadata / screenshots / privacy / age rating | Pending |
| Pricing / availability / EU trader status | Pending |
| Submission date / review build / review outcome | Not submitted |

For each completed checklist item record pass/fail, date, build and evidence here. Put credentials only in App Store Connect. Track rejection feedback as new issues rather than marking untested behavior passed.

## Wallet icon build 16 — September 15, 2026

- Original supplied artwork retained in `docs/branding`; generated icon is 1024 × 1024, sRGB and opaque. Regeneration produces identical bytes. Inspected the small device icon extracted from the signed archive; the compiled catalog also contains the 1024 × 1024 marketing icon.
- Core suite: 63 tests in 11 suites passed (`artifacts/icon-update/core-tests.log`). Entry create/edit/delete/period navigation passed on iPhone 17 Pro Max / iOS 26.5 (`artifacts/release-1.0-16/FocusedTests.xcresult`).
- The broader Pro Max accessibility run found Settings website text clipping and a Categories hit-region warning. Fixed Settings by using an explicit title-and-icon layout with vertically wrapping text; the focused standard/largest-text regression passes (`SettingsLabelTests.xcresult`). The first wrapping-only attempt did not resolve it; retained both failed runs as evidence.
- **Remaining before public release:** investigate the Categories hit-region warning on Pro Max and complete the existing physical-device checklist. The full accessibility suite is not claimed green for build 16. This does not prevent distributing the build through TestFlight for testing.
