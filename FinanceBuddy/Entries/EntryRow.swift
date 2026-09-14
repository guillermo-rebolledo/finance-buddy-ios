import FinanceBuddyCore
import SwiftUI

struct EntryRow: View {
  let entry: JournalEntry
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      ViewThatFits(in: .horizontal) {
        HStack(alignment: .firstTextBaseline) {
          Text(entry.kind.title).font(.headline)
          Spacer()
          amount
        }
        VStack(alignment: .leading, spacing: 4) {
          Text(entry.kind.title).font(.headline)
          amount
        }
      }
      Text(entry.categoryName).font(.subheadline)
      if let note = entry.note, !note.isEmpty {
        Text(note).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
      }
    }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 4).contentShape(
      Rectangle()
    ).accessibilityElement(children: .combine)
  }
  private var amount: some View {
    Text(entry.signedAmount.formatted()).font(.headline.monospacedDigit()).foregroundStyle(.primary)
  }
}
