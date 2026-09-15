import Foundation
import Testing

@testable import FinanceBuddyCore

@MainActor struct AccountDeletionTests {
  @Test(arguments: [nil, "apple-code"] as [String?], [204, 401])
  func wireRequestAndTokenRemoval(code: String?, status: Int) async throws {
    let (client, tokens) = ClientTests().makeClient { request in
      #expect(request.url?.path == "/api/account")
      #expect(request.httpMethod == "DELETE")
      #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer signed-token")
      if let code {
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        let body = try? JSONDecoder().decode([String: String].self, from: StubProtocol.body(request))
        #expect(body == ["appleAuthorizationCode": code])
      } else {
        #expect(StubProtocol.body(request).isEmpty)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == nil)
      }
      return (status, [:], status == 204 ? Data() : Data(#"{"code":"unauthenticated","error":"Expired"}"#.utf8))
    }
    try await client.deleteAccount(appleAuthorizationCode: code)
    #expect(tokens.token == nil)
    #expect(client.access.signedOut)
  }

  @Test(arguments: ["apple_authorization_required", "apple_revocation_failed", "forbidden", "unavailable"])
  func refusalsKeepToken(code: String) async throws {
    let (client, tokens) = ClientTests().makeClient { _ in
      (403, [:], Data("{\"code\":\"\(code)\",\"error\":\"Refused\"}".utf8))
    }
    let refusal = await #expect(throws: Refusal.self) {
      try await client.deleteAccount(appleAuthorizationCode: nil)
    }
    #expect(refusal?.code.rawValue == code)
    #expect(tokens.token == "signed-token")
    #expect(client.access.signedOut == false)
  }

  @Test func transportFailureKeepsToken() async {
    let (client, tokens) = ClientTests().makeClient { _ in
      throw URLError(.networkConnectionLost)
    }
    await #expect(throws: URLError.self) { try await client.deleteAccount(appleAuthorizationCode: nil) }
    #expect(tokens.token == "signed-token")
    #expect(client.access.signedOut == false)
  }

  @Test func offlineKeepsTokenWithoutSendingRequest() async {
    let (client, tokens) = ClientTests().makeClient { _ in
      Issue.record("Offline deletion reached transport")
      return (204, [:], Data())
    }
    client.access.offline = true
    await #expect(throws: ClientError.self) { try await client.deleteAccount(appleAuthorizationCode: nil) }
    #expect(tokens.token == "signed-token")
  }

  @Test func deletionClearsJournalAndSession() async throws {
    let api = FakeAPIClient()
    let store = SessionStore(client: api)
    await store.restore()
    await store.deleteAccount()
    #expect(store.state == .signedOut)
    #expect(store.user == nil)
    #expect(store.message == "Your account was deleted.")
    #expect(api.entries.isEmpty)
    #expect(api.managedCategories.all.isEmpty)
    #expect(api.budgets.isEmpty)
    #expect(try await api.session() == nil)
    await store.authenticate(provider: .google, idToken: "new", nonce: "nonce")
    #expect(store.state == .signedIn)
    #expect(api.entries.isEmpty)
    #expect(api.budgets.isEmpty)
    #expect(api.managedCategories.income.map(\.name) == ["Salary", "Freelance", "Other income"])
    #expect(api.managedCategories.expense.map(\.name) == ["Groceries", "Dining", "Transport", "Housing", "Utilities", "Health", "Shopping", "Entertainment"])
  }

  @Test func appleRequirementKeepsJournal() async {
    let api = FakeAPIClient()
    api.requiresAppleAuthorization = true
    let store = SessionStore(client: api)
    await store.restore()
    let count = api.entries.count
    await store.deleteAccount()
    #expect(store.state == .signedIn)
    #expect(store.user != nil)
    #expect(store.appleAuthorizationRequired)
    #expect(store.message == nil)
    #expect(api.entries.count == count)
  }

  @Test(arguments: [false, true])
  func appleAuthorizationRetry(revocationFails: Bool) async {
    let api = FakeAPIClient()
    api.requiresAppleAuthorization = true
    let store = SessionStore(client: api)
    await store.restore()
    await store.deleteAccount()
    #expect(store.appleAuthorizationRequired)
    if revocationFails { api.failure = Refusal(.appleRevocationFailed, message: "Failed") }
    await store.deleteAccount(appleAuthorizationCode: "code")
    #expect(store.appleAuthorizationRequired == false)
    #expect(store.state == (revocationFails ? .signedIn : .signedOut))
    #expect((store.user != nil) == revocationFails)
    #expect(api.entries.isEmpty == !revocationFails)
    #expect(store.message == (revocationFails ? SessionStore.deletionFailureMessage : "Your account was deleted."))
  }

  @Test func networkFailureKeepsUserAndJournal() async {
    let api = FakeAPIClient()
    let store = SessionStore(client: api)
    await store.restore()
    api.transportError = URLError(.networkConnectionLost)
    let count = api.entries.count
    await store.deleteAccount()
    #expect(store.state == .signedIn)
    #expect(store.user?.id == Fixtures.session.user.id)
    #expect(store.message == SessionStore.deletionFailureMessage)
    #expect(api.entries.count == count)
    #expect(store.busy == false)
  }

  @Test func unauthenticatedStoreReplyCountsAsDeleted() async {
    let api = FakeAPIClient()
    let store = SessionStore(client: api)
    await store.restore()
    api.failure = Refusal(.unauthenticated, message: "Expired")
    await store.deleteAccount()
    #expect(store.state == .signedOut)
    #expect(store.user == nil)
    #expect(store.message == "Your account was deleted.")
    #expect(api.signedIn == false)
  }

  @Test func busyGuardDoesNotSendSecondDeletion() async {
    let gate = DispatchSemaphore(value: 0)
    let (started, continuation) = AsyncStream<Void>.makeStream()
    let (client, _) = ClientTests().makeClient { request in
      if request.url?.path == "/api/auth/get-session" {
        return (200, [:], try! JSONEncoder().encode(Fixtures.session))
      }
      continuation.yield(())
      gate.wait()
      return (204, [:], Data())
    }
    let store = SessionStore(client: client)
    await store.restore()
    let deletion = Task { await store.deleteAccount() }
    for await _ in started { break }
    #expect(store.busy)
    await store.deleteAccount()
    #expect(store.state == .signedIn)
    gate.signal()
    await deletion.value
    continuation.finish()
    #expect(store.state == .signedOut)
    #expect(store.busy == false)
  }
}
