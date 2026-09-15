import FinanceBuddyCore
import SwiftUI

struct EntryEditorView: View {
  @Bindable var store: EntryEditorStore
  let offline: Bool
  let onSaved: (CalendarDate, BudgetView?) -> Void
  @Environment(\.dismiss) private var dismiss
  @Environment(\.dynamicTypeSize) private var typeSize
  @State private var pickerDate: Date
  @State private var discard = false
  @State private var notification: ToastMessage?
  @FocusState private var focused: String?
  init(
    store: EntryEditorStore, offline: Bool,
    onSaved: @escaping (CalendarDate, BudgetView?) -> Void
  ) {
    self.store = store
    self.offline = offline
    self.onSaved = onSaved
    _pickerDate = State(initialValue: store.date.utcDate)
  }
  var body: some View {
    NavigationStack {
      Form {
        Section {
          if typeSize.isAccessibilitySize {
            typePicker.pickerStyle(.menu)
          } else {
            typePicker.pickerStyle(.segmented)
          }

        } footer: {
          Text(
            "Refunds reduce total expenses on the date the money is received. Enter a positive amount. Transfers between your own accounts, including credit-card repayments, are excluded."
          )
        }
        Section {
          amountLayout {
            Text("MXN").foregroundStyle(.secondary)
            // Cents-first: the field holds only digits and the visible text shows them masked, so
            // SwiftUI never rewrites the text under the caret while typing.
            ZStack(alignment: .leading) {
              Text(store.amount.isEmpty ? "0.00" : store.amount)
                .foregroundStyle(store.amount.isEmpty ? .tertiary : .primary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityHidden(true)
              TextField(
                "Amount",
                text: Binding(
                  get: { String(store.amount.filter(\.isNumber).drop { $0 == "0" }) },
                  set: { store.amount = Money.mask($0) }),
                prompt: Text("")
              )
              .keyboardType(.numberPad).foregroundStyle(.clear).tint(.clear)
              .accessibilityLabel("Amount in Mexican pesos")
              .accessibilityValue(store.amount.isEmpty ? "0.00" : store.amount)
              .focused($focused, equals: "amount").accessibilityIdentifier("entryAmount")
            }
          }

        } header: {
          Text("Amount")
        }
        Section {
          DatePicker(
            "Movement date", selection: $pickerDate, in: ...store.today.utcDate,
            displayedComponents: .date
          )
          .environment(\.calendar, CalendarDate.calendar).environment(
            \.timeZone, CalendarDate.calendar.timeZone
          )
          .focused($focused, equals: "date")

        } footer: {
          Text("Today or earlier in Mexico City.")
        }
        Section {
          Picker("Category", selection: $store.categoryId) {
            Text("Uncategorized").tag(String?.none)
            ForEach(store.choices) { category in
              Text(category.name + (category.active == false ? " (Archived)" : "")).tag(
                Optional(category.id))
            }
          }.focused($focused, equals: "categoryId")

        } footer: {
          if store.choices.contains(where: { $0.active == false }) {
            Text(
              "This entry may keep its archived category while its type stays in the same category list. New entries use active categories."
            )
          }
        }
        Section {
          TextField("Note", text: $store.note, axis: .vertical).lineLimit(4...10).focused(
            $focused, equals: "note"
          ).accessibilityIdentifier("entryNote")

        } footer: {
          Text("\(store.note.utf16.count) / 2,000 characters")
        }
        if store.locked {
          Section {
            Text("This request is kept exactly as submitted until its outcome is confirmed.")
          }
        }
      }
      .disabled(store.busy || store.locked)
      .navigationTitle(store.original == nil ? "New entry" : "Edit entry")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { if store.dirty || store.locked { discard = true } else { dismiss() } }
            .disabled(store.busy || store.locked)
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(store.busy ? "Saving…" : store.locked ? "Retry Same Entry" : "Save") {
            Task {
              notification = nil
              await store.save()
              if let error = store.error {
                focused = store.field
                notification = ToastMessage(text: error, isError: true)
              }
            }
          }
          .disabled(store.busy || offline).accessibilityIdentifier("saveEntry")
        }
        ToolbarItemGroup(placement: .keyboard) {
          Spacer()
          Button("Done") { focused = nil }
        }
      }
      .confirmationDialog(
        store.locked ? "Leave this unconfirmed entry?" : "Discard unsaved changes?",
        isPresented: $discard, titleVisibility: .visible
      ) {
        Button("Keep Editing", role: .cancel) {}
        Button("Discard Changes", role: .destructive) { dismiss() }
      } message: {
        Text(
          store.locked
            ? "The entry may already be saved. Check your journal before recording it again."
            : "Your changes have not been saved.")
      }
      .interactiveDismissDisabled(store.dirty || store.locked || store.busy)
      .onChange(of: pickerDate) { _, date in store.date = CalendarDate(utcDate: date) }
      .onChange(of: store.kind) { store.updateKind() }
      .onChange(of: store.field) { _, field in focused = field }
      .onChange(of: store.saved) { _, saved in
        if saved {
          onSaved(store.date, store.savedBudget)
          dismiss()
        }
      }
      .toast($notification)
      .sensoryFeedback(.warning, trigger: store.error)
    }
  }
  private var typePicker: some View {
    Picker("Type", selection: $store.kind) {
      ForEach(MovementKind.allCases, id: \.self) { Text($0.title).tag($0) }
    }.focused($focused, equals: "kind")
  }
  private var amountLayout: AnyLayout {
    typeSize.isAccessibilitySize
      ? AnyLayout(VStackLayout(alignment: .leading))
      : AnyLayout(HStackLayout(alignment: .firstTextBaseline))
  }
}
