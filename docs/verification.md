# Verification

Recorded on September 13, 2026 using Xcode 26.6, Swift 6 strict concurrency, and iOS 26.5 / iOS 17.5 simulators. Minimum deployment target: iOS 17. App version: 1.0, build 12.

## Confirmed

- Debug builds and installs on the iPhone 17 Pro simulator without compiler warnings.
- Release builds for the generic iOS Simulator destination without compiler warnings; the 39 core tests were rerun successfully when preparing the PR.
- The owner completed Google Sign-In against the local backend. The app restored the Keychain session after reinstalling an updated build and displayed the owner's journal.
- The local backend rejected build 1 with the update screen when its minimum was 12. Updating the app to build 12 restored access without lowering the backend's minimum.
- The 39 Swift Testing tests passed on macOS and in the iOS simulator during implementation. They cover decimal money, calendar dates, refusals, request headers, token replacement, retry identities, and store consistency.
- The complete iOS 26.5 suite now passes: 39 core tests, three Audio Graph descriptor tests, and all 10 UI tests. These include the original period Dynamic Type/clipping audit, entry/category regression flows, toast behavior, and the expanded light/AX5 accessibility flows. Debug and Release builds have no compiler warnings.
- Toast screenshots were inspected in dark mode, including an error above the keyboard and a success above the tab bar. Status messages do not become list rows.
- Debug uses localhost with a localhost-only ATS exception. Release uses the stable HTTPS production origin without that exception.
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

- Complete the backend's `docs/verification.md` iPhone checklist against a deployment, including physical-device behavior, owner/non-owner sign-in, session revocation, exports, and refusal recovery.
- Complete live PDF/Sheets checks. The owner has confirmed entry/category mutation and figure parity separately; simulator fixture tests do not establish export behavior.
- Physical VoiceOver navigation and audible Audio Graph playback remain pending at the owner's request. Simulator audits and descriptor tests are not a substitute for listening to and navigating the app on a device.

The backend source and web app are unchanged. Its verification checklist remains the authoritative deployment checklist.
