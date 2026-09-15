# App Store release status

Updated September 15, 2026. Version **1.0**, latest uploaded build **16** with the wallet icon. **Build 16 uploaded successfully, is Ready to Submit in TestFlight, and is selected on the draft App Store version. Build 15 remains Waiting for Review in Beta App Review. Not submitted for public App Review or released publicly.**

## Completed

- Merged wallet-icon PR #17 and Settings accessibility follow-up #18. Archived build **16** from main commit `1fda162`; signed archive, release checks and upload succeeded. Apple confirms **1.0 (16), Ready to Submit**. Attempting external Beta App Review returned: “You can’t submit a build for testing if another build is already in review.” Build 16 is assigned to the internal **Release Testing** group (zero testers), and its What to Test notes are saved. Build 15’s existing review was preserved. Selected and saved **16** on the draft version page; reloading preserved the selection. Opened Included Assets → App Icon and visually confirmed the wallet artwork in App Store Connect. Final archive: `artifacts/release-1.0-16/FinanceBuddy-final.xcarchive`; logs: `archive-final.log` and `upload.log`. See [verification](verification.md#wallet-icon-build-16--september-15-2026) for passed checks and the remaining Categories audit warning.

- Created [Finance Buddy: Journal in App Store Connect](https://appstoreconnect.apple.com/apps/6812466832/distribution), Apple ID **6812466832**, SKU `finance-buddy-ios`, bundle ID `com.guillermorebolledo.FinanceBuddy`, English (U.S.). The shorter name was unavailable; the planned fallback is reserved.
- Saved the description, promotional text, keywords, copyright, support URL, subtitle and Finance category. Saved the privacy URL separately. Published all 12 reconciled privacy data answers. They cover app/backend collection and the archived Google SDK, with purposes and linkage matching the manifest inventory.
- Set price to **MXN 0.00**, Mexico as the base region, and availability to **Mexico only**. The availability page confirmed “1 Country or Region” and Mexico “Available on App Release.” Mac and Vision Pro availability are disabled. Release mode is **manual after approval**.
- Completed the current age questionnaire: **4+** calculated global rating, no Kids category or override. The new “Social Media Disabled for Users Under 13” answer is No because the app has no social-media feature or age gate.
- Archived and uploaded **build 13**, then fixed an accessibility issue found during the test run and archived/uploaded **build 14**. Both upload logs report `Upload succeeded` and `EXPORT SUCCEEDED`. Build **15** adds the corrected app privacy manifest with no runtime-code change from 14. Its signed archive passed release checks, uploaded successfully and finished processing. **15 was initially selected on the draft version page (now replaced by 16)** and added to the internal Release Testing group.
- Release ignores `Config/Local.xcconfig`. The release checker now rejects a development origin, ATS exceptions, a wrong bundle ID and mismatched version/build numbers. All five rejection cases were exercised on temporary copies of the built plist.
- Fixed the cents-first entry amount field: currency moves above the amount at accessibility text sizes, the visible value can wrap instead of losing its cents, and VoiceOver gets one labeled input with its formatted value.
- Captured six actual app screenshots with fixture data, build 14, iPhone 17 Pro Max / iOS 26.5. Original PNGs and opaque **1320 × 2868** JPEGs are local. No personal journal data is shown. Confirmed all six uploaded screenshots persist after reloading Media Manager, ordered Dashboard, Entries, Entry editor, Budgets, Categories, Export. The 6.5-inch section inherits the 6.9-inch set.

- Published the corrected [privacy policy](https://financebuddy.tech/privacy). Backend [PR #67](https://github.com/guillermo-rebolledo/finance-buddy/pull/67) is merged after both full CI runs passed (**248 passed, 48 skipped**). Main commit `5177bce` is live in production deployment `dpl_Ao8pXdgqTpxtrCS9xKXogZoZWPU1`, including the policy and native Apple secret.
- Configured the missing `APPLE_IOS_CLIENT_SECRET` as a sensitive Production variable and redeployed. Signature and JWT claims verified locally; expires **March 14, 2027, 18:57:24 UTC**. See [renewal checklist](apple-secret-renewal.md).
- Confirmed the previous production deployment was `fe1c0df`, including backend deletion #60 and public pages #61. Production `MINIMUM_IOS_BUILD` is unset, so no minimum-version gate blocks builds 14/15. This was checked in an isolated directory to exclude local environment overrides.
- Saved the content-rights answer (no third-party content) and reviewer notes/contact supplied by the owner. The spare review account credentials are saved in both App Store Connect review forms. A fresh private-session password login reached the sample journal without Touch ID, SMS or another verification prompt.
- Confirmed the **Free Apps Agreement is Active** through July 20, 2027. Paid Apps remains Pending User Info with tax/banking notices; [paid-app requirements do not apply to this free app without in-app purchases](https://developer.apple.com/help/app-store-connect/manage-agreements/sign-and-update-agreements). Existing DSA status is Active; no agreements or financial forms were changed.

- Switched Google OAuth from Testing (one permitted user) to **In production**, completed public branding links, and declared the existing four non-sensitive scopes. Verification Center confirms no sensitive/restricted-scope verification is required. See [Google launch configuration](google-oauth-release.md).

## Verification

| Check | Evidence |
| --- | --- |
| Build 15 signed Release archive | `artifacts/release-1.0-15/archive.log`; no build warnings/errors; code signature verifies |
| Release configuration | `scripts/check-release.py` passed on the archive; production HTTPS, iPhone only, OAuth IDs, encryption declaration, privacy resource, version/build |
| Backend release checks | 248 tests passed, 48 skipped in each full CI run. Corrected test-clock assumptions; production authentication code unchanged |
| Core suite on macOS | 63 tests in 11 suites passed; `artifacts/release-1.0-13/core-tests.log` |
| Full simulator baseline (build 13) | 85 of 86 tests passed; the sole failure was clipped entry-amount text at AX5. Includes 63 core tests, nine view tests and 14 UI tests; parameterized runs are counted separately by Xcode |
| Focused verification after the fix (build 14) | All four tests passed: three full accessibility flows and entry create/edit/delete/period navigation; `artifacts/release-1.0-14/FocusedTests.xcresult` |
| Visual regression | AX5 screenshot inspected: `1,250.00` now fully visible; duplicate overlay accessibility removed. Standard-size editor and store screenshots inspected |
| Public pages | `/privacy` and `/support` returned HTTP 200 signed out on September 15 |
| Production session endpoint | Final production requests using `X-Finance-Buddy-Build: 15`: session HTTP 200/null; private endpoint HTTP 401/unauthenticated. This verifies public reachability and refusal, not authenticated phone flows |
| Toolchain | Xcode 26.6 / iOS SDK 26.5; meets [Apple's Xcode 26 / SDK 26 upload requirement](https://developer.apple.com/news/upcoming-requirements/?id=04282026a) |

The simulator tool timed out after five minutes while its test process continued. The final `.xcresult` was read after completion; the baseline result above is from that artifact, not the timeout.

## Remaining work, in order

1. **Wait for build 15’s Beta App Review to finish, then submit build 16 for Mexico Launch Testers.** Apple currently refuses a second build in review. The previous submission remains active: Submitted build **1.0 (15)** for the **Mexico Launch Testers** external group on September 15, 2026. Confirmed **Waiting for Review**, with one tester and one build. Automatic tester notification is enabled for the group containing `gortiz.dev@gmail.com`; that tester still shows **No Builds Available** while review is pending. No usable invitation is claimed yet. The internal Release Testing group has build 15 and zero testers.
2. **Install and test build 16 on a physical iPhone.** The owner will run the [production checklist](app-store-submission.md#testflight-production-checklist) after external testing becomes available. Include Apple-linked deletion with the deployed secret, Google/Apple sign-in, journal/budget parity, exports, offline recovery, account isolation, session revocation and audible accessibility. Build 16 includes the new icon and the Settings label fix. Record the exact selected build's smoke test and investigate the Categories hit-region audit warning before public review.
3. **Submit for public App Review after phone checks pass.** Review credentials and instructions are saved, the sample journal and Sheets connection are prepared, and password-based browser login is verified. See [review-account evidence](reviewer-setup.md). Record device evidence and the public submission date in `verification.md`. Manual release keeps publication under owner control. Accessibility feature claims remain unselected pending audible device verification.

## Local artifacts and repeatable commands

Local build outputs and screenshots are ignored by Git. Keep the archive and result bundles until release is complete.

```sh
# Run the existing complete verification workflow.
scripts/verify.sh

# For a future upload, increment CURRENT_PROJECT_VERSION in project.yml first.
xcodegen generate
xcodebuild -project FinanceBuddy.xcodeproj -scheme FinanceBuddy \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath artifacts/FinanceBuddy.xcarchive archive

# Export an App Store package without uploading it.
xcodebuild -exportArchive -archivePath artifacts/FinanceBuddy.xcarchive \
  -exportOptionsPlist Config/ExportOptions-AppStore.plist \
  -exportPath artifacts/app-store-export -allowProvisioningUpdates
```

The checked-in export options preserve version/build numbers. For uploads, use Organizer → Distribute App → App Store Connect, or a separate copy of the export options with `destination` set to `upload`. Never reuse an already uploaded build number.

Build 16 replaces the original book icon with the supplied wallet artwork. The canonical source and regeneration instructions are in [branding](branding/README.md). The untracked `export/` folder is an obsolete design export and is not used by Xcode. Build 15 and older archives retain the original icon.
