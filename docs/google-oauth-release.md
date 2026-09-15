# Google OAuth launch configuration — September 15, 2026

Project: `finance-buddy-508323` (project number `443304532669`).

## Completed in Google Auth Platform

- Found OAuth in **Testing**, limited to one configured test user. Publishing was disabled because the branding setup lacked public links.
- Saved app name **Finance Buddy**, home page `https://financebuddy.tech`, and privacy link `https://financebuddy.tech/privacy`. Existing support/developer contact remains `gortiz.dev@gmail.com`.
- Declared the scopes already requested by the app/backend: `openid`, `https://www.googleapis.com/auth/userinfo.email`, `https://www.googleapis.com/auth/userinfo.profile`, `https://www.googleapis.com/auth/drive.file`.
- Confirmed all four appear under **non-sensitive scopes**, with no sensitive or restricted scopes selected. This changes the console inventory, not the app's requested permissions.
- Switched publishing status to **In production**; confirmed it persisted. Google accounts outside the old test-user list can now authorize the app, subject to ordinary Google account/security checks.
- Verification Center states verification is not required because no sensitive/restricted scopes are requested. It separately notes that custom branding is not shown until branding verification; that is not a sensitive-scope approval blocker.

The iOS and web OAuth clients already match the Release client IDs. The iOS SDK is configured with the web server client ID for its ID-token audience. Production's unset optional `GOOGLE_IOS_CLIENT_ID` is therefore not by itself evidence of a sign-in failure; verify the actual Release sign-in on the phone.

The console may still show a lifetime 100-user cap for **unapproved sensitive/restricted scopes**. Do not interpret that text as a remaining test-user restriction on these four non-sensitive scopes. Reassess verification if new scopes, a logo or branding requirements are introduced.

Physical-device Google sign-in and Sheets exports, including a fresh account, remain on the production checklist. The dedicated review account is configured; see [review-account setup](reviewer-setup.md).
