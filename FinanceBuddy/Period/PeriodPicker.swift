import FinanceBuddyCore
import SwiftUI

struct PeriodPicker: View {
  @Bindable var store: PeriodStore
  @Environment(\.dynamicTypeSize) private var typeSize
  @State private var kind: PeriodKind = .week
  @State private var jumpDate = Date(timeIntervalSince1970: 0)
  @State private var showingDate = false

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      if typeSize.isAccessibilitySize {
        kindPicker.pickerStyle(.menu)
        PeriodTitle(
          summary: store.summary, fallback: store.selection.requestDescription, stacked: true)
        HStack {
          previous
          Spacer()
          next
        }
      } else {
        kindPicker.pickerStyle(.segmented)
        HStack {
          previous
          PeriodTitle(
            summary: store.summary, fallback: store.selection.requestDescription, stacked: false)
          next
        }
      }
      let actions =
        typeSize.isAccessibilitySize
        ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout())
      actions {
        Button(action: jump) {
          Text("Jump to date")
            .fixedSize(horizontal: false, vertical: true)
            .frame(minHeight: 44).contentShape(Rectangle())
        }.disabled(store.summary == nil)
        if !typeSize.isAccessibilitySize { Spacer() }
        if store.summary?.containsToday == false
          || (store.failureMessage != nil && store.selection.date != nil)
        {
          Button(action: store.current) {
            Text("Today").frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
          }
        }
      }
      if store.loading { LoadingView(title: "Loading period…").font(.caption) }
      if let message = store.failureMessage {
        VStack(alignment: .leading, spacing: 8) {
          Label(message, systemImage: "exclamationmark.triangle").font(.callout)
          if let error = store.error { Text(error).font(.caption).foregroundStyle(.secondary) }
          Button("Retry") { Task { await store.refresh(dashboard: true) } }.frame(minHeight: 44)
        }.accessibilityElement(children: .contain)
      }
    }
    .lineLimit(nil)
    .buttonStyle(.borderless)
    .onAppear { kind = store.selection.kind }
    .onChange(of: store.selection.kind) { _, value in kind = value }
    .sheet(isPresented: $showingDate) {
      NavigationStack {
        DatePicker("Jump to date", selection: $jumpDate, displayedComponents: .date)
          .datePickerStyle(.graphical).padding()
          .environment(\.calendar, CalendarDate.calendar).environment(
            \.timeZone, CalendarDate.calendar.timeZone
          )
          .navigationTitle("Jump to date").navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingDate = false } }
            ToolbarItem(placement: .confirmationAction) {
              Button("Show") {
                store.select(.init(kind: kind, date: CalendarDate(utcDate: jumpDate)))
                showingDate = false
              }
            }
          }
      }.presentationDetents([.medium, .large])
    }
  }
  private var kindPicker: some View {
    Picker("Summary period", selection: $kind) {
      ForEach(PeriodKind.allCases, id: \.self) { Text($0.title).tag($0) }
    }.onChange(of: kind) { _, value in
      if value != store.selection.kind {
        store.select(.init(kind: value, date: store.selection.date))
      }
    }
  }
  private var previous: some View {
    Button(action: store.previous) {
      Image(systemName: "chevron.left").frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
    }
    .accessibilityLabel("Previous period").disabled(store.summary == nil || store.loading)
  }
  private var next: some View {
    Button(action: store.next) {
      Image(systemName: "chevron.right").frame(minWidth: 44, minHeight: 44).contentShape(
        Rectangle())
    }
    .accessibilityLabel("Next period").disabled(store.summary == nil || store.loading)
  }
  private func jump() {
    guard let summary = store.summary else { return }
    jumpDate = (store.selection.date ?? summary.today).utcDate
    showingDate = true
  }
}
