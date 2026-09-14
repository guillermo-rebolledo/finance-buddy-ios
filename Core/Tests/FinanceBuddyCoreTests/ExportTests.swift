import Foundation
import Testing

@testable import FinanceBuddyCore

@MainActor struct ExportTests {
  @Test func retriesKeepExportIdentityAndOriginalPeriod() async throws {
    let api = FakeAPIClient()
    let store = ExportStore(client: api)
    api.failure = Refusal(.notConfirmed, message: "Retry", status: 503)
    await store.begin(.sheets, summary: Fixtures.summary())
    let first = try #require(store.pending)
    await store.begin(.sheets, summary: Fixtures.summary(.init(kind: .month)))
    #expect(api.exportRequests.count == 2)
    #expect(api.exportRequests[1].1 == first.id)
    #expect(api.exportRequests[1].0 == first.period)
    api.failure = nil
    await store.retry()
    #expect(store.pending == nil)
    #expect(store.spreadsheet != nil)
  }
  @Test(arguments: [RefusalCode.exportUnconfirmed, .exportPeriodMismatch])
  func explicitNewExportsUseNewIDs(code: RefusalCode) async {
    let api = FakeAPIClient()
    let store = ExportStore(client: api)
    api.failure = Refusal(code, message: "Check Drive", status: 409)
    await store.begin(.sheets, summary: Fixtures.summary())
    #expect(store.pending == nil)
    let first = api.exportRequests[0].1
    api.failure = nil
    await store.retry()
    #expect(api.exportRequests[1].1 != first)
  }
  @Test func pdfIsSavedUnderServerFilenameAndCleaned() async throws {
    let store = ExportStore(client: FakeAPIClient())
    await store.begin(.pdf, summary: Fixtures.summary())
    let file = try #require(store.fileURL)
    #expect(file.lastPathComponent.contains("exported-2026-09-13.pdf"))
    #expect(try Data(contentsOf: file).starts(with: Data("%PDF".utf8)))
    store.cleanupPDF()
    #expect(FileManager.default.fileExists(atPath: file.path) == false)
  }
}
