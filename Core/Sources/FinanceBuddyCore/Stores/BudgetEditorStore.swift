import Foundation
import Observation

/// Sets a budget for a chosen period: repeating from it by default, or for that period only.
/// Every choice of kind or date is resolved by the server through the summary before the form
/// describes it, so the label, the prefilled amount, One-off, and the saved period always agree.
@MainActor @Observable public final class BudgetEditorStore: Identifiable {
  public let id = UUID()
  public private(set) var kind: PeriodKind
  public private(set) var date: CalendarDate
  /// The period last resolved by the server. Saving names exactly this period.
  public private(set) var period: Summary?
  public private(set) var resolving = false
  public private(set) var resolveError = false
  public var amount = ""
  public var oneOff = false
  public private(set) var busy = false
  public private(set) var error: String?
  public private(set) var field: String?
  public private(set) var saved = false
  public private(set) var confirmation: String?
  private var sequence = 0
  private let client: any APIClient
  public init(client: any APIClient, kind: PeriodKind, date: CalendarDate) {
    self.client = client
    self.kind = kind
    self.date = date
  }
  public var noun: String { (period?.kind ?? kind).rawValue }
  public var ended: Bool { period.map { $0.end < $0.today } ?? false }
  public var canSave: Bool { period != nil && !resolving && !ended && !busy }
  public var canRemoveOneOff: Bool { period?.budget?.repeats == false && !ended }
  public var dirty: Bool {
    amount != (period?.budget?.amount.wire ?? "") || oneOff != (period?.budget?.repeats == false)
  }
  public func resolve() async { await choose(kind: kind, date: date) }
  public func choose(kind: PeriodKind, date: CalendarDate) async {
    self.kind = kind
    self.date = date
    sequence += 1
    let current = sequence
    resolving = true
    do {
      let resolved = try await client.summary(.init(kind: kind, date: date))
      // A slower earlier choice must not replace the period now chosen.
      guard current == sequence else { return }
      period = resolved
      amount = resolved.budget?.amount.wire ?? ""
      // A period with a one-off budget opens that budget, not a second one.
      oneOff = resolved.budget?.repeats == false
      error = nil
      field = nil
      resolveError = false
      resolving = false
    } catch {
      guard current == sequence else { return }
      resolveError = true
      resolving = false
    }
  }
  public func validate() -> Bool {
    field = nil
    error = nil
    guard
      amount.range(of: #"^[0-9]{1,12}(?:\.[0-9]{1,2})?$"#, options: .regularExpression) != nil
    else {
      field = "amount"
      error =
        "Enter an amount of zero or more with up to two decimal places (maximum 999,999,999,999.99)."
      return false
    }
    return true
  }
  /// Setting a budget has the same effect when repeated, so a retry after a lost reply is safe
  /// and needs no kept request identity.
  public func save() async {
    guard canSave, !client.access.offline, let period, validate(),
      let money = try? Money(string: amount)
    else { return }
    busy = true
    defer { busy = false }
    do {
      let budget = try await client.setBudget(
        period.selection, BudgetRequest(amount: money, oneOff: oneOff))
      confirmation =
        budget.map {
          oneOff
            ? "One-off budget of \($0.amount.formatted()) saved \($0.phrase(today: period.today))."
            : "Budget of \($0.amount.formatted()) saved for every \(noun) from \($0.start.budgetName(today: period.today))."
        } ?? "Budget saved."
      saved = true
    } catch let refusal as Refusal {
      error = refusal.localizedDescription
      field = refusal.field
    } catch { self.error = "The budget could not be confirmed. Retry it safely." }
  }
  public func removeOneOff() async {
    guard canRemoveOneOff, !busy, !client.access.offline, let period else { return }
    busy = true
    error = nil
    field = nil
    defer { busy = false }
    do {
      let applies = try await client.removeBudget(period.selection, scope: .period)
      confirmation =
        applies.map {
          "One-off budget removed. The repeating budget of \($0.amount.formatted()) applies again."
        } ?? "One-off budget removed."
      saved = true
    } catch { self.error = error.localizedDescription }
  }
}
