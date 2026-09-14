import FinanceBuddyCore
import SwiftUI

struct BudgetEditorView: View {
  @Bindable var store: BudgetEditorStore
  let offline: Bool
  let onSaved: (String) -> Void
  @Environment(\.dismiss) private var dismiss
  @Environment(\.dynamicTypeSize) private var typeSize
  @State private var kind: PeriodKind
  @State private var pickerDate: Date
  @State private var discard = false
  @State private var notification: ToastMessage?
  @FocusState private var amountFocused: Bool
  init(store: BudgetEditorStore, offline: Bool, onSaved: @escaping (String) -> Void) {
    self.store = store
    self.offline = offline
    self.onSaved = onSaved
    _kind = State(initialValue: store.kind)
    _pickerDate = State(initialValue: store.date.utcDate)
  }
  var body: some View {
    NavigationStack {
      Form {
        Section {
          if typeSize.isAccessibilitySize {
            kindPicker.pickerStyle(.menu)
          } else {
            kindPicker.pickerStyle(.segmented)
          }
          DatePicker("Date", selection: $pickerDate, displayedComponents: .date)
            .environment(\.calendar, CalendarDate.calendar)
            .environment(\.timeZone, CalendarDate.calendar.timeZone)
          LabeledContent("Budgeting") {
            Text(
              store.period.map { $0.kind.label(start: $0.start, end: $0.end, today: $0.today) }
                ?? "Week of 0–0 Sep"
            )
            .multilineTextAlignment(.trailing)
            .redacted(reason: store.period == nil ? .placeholder : [])
          }
          .accessibilityValue(store.resolving ? "Loading" : "")
        } footer: {
          if store.resolveError {
            Text("Could not check that period. Choose it again to retry.")
          } else {
            Text(
              store.oneOff
                ? "The budget applies to this period only, in place of any repeating budget."
                : "The budget applies to the period you choose and every one after it, until you change it."
            )
          }
        }
        if store.ended {
          Section {
            Label("This \(store.noun) has ended", systemImage: "clock.arrow.circlepath")
              .font(.headline)
            Text("Its budget stays as it was. Choose today or a later date to set a budget.")
              .font(.footnote)
          }
        }
        Section {
          HStack(alignment: .firstTextBaseline) {
            Text("MXN").foregroundStyle(.secondary)
            TextField("Amount", text: $store.amount).keyboardType(.decimalPad)
              .focused($amountFocused).accessibilityIdentifier("budgetAmount")
          }
        } header: {
          Text("Amount")
        } footer: {
          Text("The most you intend to spend. Zero plans a \(store.noun) with no spending.")
        }
        Section {
          Toggle("One-off (this period only)", isOn: $store.oneOff)
            .accessibilityIdentifier("budgetOneOff")
        }
        if store.canRemoveOneOff {
          Section {
            Button("Remove one-off", role: .destructive) {
              Task {
                await store.removeOneOff()
                showError()
              }
            }
          } footer: {
            Text("The repeating budget, if any, applies to this \(store.noun) again.")
          }
        }
      }
      .disabled(store.busy)
      .navigationTitle("Set budget")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { if store.dirty { discard = true } else { dismiss() } }
            .disabled(store.busy)
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(store.busy ? "Saving…" : "Save") {
            Task {
              notification = nil
              await store.save()
              showError()
            }
          }
          .disabled(!store.canSave || offline).accessibilityIdentifier("saveBudget")
        }
        ToolbarItemGroup(placement: .keyboard) {
          Spacer()
          Button("Done") { amountFocused = false }
        }
      }
      .confirmationDialog(
        "Discard unsaved changes?", isPresented: $discard, titleVisibility: .visible
      ) {
        Button("Keep Editing", role: .cancel) {}
        Button("Discard Changes", role: .destructive) { dismiss() }
      }
      .interactiveDismissDisabled(store.dirty || store.busy)
      .task { await store.resolve() }
      .onChange(of: pickerDate) { _, date in
        Task { await store.choose(kind: kind, date: CalendarDate(utcDate: date)) }
      }
      .onChange(of: kind) { _, kind in Task { await store.choose(kind: kind, date: store.date) } }
      .onChange(of: store.saved) { _, saved in
        if saved {
          onSaved(store.confirmation ?? "Budget saved.")
          dismiss()
        }
      }
      .toast($notification)
      .sensoryFeedback(.warning, trigger: store.error)
    }
  }
  private var kindPicker: some View {
    Picker("Period", selection: $kind) {
      ForEach(PeriodKind.allCases, id: \.self) { Text($0.title).tag($0) }
    }
  }
  private func showError() {
    guard let error = store.error else { return }
    amountFocused = store.field == "amount"
    notification = ToastMessage(text: error, isError: true)
  }
}
