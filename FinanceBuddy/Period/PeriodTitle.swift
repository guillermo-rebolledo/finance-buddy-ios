import FinanceBuddyCore
import SwiftUI

struct PeriodTitle: View {
  let summary: Summary?
  let fallback: String
  let stacked: Bool
  var loading = false
  var body: some View {
    VStack(spacing: 4) {
      Text(summary?.title ?? fallback).font(.headline)
        .fixedSize(horizontal: false, vertical: true)
      // Keep the subtitle line while loading so the picker height doesn't jump.
      if let summary {
        Text(
          stacked ? "\(summary.start.description)\n–\n\(summary.end.description)" : summary.subtitle
        )
        .font(.caption).foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
      } else if loading {
        Text(stacked ? "0000-00-00\n–\n0000-00-00" : "0000-00-00 – 0000-00-00").font(.caption)
      }
    }.multilineTextAlignment(.center).frame(maxWidth: .infinity)
      .redacted(reason: loading ? .placeholder : [])
      .accessibilityElement(children: .combine)
      .accessibilityValue(loading ? "Loading" : "")
  }
}
