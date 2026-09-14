import Foundation
import Observation

@MainActor @Observable public final class ExportStore {
  public enum Kind { case pdf, sheets }
  public struct Attempt: Sendable {
    public let id: String
    public let period: PeriodSelection
    public let title: String
  }
  public private(set) var kind: Kind = .pdf
  public private(set) var pending: Attempt?
  public private(set) var busy = false
  public private(set) var error: String?
  public private(set) var code: RefusalCode?
  public private(set) var fileURL: URL?
  public private(set) var spreadsheet: Spreadsheet?
  public private(set) var periodTitle = ""
  public var previewURL: URL?
  private var period: PeriodSelection?
  private var directory: URL?
  private let client: any APIClient
  public init(client: any APIClient) { self.client = client }
  public func begin(_ kind: Kind, summary: Summary) async {
    guard !busy else { return }
    // An unresolved Sheets attempt keeps its original period even after the selector moves.
    if let pending, kind == .sheets {
      self.kind = kind
      period = pending.period
      periodTitle = pending.title
      await retry()
      return
    }
    cleanupPDF()
    self.kind = kind
    period = summary.selection
    periodTitle = summary.title
    error = nil
    code = nil
    spreadsheet = nil
    await retry()
  }
  public func retry() async {
    guard !busy, let period, !client.access.offline else { return }
    busy = true
    error = nil
    code = nil
    defer { busy = false }
    if kind == .sheets {
      if pending == nil {
        pending = Attempt(id: UUID().uuidString, period: period, title: periodTitle)
      }
      guard let attempt = pending else { return }
      do {
        spreadsheet = try await client.spreadsheet(attempt.period, id: attempt.id)
        periodTitle = attempt.title
        pending = nil
      } catch let refusal as Refusal {
        code = refusal.code
        error = refusal.localizedDescription
        if refusal.code == .exportUnconfirmed || refusal.code == .exportPeriodMismatch {
          pending = nil
        }
      } catch { self.error = "The export could not be confirmed. Retry to check the same export." }
    } else {
      cleanupPDF()
      do {
        let document = try await client.pdf(period)
        let folder = FileManager.default.temporaryDirectory.appending(
          path: "FinanceBuddy-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        directory = folder
        let file = folder.appending(path: URL(fileURLWithPath: document.filename).lastPathComponent)
        try document.data.write(to: file, options: [.atomic, .completeFileProtection])
        fileURL = file
        previewURL = file
      } catch { self.error = "The PDF could not be created, and your journal is unchanged." }
    }
  }
  public func cleanupPDF() {
    previewURL = nil
    fileURL = nil
    if let directory { try? FileManager.default.removeItem(at: directory) }
    directory = nil
  }
}
