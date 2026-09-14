import Foundation
import Security

public enum SignInNonce {
  public static func make() throws -> String {
    var bytes = [UInt8](repeating: 0, count: 32)
    let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
    guard status == errSecSuccess else { throw KeychainError(status: status) }
    return bytes.map { String(format: "%02x", $0) }.joined()
  }
}
