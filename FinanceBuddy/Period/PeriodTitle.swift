import FinanceBuddyCore
import SwiftUI

struct PeriodTitle: View {
  let summary: Summary?
  let fallback: String
  let stacked: Bool
  var body: some View {
    VStack(spacing: 4) {
      Text(summary?.title ?? fallback).font(.headline)
        .fixedSize(horizontal: false, vertical: true)
      if let summary {
        Text(
          stacked ? "\(summary.start.description)\n–\n\(summary.end.description)" : summary.subtitle
        )
        .font(.caption).foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
      }
    }.multilineTextAlignment(.center).frame(maxWidth: .infinity)
  }
}
