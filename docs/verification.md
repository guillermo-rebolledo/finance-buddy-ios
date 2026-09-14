# Verification

Recorded on September 13, 2026 using Xcode 26.6, Swift 6 strict concurrency, and iOS 26.5 simulators. Minimum deployment target: iOS 17. App version: 1.0, build 12.

## Confirmed

- Debug builds and installs on the iPhone 17 Pro simulator without compiler warnings.
- Release builds for the generic iOS Simulator destination without compiler warnings; the 39 core tests were rerun successfully when preparing the PR.
- The owner completed Google Sign-In against the local backend. The app restored the Keychain session after reinstalling an updated build and displayed the owner's journal.
- The local backend rejected build 1 with the update screen when its minimum was 12. Updating the app to build 12 restored access without lowering the backend's minimum.
- The 39 Swift Testing tests passed on macOS and in the iOS simulator during implementation. They cover decimal money, calendar dates, refusals, request headers, token replacement, retry identities, and store consistency.
- The latest targeted UI run passed all four tests: entry add/edit/delete and period navigation; category creation/menu archive/sign-out; category swipe rename/archive; and toast validation, dismissal, repeated errors, and automatic success dismissal.
- Toast screenshots were inspected in dark mode, including an error above the keyboard and a success above the tab bar. Status messages do not become list rows.
- Earlier UI runs passed the tab shell and largest Dynamic Type screen traversal.
- Debug uses localhost with a localhost-only ATS exception. Release uses the stable HTTPS production origin without that exception.

Automated UI tests use the in-memory fake. Their entries and categories do not alter the owner's journal. Local OAuth configuration, build products, test reports, and screenshots are excluded from Git.

## Remaining before completion

- `testAccessibilityAndDashboardTables` has a known text-clipping audit failure for the period picker's “Jump to date” label. The chart table interaction passes, but the full suite is not yet green.
- Complete the backend's `docs/verification.md` iPhone checklist against a deployment, including physical-device behavior, owner/non-owner sign-in, session revocation, exports, and refusal recovery.
- Compare figures with the website for matching periods, and complete live entry/category mutation and PDF/Sheets checks. Simulator fixture tests do not establish live parity.
- Finish the full accessibility review, including VoiceOver, Audio Graphs, and all screens at accessibility sizes; test minimum-supported iOS 17 behavior.

The backend source and web app are unchanged. Its verification checklist remains the authoritative deployment checklist.
