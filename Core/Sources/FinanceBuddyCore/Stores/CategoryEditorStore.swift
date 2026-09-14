import Foundation
import Observation

@MainActor @Observable public final class CategoryEditorStore: Identifiable {
  public let id = UUID()
  public let original: Category?
  public let kind: CategoryKind
  public var name: String
  public private(set) var busy = false
  public private(set) var pending: CategoryRequest?
  public private(set) var error: String?
  public private(set) var saved = false
  private let all: [Category]
  private let client: any APIClient
  public init(client: any APIClient, kind: CategoryKind, all: [Category], original: Category? = nil)
  {
    self.client = client
    self.kind = kind
    self.all = all
    self.original = original
    name = original?.name ?? ""
  }
  public var dirty: Bool { name != (original?.name ?? "") }
  public var locked: Bool { pending != nil }
  public func save() async {
    guard !busy, !client.access.offline else { return }
    error = nil
    if pending == nil {
      let trimmed = DomainValidation.trim(name)
      guard !trimmed.isEmpty, trimmed.utf16.count <= 40,
        trimmed.range(of: #"\p{C}"#, options: .regularExpression) == nil
      else {
        error = "Enter a name of 1 to 40 characters, without line breaks or control characters."
        return
      }
      guard
        !all.contains(where: {
          $0.kind == kind && $0.id != original?.id && $0.name.lowercased() == trimmed.lowercased()
        })
      else {
        error =
          "You already have a category with that name in this list. Rename or restore that one instead."
        return
      }
      pending = CategoryRequest(
        action: original == nil ? .create : .rename, id: original?.id ?? UUID().uuidString,
        kind: original == nil ? kind : nil, name: trimmed)
    }
    guard let request = pending else { return }
    busy = true
    defer { busy = false }
    do {
      try await client.changeCategory(request)
      pending = nil
      saved = true
    } catch let refusal as Refusal {
      error = refusal.localizedDescription
      if refusal.status == 400 { pending = nil }
    } catch { self.error = "The category change could not be confirmed. Retry the same change." }
  }
}
