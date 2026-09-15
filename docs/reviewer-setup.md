# App Review account setup

The app requires Apple or Google sign-in. App Store Connect therefore needs a working review login before submission. Do not use the owner's personal journal.

## Current review account status — September 15, 2026

The owner supplied a spare Google account after new-account SMS verification failed. Its credentials are saved in both App Store Connect review forms; do not record its password in this repository.

- Google sign-in succeeded in a separate private browser session; the selected identity was confirmed during Google authorization and in the exported spreadsheet.
- The owner explicitly approved the `drive.file` grant. Finance Buddy confirmed Google Sheets is connected.
- Created the six fictional entries below, the custom expense category **Learning**, and a repeating monthly budget of **MXN 16,000** from September 2026.
- Verified the September dashboard and generated Google Sheet: six entries, income **MXN 25,800.00**, expenses after refunds **MXN 8,535.25**, net change **MXN 17,264.75**. The Sheet is private to the review account.
- Downloaded the September PDF and checked its extracted text: the same six entries and totals are present on one page. Local filename: `finance-buddy-month-2026-09-01-to-2026-09-30-exported-2026-09-15.pdf` in Downloads.
- **Password-based access verified:** closed the previous private session, started a fresh private session, selected Google's “Try another way” → “Enter your password”, and reached the sample journal with the exact saved review password. No Touch ID, SMS or other second-factor prompt was needed in this check. Google may still challenge a different device or location; keep the account available during review.
- Both TestFlight Test Information and App Store version review credentials/notes are saved. Reloading the App Store version confirmed persistence. Build **1.0 (15)** was submitted for **Beta App Review** and shows **Waiting for Review** in the external group.

## Owner steps

1. Use the spare Google account already supplied for Finance Buddy review. Keep control of recovery methods; do not weaken the owner's personal account security.
2. Sign in to https://financebuddy.tech with that dedicated account. Check the displayed identity before adding data. Connect Google Sheets from Dashboard so the reviewer can test spreadsheet exports.
3. Enter the review Google email and password directly in App Store Connect → Finance Buddy: Journal → Distribution → iOS App Version 1.0 → App Review Information. Do not put its password in GitHub, these documents, or chat.
4. Test that exact login from a separate device/browser and confirm the reviewer can use it without a challenge requiring access to your personal phone. If Google prevents a reliable review login, resolve that before submission; don't ship a hidden authentication bypass.
5. Populate the journal below. Keep the account available through App Review. If deletion is tested on it, sign in and populate it again before submission.

## Demonstration journal

Use only fictional sample records. Dates below assume review preparation in September 2026; adjust to the current month if review is delayed.

| Date | Type | Amount (MXN) | Category | Note |
| --- | --- | --- | --- | --- |
| 2026-09-01 | Income | 24000.00 | Salary | Sample monthly salary |
| 2026-09-01 | Expense | 7500.00 | Housing | Sample rent |
| 2026-09-09 | Refund | 120.00 | Shopping | Sample returned purchase |
| 2026-09-14 | Expense | 975.25 | Groceries | Sample weekly groceries |
| 2026-09-15 | Expense | 180.00 | Transport | Sample transport |
| 2026-09-15 | Income | 1800.00 | Freelance | Sample design work |

Every note ends with “— fictional review data”. The Learning expense category and repeating monthly budget are saved. PDF and Google Sheets exports were checked against the totals above.

## Review contact

Owner supplied the private review contact name **Guillermo Ortiz** and email **gortiz.dev@gmail.com**. The supplied phone number and contact details are saved privately in App Store Connect. This does not change the public support contact.

Use the [review notes](app-store-submission.md#review-notes-template) once the account is populated and verified. Do not claim a sample journal or Sheets connection exists until it does.

## External TestFlight

On September 15, 2026, submitted **1.0 (15)** to Beta App Review for **Mexico Launch Testers**. App Store Connect confirms **External Group · 1 Tester · 1 Build**, with build status **Waiting for Review**. The tester remains `gortiz.dev@gmail.com`; its current status is **No Builds Available** until approval. “Automatically notify testers” was checked when submitting, so notification is configured for when Apple enables the build. No usable invitation is claimed before that happens.

Saved What to Test covers physical iPhone Google/Apple sign-in, returning sessions, transaction CRUD and summaries, budgets/categories, PDF/Sheets exports, offline recovery, larger text/VoiceOver and deletion using disposable identities. Public App Review submission and public release remain pending the owner's physical-device checks.
