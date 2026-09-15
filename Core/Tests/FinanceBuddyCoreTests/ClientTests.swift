import AppIntents
import Foundation
import Testing

@testable import FinanceBuddyCore

final class StubProtocol: URLProtocol, @unchecked Sendable {
  final class Registry: @unchecked Sendable {
    let lock = NSLock()
    private var handlers: [String: @Sendable (URLRequest) throws -> (Int, [String: String], Data)] = [:]
    func register(
      _ host: String, handler: @escaping @Sendable (URLRequest) throws -> (Int, [String: String], Data)
    ) {
      lock.lock()
      defer { lock.unlock() }
      handlers[host] = handler
    }
    func reply(_ request: URLRequest) throws -> (Int, [String: String], Data) {
      lock.lock()
      let handler = handlers[request.url!.host!]!
      lock.unlock()
      return try handler(request)
    }
  }
  static let registry = Registry()
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
  override func startLoading() {
    do {
      let (status, headers, data) = try Self.registry.reply(request)
      client?.urlProtocol(
        self,
        didReceive: HTTPURLResponse(
          url: request.url!, statusCode: status, httpVersion: nil, headerFields: headers)!,
        cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: data)
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }
  static func body(_ request: URLRequest) -> Data {
    if let body = request.httpBody { return body }
    guard let stream = request.httpBodyStream else { return Data() }
    stream.open()
    defer { stream.close() }
    var data = Data()
    var buffer = [UInt8](repeating: 0, count: 1024)
    while stream.hasBytesAvailable {
      let count = stream.read(&buffer, maxLength: buffer.count)
      if count <= 0 { break }
      data.append(contentsOf: buffer.prefix(count))
    }
    return data
  }
  override func stopLoading() {}
}
@MainActor struct ClientTests {
  func makeClient(
    token: String? = "signed-token",
    handler: @escaping @Sendable (URLRequest) throws -> (Int, [String: String], Data)
  ) -> (LiveAPIClient, MemoryTokenStorage) {
    let host = UUID().uuidString.lowercased() + ".example.com"
    StubProtocol.registry.register(host, handler: handler)
    let config = LiveAPIClient.sessionConfiguration()
    config.protocolClasses = [StubProtocol.self]
    let tokens = MemoryTokenStorage(token)
    return (
      LiveAPIClient(
        baseURL: URL(string: "https://\(host)")!, build: "12.1", tokens: tokens,
        configuration: config), tokens
    )
  }
  @Test func requestsHaveOnlyNativeCredentialsAndWritesAreJSON() async throws {
    let (client, _) = makeClient { request in
      #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer signed-token")
      #expect(request.value(forHTTPHeaderField: "X-Finance-Buddy-Build") == "12.1")
      #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
      #expect(request.value(forHTTPHeaderField: "Cookie") == nil)
      #expect(request.value(forHTTPHeaderField: "Origin") == nil)
      #expect(request.httpShouldHandleCookies == false)
      if request.httpMethod != "GET" {
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        let object =
          (try? JSONSerialization.jsonObject(with: StubProtocol.body(request))) as? [String: Any]
        #expect(object != nil)
        if request.url?.path == "/api/journal", request.httpMethod != "DELETE" {
          #expect(object?["amount"] as? String == "20.00")
          #expect(object?["categoryId"] is NSNull)
        }
        if request.url?.path == "/api/budgets" {
          let query = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.queryItems
          #expect(
            query == [
              URLQueryItem(name: "kind", value: "month"),
              URLQueryItem(name: "date", value: "2026-09-13"),
            ])
          if request.httpMethod == "PUT" {
            #expect(object?["amount"] as? String == "0.00")
            #expect(object?["oneOff"] as? Bool == true)
          } else {
            #expect(object?["scope"] as? String == "onward")
          }
        }
      }
      let path = request.url!.path
      let data: Data
      if path == "/api/journal" && request.httpMethod == "GET" {
        data = try! JSONEncoder().encode(Fixtures.summary())
      } else if path == "/api/journal/trends" {
        data = try! JSONEncoder().encode(Fixtures.trends())
      } else if path == "/api/categories" && request.httpMethod == "GET" {
        data = try! JSONEncoder().encode(Fixtures.categories)
      } else if path == "/api/budgets" && request.httpMethod == "GET" {
        #expect(request.url?.query == "before=2026-09-06_week")
        data = try! JSONEncoder().encode(Fixtures.budgetList())
      } else if path == "/api/budgets" {
        data = Data(#"{"saved":true,"budget":null}"#.utf8)
      } else if path == "/api/auth/get-session" {
        data = try! JSONEncoder().encode(Fixtures.session)
      } else if path == "/api/journal/spreadsheet" {
        data = Data(
          #"{"url":"https://docs.google.com/spreadsheets/d/fixture","title":"Snapshot"}"#.utf8)
      } else if path == "/api/journal/export" {
        return (
          200,
          [
            "Content-Type": "application/pdf",
            "Content-Disposition": "attachment; filename=\"snapshot.pdf\"",
          ], Fixtures.pdf
        )
      } else {
        data = Data(#"{"saved":true,"changed":true,"success":true,"status":true}"#.utf8)
      }
      return (200, ["Set-Cookie": "forbidden-cookie=value"], data)
    }
    _ = try await client.session()
    _ = try await client.summary(.init())
    _ = try await client.trends(.init())
    _ = try await client.categories()
    let entry = EntryRequest(
      id: UUID().uuidString, kind: .expense, amount: Money(20), date: Fixtures.today,
      categoryId: nil, note: "")
    #expect(try await client.save(entry, correcting: false) == nil)
    #expect(try await client.save(entry, correcting: true) == nil)
    #expect(try await client.budgets(before: "2026-09-06_week").now.week != nil)
    let month = PeriodSelection(kind: .month, date: Fixtures.today)
    #expect(try await client.setBudget(month, BudgetRequest(amount: .zero, oneOff: true)) == nil)
    #expect(try await client.removeBudget(month, scope: .onward) == nil)
    try await client.delete(id: entry.id)
    try await client.changeCategory(
      CategoryRequest(action: .create, id: UUID().uuidString, kind: .income, name: "Gift"))
    _ = try await client.spreadsheet(.init(), id: UUID().uuidString)
    #expect(try await client.pdf(.init()).filename == "snapshot.pdf")
    try await client.signOut(everywhere: true)
  }
  @Test(arguments: SignInProvider.allCases)
  func signedHeaderReplacesTokenAndBodyIsNeverUsed(provider: SignInProvider) async throws {
    let (client, tokens) = makeClient(token: nil) { request in
      if request.url!.path == "/api/auth/sign-in/social" {
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
        #expect(request.value(forHTTPHeaderField: "Cookie") == nil)
        #expect(request.value(forHTTPHeaderField: "Origin") == nil)
        #expect(request.value(forHTTPHeaderField: "X-Finance-Buddy-Build") == "12.1")
        let object =
          (try? JSONSerialization.jsonObject(with: StubProtocol.body(request))) as? [String: Any]
        #expect(object?["provider"] as? String == provider.rawValue)
        #expect(
          (object?["idToken"] as? [String: String]) == [
            "token": "identity-token", "nonce": "original-nonce",
          ])
        return (200, ["set-auth-token": "signed-header"], Data(#"{"token":"unsigned-body"}"#.utf8))
      }
      #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer signed-header")
      return (
        200, ["set-auth-token": "refreshed-header"], try! JSONEncoder().encode(Fixtures.session)
      )
    }
    try await client.signIn(provider: provider, idToken: "identity-token", nonce: "original-nonce")
    #expect(tokens.token == "signed-header")
    _ = try await client.session()
    #expect(tokens.token == "refreshed-header")
  }
  @Test(arguments: SignInProvider.allCases)
  func missingHeaderCannotAuthenticate(provider: SignInProvider) async {
    let (client, tokens) = makeClient(token: nil) { _ in
      (200, [:], Data(#"{"token":"unsigned"}"#.utf8))
    }
    await #expect(throws: ClientError.self) {
      try await client.signIn(
        provider: provider, idToken: "identity-token", nonce: "original-nonce")
    }
    #expect(tokens.token == nil)
  }
  @Test func upgradeBlocksSubsequentRequests() async {
    let (client, _) = makeClient { _ in
      (426, [:], Data(#"{"code":"upgrade_required","error":"Update"}"#.utf8))
    }
    await #expect(throws: Refusal.self) { try await client.summary(.init()) }
    #expect(client.access.upgradeRequired)
    await #expect(throws: Refusal.self) { try await client.session() }
  }
  @Test func sessionNullClearsToken() async throws {
    let (client, tokens) = makeClient { _ in (200, [:], Data("null".utf8)) }
    #expect(try await client.session() == nil)
    #expect(tokens.token == nil)
  }
  @Test func configurationDisablesCookieStorageAndCaching() {
    let config = LiveAPIClient.sessionConfiguration()
    #expect(config.httpCookieStorage == nil)
    #expect(config.httpShouldSetCookies == false)
    #expect(config.requestCachePolicy == .reloadIgnoringLocalCacheData)
    #expect(config.urlCache == nil)
  }

  @Test func periodQueriesUseServerDatesAndCurrentWeekOmitsBoth() async throws {
    let (client, _) = makeClient { request in
      let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
      if components.queryItems != nil {
        #expect(
          components.queryItems == [
            URLQueryItem(name: "kind", value: "month"),
            URLQueryItem(name: "date", value: "2026-08-01"),
          ])
      }
      return (200, [:], try! JSONEncoder().encode(Fixtures.summary()))
    }
    _ = try await client.summary(.init())
    _ = try await client.summary(.init(kind: .month, date: CalendarDate("2026-08-01")))
  }
  @Test func refusalHeadersRefreshTokenAndUnauthenticatedClearsIt() async {
    let (client, tokens) = makeClient { _ in
      (
        503, ["set-auth-token": "new-signed-token"],
        Data(#"{"code":"unavailable","error":"Later"}"#.utf8)
      )
    }
    await #expect(throws: Refusal.self) { try await client.summary(.init()) }
    #expect(tokens.token == "new-signed-token")
    let (expired, expiredTokens) = makeClient { _ in
      (401, [:], Data(#"{"code":"unauthenticated","error":"Expired"}"#.utf8))
    }
    await #expect(throws: Refusal.self) { try await expired.summary(.init()) }
    #expect(expiredTokens.token == nil)
    #expect(expired.access.signedOut)
  }
  @Test func saveReplyCarriesBudgetAndUnreadableBudgetLeavesSaveConfirmed() async throws {
    let view = Fixtures.summary().budget!
    let (client, _) = makeClient { _ in
      (
        200, [:],
        try! JSONSerialization.data(withJSONObject: [
          "saved": true, "budget": try! JSONSerialization.jsonObject(with: JSONEncoder().encode(view)),
        ])
      )
    }
    let entry = EntryRequest(
      id: UUID().uuidString, kind: .expense, amount: Money(20), date: Fixtures.today,
      categoryId: nil, note: "")
    #expect(try await client.save(entry, correcting: false) == view)
    let (broken, _) = makeClient { _ in
      (200, [:], Data(#"{"saved":true,"budget":{"kind":"week"}}"#.utf8))
    }
    #expect(try await broken.save(entry, correcting: false) == nil)
  }
  @Test func malformedSuccessDoesNotClaimWriteConfirmed() async {
    let (client, _) = makeClient { _ in (200, [:], Data(#"{"other":true}"#.utf8)) }
    await #expect(throws: ClientError.self) { try await client.delete(id: "id") }
  }
  @Test func offlineWritesNeverReachTransport() async {
    let (client, _) = makeClient { _ in
      Issue.record("Offline write reached HTTP")
      return (200, [:], Data())
    }
    client.access.offline = true
    await #expect(throws: ClientError.self) { try await client.delete(id: "id") }
  }
}
