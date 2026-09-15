import Foundation
import Observation

@MainActor @Observable public final class EntryEditorStore: Identifiable {
  public let id = UUID()
  public var kind: MovementKind
  public var amount: String
  public var date: CalendarDate
  public var categoryId: String?
  public var note: String
  public let today: CalendarDate
  public let original: JournalEntry?
  public let categories: [Category]
  public private(set) var busy = false
  public private(set) var pending: EntryRequest?
  public private(set) var error: String?
  public private(set) var field: String?
  public private(set) var saved = false
  /// The budget the saved entry counts against, when the reply carried one.
  public private(set) var savedBudget: BudgetView?
  private var creationID: String?
  private let client: any APIClient
  public init(
    client: any APIClient, today: CalendarDate, categories: [Category], entry: JournalEntry? = nil
  ) {
    self.client = client
    self.today = today
    self.categories = categories
    original = entry
    kind = entry?.kind ?? .expense
    amount = entry.map { Money.mask($0.amount.wire) } ?? ""
    date = entry?.date ?? today
    categoryId = entry?.categoryId
    note = entry?.note ?? ""
  }
  public var locked: Bool { pending != nil }
  private var plainAmount: String { amount.replacingOccurrences(of: ",", with: "") }
  public var dirty: Bool {
    kind != (original?.kind ?? .expense)
      || amount != (original.map { Money.mask($0.amount.wire) } ?? "")
      || date != (original?.date ?? today) || categoryId != original?.categoryId
      || note != (original?.note ?? "")
  }
  public var choices: [Category] {
    var choices = categories.filter { $0.kind == kind.categoryKind && $0.active != false }
    if let original, original.kind.categoryKind == kind.categoryKind, let id = original.categoryId,
      !choices.contains(where: { $0.id == id })
    {
      choices.append(
        Category(id: id, kind: kind.categoryKind, name: original.categoryName, active: false))
    }
    return choices
  }
  public func updateKind() {
    if !choices.contains(where: { $0.id == categoryId }) { categoryId = nil }
  }
  public func validate() -> Bool {
    field = nil
    error = nil
    guard plainAmount.range(of: #"^[0-9]{1,12}(?:\.[0-9]{1,2})?$"#, options: .regularExpression) != nil,
      let money = try? Money(string: plainAmount), money.value > 0
    else {
      field = "amount"
      error =
        "Enter an amount greater than zero with up to two decimal places (maximum 999,999,999,999.99)."
      return false
    }
    guard date <= today else {
      field = "date"
      error = "Choose a valid movement date today or earlier in Mexico City."
      return false
    }
    guard note.utf16.count <= 2000 else {
      field = "note"
      error = "Keep the note within 2,000 characters."
      return false
    }
    guard categoryId == nil || choices.contains(where: { $0.id == categoryId }) else {
      field = "categoryId"
      error = "Choose an available category."
      return false
    }
    return true
  }
  public func save() async {
    guard !busy, !client.access.offline else { return }
    if pending == nil {
      guard validate(), let money = try? Money(string: plainAmount) else { return }
      if original == nil && creationID == nil { creationID = UUID().uuidString }
      pending = EntryRequest(
        id: original?.id ?? creationID!, kind: kind, amount: money, date: date,
        categoryId: categoryId, note: note)
    }
    guard let request = pending else { return }
    busy = true
    error = nil
    field = nil
    defer { busy = false }
    do {
      savedBudget = try await client.save(request, correcting: original != nil)
      saved = true
      pending = nil
      creationID = nil
    } catch let refusal as Refusal {
      error = refusal.localizedDescription
      field = refusal.field
      if refusal.status == 400 {
        pending = nil
        creationID = nil
      }
    } catch {
      self.error = "The entry could not be confirmed. Retry the same entry to avoid a duplicate."
    }
  }
}
