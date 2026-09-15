# App Store submission kit

Version 1.0, current upload 15. See [release status](release-status.md) for completed account setup, uploads and remaining blockers. This kit supports [spec #7](https://github.com/guillermo-rebolledo/finance-buddy-ios/issues/7). Complete the owner-run checks in [#13](https://github.com/guillermo-rebolledo/finance-buddy-ios/issues/13) before submission. Simulator tests do not establish production readiness.

## Listing text

| Field | Copy |
| --- | --- |
| Name | Finance Buddy: Journal |
| Original name (unavailable) | Finance Buddy |
| Subtitle | A clear journal for your money |
| Keywords | expenses,income,budget,journal,MXN,pesos,spending,refunds,finance,summary |
| Promotional text | Record your financial movements, follow trends and plan budgets in Mexican pesos. Keep a clear journal on your iPhone and export snapshots when you need them. |
| Primary category | Finance |
| Copyright | 2026 Guillermo Ortiz Rebolledo |
| Support URL | https://financebuddy.tech/support |
| Privacy Policy URL | https://financebuddy.tech/privacy |

Finance Buddy: Journal was reserved on September 15, 2026 (Apple ID 6812466832). Finance Buddy was unavailable. The subtitle must fit 30 characters, keywords 100, and promotional text 170.

### Description

Finance Buddy is a personal finance journal for your iPhone. Record financial movements in Mexican pesos and see how your income, expenses and refunds add up.

• Record income, expenses and refunds with a movement date, category and optional note.
• Read daily, weekly and monthly summaries, including spending by category and net change.
• Follow trends across consecutive periods.
• Set repeating or one-off budgets for days, weeks and months. See what remains and change or stop a budget when your plans change.
• Organize your journal with custom categories. Archive categories while keeping past financial movements readable.
• Create export snapshots as PDFs or Google Sheets spreadsheets. Connect Google Sheets on the Finance Buddy website first.
• Sign in with Apple or Google and use the same journal on your iPhone and the website.

Amounts use MXN. All calendar dates and summary periods use Mexico City time. Net change describes recorded activity, not a bank account balance.

Your journal is private to your account. Apple and Google sign-ins with the same verified email share one journal; Apple's Hide My Email creates a separate journal. Delete your account from Settings when you no longer want to keep it. Spreadsheets already in Google Drive and PDFs you saved remain yours.

Finance Buddy is free, with no ads, tracking, subscriptions or in-app purchases. An internet connection and an Apple or Google account are required.

## Privacy label

The September 15 reconciliation covers the app, backend and every archived SDK. Use these exact purposes. All rows are **linked to identity: Yes**, **used for tracking: No**.

| App Store Connect type | Purposes | Evidence |
| --- | --- | --- |
| Contact Info → Name | App Functionality | Provider profile and Google manifest |
| Contact Info → Email Address | App Functionality | Provider identity and Google manifest |
| Contact Info → Phone Number | App Functionality | Google manifest |
| Location → Coarse Location | App Functionality | Google's IP-based fraud prevention and manifest |
| Identifiers → User ID | App Functionality, Analytics | Journal ownership; Google manifest |
| Identifiers → Device ID | Analytics | Google manifest |
| Usage Data → Other Usage Data | Analytics | Google manifest |
| Other Data Types | App Functionality, Analytics | Stored session IP/user agent and provider grants; Google manifest |
| Financial Info → Other Financial Info | App Functionality | Financial movements and budgets |
| User Content → Photos or Videos | App Functionality | Better Auth retains the Google profile-picture reference |
| User Content → Other User Content | App Functionality | Free-form journal notes and custom category names |
| Diagnostics → Other Diagnostic Data | App Functionality | Hosting request/error diagnostics |

Google's 10.0.0 manifest is the version-specific vendor disclosure used for its SDK; the integration has no documented override excluding these categories. This is not a claim that every person supplies every optional profile field. Finance Buddy itself does not ask for phone numbers or location permission. No vendor manifest was altered. See [reconciliation evidence](privacy-release-gap.md).

The live policy now distinguishes third-party SDK analytics from Finance Buddy's own processing, and describes profile images, notes, session details, logs, backups and deletion. Build 15 adds the missing app-owned manifest declarations; it changes no runtime behavior from build 14. All 11 archived manifests are retained and aggregate to the 12 rows above. Evidence: `artifacts/release-1.0-15/privacy-manifests.json` and `privacy-summary.json`. Required-reason SDK declarations remain unchanged (UserDefaults CA92.1, C56D.1 and 1C8F.1).


## Age rating answers

Use the current questionnaire; Apple computes the final rating. These answers describe the current app. Reference: [Apple's age-rating definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions).

| Question | Answer and reason |
| --- | --- |
| Parental controls / age assurance | No / No; no age-based controls or age verification |
| Unrestricted web access | No; app links open its own website and Google Drive, with no arbitrary URL entry or web search feature |
| User-generated content | No; journal notes are private, with no broad distribution or public feed |
| Social media / messaging and chat / advertising | No to each |
| Profanity or crude humor / horror or fear / alcohol, tobacco or drugs | None for each |
| Medical or treatment information / health or wellness topics | None / No |
| Mature or suggestive themes / sexual content or nudity / graphic sexual content | None for each |
| Cartoon or fantasy violence / realistic violence / prolonged graphic or sadistic violence / guns or weapons | None for each |
| Gambling / simulated gambling / contests / loot boxes | No or None for each |
| Made for Kids / override to a higher rating | No / no override |

Expected global rating: 4+, subject to the questionnaire and regional results. This is a journal, not a gambling, loan, banking or investment service. Reassess the web-access answer if the linked pages introduce general browsing or content discovery.

## Review notes template

Paste into App Store Connect. Replace bracketed fields there only. **Never commit real demo credentials.**

```text
Demo Google email: [ENTER IN APP STORE CONNECT ONLY]
Demo Google password: [ENTER IN APP STORE CONNECT ONLY]
Review contact: [OWNER NAME, EMAIL AND PHONE]

1. Tap Continue with Google and use the demo credentials above. The journal contains income, expenses and refunds across several weeks, custom categories and a repeating budget.
2. Entries: add, edit and delete a financial movement. Dashboard: change day/week/month, inspect summaries, trends and the chart data table. Budgets: set, change and stop a budget. Categories: create, rename, archive and restore a category.
3. All amounts are MXN and dates use America/Mexico_City. Net change is recorded income minus recorded expenses, not a bank balance.
4. PDF export is available from Dashboard. Google Sheets authorization happens on https://financebuddy.tech first; the demo account is connected there. Existing exported spreadsheets remain in the person's Google Drive.
5. Continue with Apple is also available. A new Apple identity opens an empty journal with starter categories. Share My Email with the same verified Google email opens the shared journal; Hide My Email creates a separate journal.
6. Delete Account is the final section in Settings. Read the confirmation and tap Delete Permanently. Apple-linked accounts may show Apple's system authorization sheet before deletion. Cancelling keeps the account. Successful deletion signs out all devices and browsers. Signing in again creates an empty journal. Please use a fresh test identity for deletion; deleting the demo identity clears its demonstration data too.
7. Privacy Policy is available before sign-in and in Settings. Support is also in Settings.
```

Before review, test the demo login on a separate device. Keep it usable throughout review and repopulate it if it is deleted. Production's `MINIMUM_IOS_BUILD` must not exceed the build in review or on TestFlight.

## Screenshot plan

Capture six portrait screenshots (PNG originals; opaque JPEGs for upload) at **1320 × 2868** using an **iPhone 17 Pro Max simulator**. This is an accepted 6.9-inch size in [Apple's screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications). Use the Debug build with the in-memory fake; fixture arguments are disabled in Release. Do not show personal production data.

| Order | Screen | Appearance | Launch arguments / action |
| --- | --- | --- | --- |
| 1 | Dashboard summary and budget | Light | `-useFakeAPI -light`; tap Dashboard in the fake-backed app |
| 2 | Financial movements | Light | `-useFakeAPI -light`; opens Entries in the fake-backed app |
| 3 | Entry editor | Light | `-useFakeAPI -light`; open the Weekly groceries entry |
| 4 | Budgets | Light | `-useFakeAPI -light`; tap Budgets |
| 5 | Categories | Light | `-useFakeAPI -light`; tap Categories |
| 6 | Export options | Light | `-useFakeAPI -light`; tap Dashboard, then Export |

The `export` preview route intentionally shows a reconnect refusal; use the normal fake-backed Dashboard for the listing's export-options image. The `dashboard`, `entries`, `settings` and `signIn` preview routes also exist for visual checks. Test `-largestType` separately for accessibility; use the standard system type size for listing captures. Capture via Simulator → File → Save Screen, verify the PNG's pixel size, and upload in this order. Capture actual app screens; avoid invented balances or export success claims.

## Apple Developer and App Store Connect setup

1. Create the iOS app record with bundle ID `com.guillermorebolledo.FinanceBuddy`, primary language English, and the available name above. Confirm copyright and review contact details.
2. Confirm Sign in with Apple is enabled on that App ID and it is associated with the website Services ID. Confirm provisioning for team `X76BWPRADX`.
3. Follow the backend's [Apple setup guide](https://github.com/guillermo-rebolledo/finance-buddy/blob/main/docs/apple-sign-in.md#generate-and-renew-the-bundle-id-secret): generate a separate JWT with the bundle ID as subject, deploy it as `APPLE_IOS_CLIENT_SECRET` alongside `APPLE_IOS_BUNDLE_ID`, and keep the web Services ID secret separate. Schedule renewal of both secrets before their 180-day expiration. Private keys and secrets stay outside this repo.
4. Confirm backend #60 and #61 are deployed, not merely merged. Check the minimum-build setting before every upload and while review is in progress.
5. Create a dedicated demo Google account, that App Review can access without a personal-device verification challenge. Populate several weeks of financial movements, custom categories, a repeating budget and trends; connect Sheets on the website. Put credentials only in App Store Connect.
6. Set price to **Free** and initially make the app available in **Mexico**. Complete the EU trader-status declaration with the owner's actual status before expanding availability. Disable Designed for iPhone distribution on Mac and Apple Vision Pro for this iPhone-only release.
7. Enter listing copy, privacy label, age rating, support/privacy URLs and review notes. Upload the screenshots. Use the standard Apple EULA unless the owner provides another.
8. Raise `CURRENT_PROJECT_VERSION` for each upload, regenerate the project, and run `scripts/verify.sh`. Archive Release for a physical-device destination, validate and upload from Xcode Organizer. Keep marketing version 1.0 for the first submission. Confirm export compliance is resolved by the built encryption declaration.
9. Complete the production checklist below on the uploaded TestFlight build. Select that exact build for review and submit only after all required checks pass.

## TestFlight production checklist

Record date, version/build, physical iPhone model/iOS, backend deployment, minimum build, tester and per-item results in [verification.md](verification.md). Use disposable accounts for deletion. Leave unchecked items pending; record failures with reproduction steps.

- [ ] Confirm the backend deployment includes #60 and #61; privacy and support pages load signed out, and the support contact works.
- [ ] Record production `MINIMUM_IOS_BUILD`; verify it is no higher than the uploaded build and will remain so throughout review/TestFlight.
- [ ] Apple Share My Email signs in and shares the existing Google journal for the same verified email.
- [ ] Apple Hide My Email signs in to a separate journal. A second verified account cannot see the first account's data.
- [ ] Cancel Apple sign-in and retry successfully.
- [ ] Google sign-in works on the physical iPhone with the Release configuration.
- [ ] Relaunch restores the Keychain session; the journal remains available.
- [ ] Sign Out ends this session. Sign Out Everywhere ends phone and browser sessions. Relaunch requires sign-in.
- [ ] Add, edit and delete financial movements; create, rename, archive and restore categories. Compare day/week/month summaries and trends against the website.
- [ ] Set, change, stop and remove budgets; compare repeating and one-off results with the website.
- [ ] Export a PDF and inspect its dates, MXN figures, categories and saved-file behavior.
- [ ] Connect Google Sheets on the website and export from iPhone; inspect the spreadsheet snapshot. Verify reconnect refusal/recovery and duplicate-safe retry after connection loss.
- [ ] Disconnect the network: loaded data remains visible and writes are disabled. Reconnect and retry. Verify expired-session, unavailable-server and other refusal recovery using the backend's deployment checklist.
- [ ] Delete a disposable Google-only account from Settings. Cancel once first. Verify the confirmation wording, deleted message, Keychain session removal and invalidation of browser/other-device sessions. Sign in again: empty journal with starter categories.
- [ ] Delete a disposable Apple-linked account, including one created natively without a stored web token. Cancel Apple's sheet first: stay signed in without an error. Retry successfully; verify actual Apple grant revocation and a fresh empty journal on next sign-in. Verify Google grant revocation where linked.
- [ ] Delete a shared-email Apple/Google journal and confirm neither provider retains the old journal; unrelated accounts remain unchanged.
- [ ] Delete from web Settings and verify the iPhone signs out on its next server request.
- [ ] Existing Google Drive spreadsheets and saved PDFs survive account deletion.
- [ ] Open Privacy Policy from sign-in and Settings, and Support from Settings; real pages load inside the browser.
- [ ] Navigate with physical-device VoiceOver, hear deletion confirmation/result and Audio Graph playback, and inspect the largest text size in light and dark appearances.
- [ ] Complete every deployment/iPhone check in the backend's [verification checklist](https://github.com/guillermo-rebolledo/finance-buddy/blob/main/docs/verification.md), including verified-account admission, separate-account isolation, session revocation, exports and refusal recovery. Record its deployment reference here.
- [ ] Verify the demo login and populated journal on a separate device; confirm the review build never shows Update Required.
- [ ] Enter final metadata, privacy/age-rating answers and screenshots in App Store Connect; select the tested build, submit for review and record the submission date. Track rejection feedback as new issues.
