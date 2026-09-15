# App icon

`app-icon-source.webp` is the original 2048 × 2048 wallet artwork supplied for the app. Keep this source outside the app bundle.

From the repository root, regenerate the production asset with:

```sh
swift scripts/generate-icon.swift
```

The script writes `FinanceBuddy/Assets.xcassets/AppIcon.appiconset/AppIcon.png`: a 1024 × 1024 sRGB PNG with no alpha channel, no crop and square corners. The existing universal iOS asset catalog generates all required device sizes and the App Store icon. iOS applies the corner mask and derives appearance variants. There are no alternate icons or separate icon assets for other app targets.

The local, untracked `export/` directory is an older design export and is not used by Xcode. Do not copy its assets over the current icon.

## App Store Connect

Apple obtains the icon from the uploaded app build; it is not a separate listing image upload. See [Apple's app icon instructions](https://developer.apple.com/help/app-store-connect/manage-app-information/add-an-app-icon).

On September 15, 2026, build 1.0 (15) is waiting for Beta App Review. To deliver this icon, merge the PR, archive with an unused higher build number, upload, wait for processing, and select that new build on the draft App Store version. Add it to the appropriate TestFlight group and test it on a physical iPhone before public submission. If version 1.0 has already been published by then, create a new marketing version as well.

Existing archives and uploaded builds retain their original icon. Screenshots of the app's internal screens do not need replacement for an icon-only update.

Build **1.0 (16)** was uploaded from merged main on September 15, 2026 and selected on the draft App Store version. The Included Assets preview in App Store Connect shows this wallet icon. External Beta App Review is temporarily blocked while build 15 is already in review; see [release status](../release-status.md).
