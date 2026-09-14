import Foundation
import Security

@MainActor public final class KeychainTokenStorage: TokenStorage {
  private let service: String
  public init(service: String = "com.guillermorebolledo.FinanceBuddy.session") {
    self.service = service
  }
  private var query: [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service,
      kSecAttrAccount as String: "bearer-session",
    ]
  }
  public func read() throws -> String? {
    var query = query
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    var result: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    if status == errSecItemNotFound { return nil }
    guard status == errSecSuccess, let data = result as? Data,
      let token = String(data: data, encoding: .utf8)
    else { throw KeychainError(status: status) }
    return token
  }
  public func write(_ token: String?) throws {
    guard let token else {
      let status = SecItemDelete(query as CFDictionary)
      guard status == errSecSuccess || status == errSecItemNotFound else {
        throw KeychainError(status: status)
      }
      return
    }
    let attributes: [String: Any] = [
      kSecValueData as String: Data(token.utf8),
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    ]
    let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    if status == errSecItemNotFound {
      let added = SecItemAdd(query.merging(attributes) { _, new in new } as CFDictionary, nil)
      guard added == errSecSuccess else { throw KeychainError(status: added) }
    } else if status != errSecSuccess {
      throw KeychainError(status: status)
    }
  }
}
