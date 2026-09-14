import Foundation
import OSLog
import Observation

@MainActor public final class LiveAPIClient: APIClient {
  public let access: AppAccess
  private let baseURL: URL
  private let build: String
  private let tokens: any TokenStorage
  private let urlSession: URLSession
  private let logger = Logger(subsystem: "com.guillermorebolledo.FinanceBuddy", category: "HTTP")
  public static func sessionConfiguration() -> URLSessionConfiguration {
    let config = URLSessionConfiguration.ephemeral
    config.httpCookieStorage = nil
    config.httpShouldSetCookies = false
    config.requestCachePolicy = .reloadIgnoringLocalCacheData
    config.urlCache = nil
    return config
  }
  public init(
    baseURL: URL, build: String, tokens: any TokenStorage, access: AppAccess = AppAccess(),
    configuration: URLSessionConfiguration? = nil
  ) {
    self.baseURL = baseURL
    self.build = build
    self.tokens = tokens
    self.access = access
    let config = configuration ?? Self.sessionConfiguration()
    config.httpCookieStorage = nil
    config.httpShouldSetCookies = false
    config.requestCachePolicy = .reloadIgnoringLocalCacheData
    config.urlCache = nil
    config.httpAdditionalHeaders = nil
    urlSession = URLSession(
      configuration: config, delegate: NoRedirectDelegate(), delegateQueue: nil)
  }
  public func clearToken() throws {
    try tokens.write(nil)
    access.signedOut = true
    access.sessionGeneration += 1
  }
  private func request(
    _ path: String, method: String = "GET", body: Data? = nil, period: PeriodSelection? = nil
  ) async throws -> (Data, HTTPURLResponse) {
    guard !access.upgradeRequired else {
      throw Refusal(.upgradeRequired, message: "Update Finance Buddy to continue.")
    }
    if access.offline && method != "GET" { throw ClientError.offline }
    var components = URLComponents(
      url: baseURL.appending(path: path), resolvingAgainstBaseURL: false)!
    if let period {
      var items: [URLQueryItem] = []
      if period.kind != .week || period.date != nil {
        items.append(URLQueryItem(name: "kind", value: period.kind.rawValue))
      }
      if let date = period.date {
        items.append(URLQueryItem(name: "date", value: date.description))
      }
      components.queryItems = items.isEmpty ? nil : items
    }
    var request = URLRequest(url: components.url!)
    request.httpMethod = method
    request.httpBody = body
    request.httpShouldHandleCookies = false
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue(build, forHTTPHeaderField: "X-Finance-Buddy-Build")
    if let token = try tokens.read() {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    if body != nil { request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
    let generation = access.sessionGeneration
    let (data, response) = try await urlSession.data(for: request)
    guard let http = response as? HTTPURLResponse else { throw ClientError.invalidResponse }
    guard generation == access.sessionGeneration else { throw CancellationError() }
    if let token = http.value(forHTTPHeaderField: "set-auth-token") { try tokens.write(token) }
    if !(200...299).contains(http.statusCode) {
      let refusal = Refusal.map(
        data: data, status: http.statusCode, signIn: path == "api/auth/sign-in/social",
        session: path == "api/auth/get-session")
      switch refusal.code {
      case .unauthenticated, .forbidden: try clearToken()
      case .upgradeRequired: access.upgradeRequired = true
      case .requestNotAllowed:
        logger.error("Request integrity refused for \(path, privacy: .public)")
      default: break
      }
      throw refusal
    }
    return (data, http)
  }
  private func decode<T: Decodable>(_ type: T.Type, path: String, period: PeriodSelection? = nil)
    async throws -> T
  {
    let (data, _) = try await request(path, period: period)
    return try JSONDecoder().decode(type, from: data)
  }
  private func write<T: Encodable>(
    _ body: T, path: String, method: String = "POST", successKey: String = "saved"
  ) async throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let (data, _) = try await request(path, method: method, body: encoder.encode(body))
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    guard object?[successKey] as? Bool == true else { throw ClientError.invalidResponse }
  }
  public func session() async throws -> SessionReply? {
    let reply = try await decode(SessionReply?.self, path: "api/auth/get-session")
    if reply == nil { try clearToken() }
    return reply
  }
  public func signIn(idToken: String, nonce: String) async throws {
    struct Token: Encodable {
      let token: String
      let nonce: String
    }
    struct Body: Encodable {
      let provider = "google"
      let idToken: Token
    }
    let (_, response) = try await request(
      "api/auth/sign-in/social", method: "POST",
      body: JSONEncoder().encode(Body(idToken: Token(token: idToken, nonce: nonce))))
    guard response.value(forHTTPHeaderField: "set-auth-token")?.isEmpty == false else {
      try clearToken()
      throw ClientError.missingSignedToken
    }
    access.signedOut = false
  }
  public func signOut(everywhere: Bool) async throws {
    do {
      try await write(
        [String: String](), path: everywhere ? "api/auth/revoke-sessions" : "api/auth/sign-out",
        successKey: everywhere ? "status" : "success")
    } catch {
      try clearToken()
      throw error
    }
    try clearToken()
  }
  public func summary(_ period: PeriodSelection) async throws -> Summary {
    try await decode(Summary.self, path: "api/journal", period: period)
  }
  public func trends(_ period: PeriodSelection) async throws -> Trends {
    try await decode(Trends.self, path: "api/journal/trends", period: period)
  }
  public func save(_ entry: EntryRequest, correcting: Bool) async throws {
    try await write(entry, path: "api/journal", method: correcting ? "PATCH" : "POST")
  }
  public func delete(id: String) async throws {
    try await write(["id": id], path: "api/journal", method: "DELETE")
  }
  public func categories() async throws -> CategoryLists {
    try await decode(CategoryLists.self, path: "api/categories")
  }
  public func changeCategory(_ request: CategoryRequest) async throws {
    try await write(request, path: "api/categories", successKey: "changed")
  }
  public func pdf(_ period: PeriodSelection) async throws -> PDFDocument {
    let (data, response) = try await request("api/journal/export", period: period)
    guard response.mimeType == "application/pdf", data.starts(with: Data("%PDF".utf8)) else {
      throw ClientError.invalidResponse
    }
    let disposition = response.value(forHTTPHeaderField: "Content-Disposition") ?? ""
    let raw = disposition.components(separatedBy: "filename=").dropFirst().first?
      .trimmingCharacters(in: CharacterSet(charactersIn: "\" "))
    let filename = raw.map { URL(fileURLWithPath: $0).lastPathComponent } ?? "finance-buddy.pdf"
    return PDFDocument(
      data: data, filename: filename.hasSuffix(".pdf") ? filename : "finance-buddy.pdf")
  }
  public func spreadsheet(_ period: PeriodSelection, id: String) async throws -> Spreadsheet {
    let (data, _) = try await request(
      "api/journal/spreadsheet", method: "POST", body: JSONEncoder().encode(["id": id]),
      period: period)
    return try JSONDecoder().decode(Spreadsheet.self, from: data)
  }
}
