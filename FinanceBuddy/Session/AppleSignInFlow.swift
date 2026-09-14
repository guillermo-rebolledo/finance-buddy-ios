import AuthenticationServices
import CryptoKit
import FinanceBuddyCore
import Observation

@MainActor @Observable final class AppleSignInFlow {
  private(set) var signingIn = false
  private var nonce: String?

  func prepare(_ request: ASAuthorizationAppleIDRequest, session: SessionStore) {
    session.message = nil
    nonce = nil
    signingIn = true
    do {
      let nonce = try SignInNonce.make()
      self.nonce = nonce
      request.requestedScopes = [.email]
      // Better Auth compares the token's nonce against SHA-256 of the original nonce.
      request.nonce = Self.digest(nonce)
    } catch {
      session.message = Refusal.signInMessage
    }
  }

  func complete(_ result: Result<ASAuthorization, any Error>, session: SessionStore) async {
    let nonce = self.nonce
    self.nonce = nil
    defer { signingIn = false }
    switch result {
    case .success(let authorization):
      guard let nonce,
        let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
        let data = credential.identityToken,
        let token = String(data: data, encoding: .utf8), !token.isEmpty
      else {
        session.message = Refusal.signInMessage
        return
      }
      await session.authenticate(provider: .apple, idToken: token, nonce: nonce)
    case .failure(let error):
      // Dismissing Apple's sheet is a normal exit; keep both providers available to retry.
      if (error as? ASAuthorizationError)?.code != .canceled {
        session.message = Refusal.signInMessage
      }
    }
  }

  static func digest(_ nonce: String) -> String {
    SHA256.hash(data: Data(nonce.utf8)).map { String(format: "%02x", $0) }.joined()
  }
}
