# Finance Buddy for iPhone

A native client for the existing Finance Buddy journal. Swift 6, SwiftUI, Observation, iOS 17+, and the same HTTP API as the website. The production origin is `https://finance-buddy-self.vercel.app`.

## Open and run

Open `FinanceBuddy.xcodeproj`, select the **FinanceBuddy** scheme and an iPhone simulator, then Run. The checked-in Xcode project is ready to open; XcodeGen is only needed when changing the project structure (`brew install xcodegen`, then `xcodegen generate`). GoogleSignIn-iOS **10.0.0** is exact-pinned through SPM, with its resolved transitive dependencies committed.

Debug uses `http://localhost:3000`. Start the backend in its own checkout with `pnpm dev:local`. Release uses the production HTTPS origin. Only the Debug Info.plist grants an ATS exception, scoped to localhost.

Copy `Config/Local.xcconfig.example` to `Config/Local.xcconfig` and fill in the **public** iOS client ID, web/server client ID, and reversed iOS client ID. Local.xcconfig is ignored. The bundle ID registered with the Google iOS OAuth client must be **com.guillermorebolledo.FinanceBuddy**. Set the same iOS client ID as `GOOGLE_IOS_CLIENT_ID` in the backend's private configuration. No Google client secret belongs in this app.

The SDK's nonce overload was checked in its installed public header and compiled as:

```swift
try await GIDSignIn.sharedInstance.signIn(
  withPresenting: controller,
  hint: nil,
  additionalScopes: nil,
  nonce: nonce
)
```

`GIDConfiguration` supplies `serverClientID` using the web client ID. The app sends the Google ID token with the same fresh nonce to the backend. Only `set-auth-token` is saved to Keychain; the response body's unsigned token is never used. Run a normally signed simulator build: disabling code signing can prevent Keychain access.

For a physical development device, select your Apple development team in Xcode. Debug's localhost is the device itself; use a reachable HTTPS development origin for device testing. Release already embeds the stable production origin. App Store distribution is outside this project’s scope.

## Architecture

- **Core / Networking:** `APIClient` is the protocol boundary. `LiveAPIClient` owns HTTP, headers, decoding, refusal mapping, token replacement, and the global upgrade gate. Its ephemeral session has no cookie storage or URL cache and does not follow redirects. Keychain uses `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
- **Core / Stores:** Main-actor `@Observable` feature stores own state and call the protocol. Period request sequencing prevents stale replies. The Dashboard commits summary and trends together after checking their period identity. A failed refresh preserves the loaded snapshot.
- **FinanceBuddy:** SwiftUI views render the stores. Google Sign-In, network reachability, Quick Look, Safari, and chart accessibility are thin Apple/Google integrations.
- **Core / Fixtures:** The in-memory client is injected into previews and tests. `-useFakeAPI` is enabled in Debug only and never changes the backend or bypasses a real session.

Money is decoded from strings directly into `Decimal`. `Double` is used only when projecting already-decoded values into chart coordinates and Audio Graphs; arithmetic and visible monetary labels remain decimal. `CalendarDate` keeps Mexico City dates as year/month/day. Its UTC `Date` bridge is only for system controls and single-day stepping. Live code never calculates summary period boundaries.

New entries, category creations, and Sheets exports keep their request identities across uncertain outcomes. Pending forms cannot be edited. A definitive 400 permits correcting the form with a fresh creation ID; Sheets creates a fresh export after success, `export_unconfirmed`, or `export_period_mismatch`. Export requests always capture the loaded period.

## Tests and previews

Run all unit, client, and UI tests with **Product → Test** in Xcode. Swift Testing covers values, refusals, HTTP integrity, token rotation, offline behavior, request identities, and store sequencing. Three additional Swift Testing cases verify Audio Graph descriptors. XCTest covers UI flows and accessibility. The core tests can also run quickly on macOS:

```sh
swift test --package-path Core
```

Run the entire simulator suite from the command line:

```sh
xcodebuild -project FinanceBuddy.xcodeproj -scheme FinanceBuddy \
  -destination 'platform=iOS Simulator,name=iPhone 17e' \
  -parallel-testing-enabled NO test
```

Use `-useFakeAPI` in a Debug scheme’s launch arguments to explore without signing in. Optional fixture-only arguments `-light`, `-dark`, and `-largestType` support visual verification. The live client ignores them. For fixture-only screen inspection, add `-previewScreen` followed by `editor`, `categoryEditor`, `deletion`, `export`, `signIn`, `unavailable`, or `upgrade`; this route is available only with `-useFakeAPI` in Debug. `ScreenPreviews.swift` provides light, dark, and largest-size previews for every app screen, plus empty-day and failed-load scenarios. The normal fixture includes income, expenses, a refund, an archived category, and a twelve-week trend.

See [verification](docs/verification.md) for results and remaining owner/device checks. The backend’s `docs/verification.md` remains the authoritative deployment/iPhone checklist.

## Project notes

The Google logo is an unmodified asset from GoogleSignIn-iOS 10.0.0; its Apache license is included in `docs/GoogleSignIn-LICENSE`. `scripts/generate-icon.swift` produces the app icon with Apple’s SF Symbols. There are no analytics, local financial persistence, background queues, extra authentication providers, or in-app Google Drive authorization.
