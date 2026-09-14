import Foundation
import OSLog
import Observation

@MainActor public protocol APIClient: AnyObject, Sendable {
  var access: AppAccess { get }
  func session() async throws -> SessionReply?
  func signIn(provider: SignInProvider, idToken: String, nonce: String) async throws
  func signOut(everywhere: Bool) async throws
  func clearToken() throws
  func summary(_ period: PeriodSelection) async throws -> Summary
  func trends(_ period: PeriodSelection) async throws -> Trends
  func save(_ entry: EntryRequest, correcting: Bool) async throws
  func delete(id: String) async throws
  func categories() async throws -> CategoryLists
  func changeCategory(_ request: CategoryRequest) async throws
  func pdf(_ period: PeriodSelection) async throws -> PDFDocument
  func spreadsheet(_ period: PeriodSelection, id: String) async throws -> Spreadsheet
}
