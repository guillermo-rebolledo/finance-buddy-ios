# Verification

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
