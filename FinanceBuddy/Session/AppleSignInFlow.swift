import AuthenticationServices
import CryptoKit
import FinanceBuddyCore
import Observation
import UIKit

@MainActor @Observable final class AppleSignInFlow: NSObject, ASAuthorizationControllerDelegate,
  ASAuthorizationControllerPresentationContextProviding
{
  private(set) var signingIn = false
  private var nonce: String?
  private var controller: ASAuthorizationController?
  private var anchor: ASPresentationAnchor?
  private var deletionContinuation: CheckedContinuation<Result<Data?, any Error>, Never>?

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
      if !Self.isCancellation(error) {
        session.message = Refusal.signInMessage
      }
    }
  }

  func prepareDeletion(_ request: ASAuthorizationAppleIDRequest, session: SessionStore) {
    session.finishAppleDeletionAuthorization()
    session.message = nil
    signingIn = true
    request.requestedScopes = []
  }

  func authorizeDeletion(session: SessionStore) async {
    guard !signingIn, !session.busy else { return }
    let request = ASAuthorizationAppleIDProvider().createRequest()
    prepareDeletion(request, session: session)
    anchor = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
      .filter { $0.activationState == .foregroundActive }
      .flatMap(\.windows).first { $0.isKeyWindow }
    guard anchor != nil else {
      await completeDeletion(.failure(ASAuthorizationError(.failed)), session: session)
      return
    }
    let controller = ASAuthorizationController(authorizationRequests: [request])
    self.controller = controller
    controller.delegate = self
    controller.presentationContextProvider = self
    let result = await withCheckedContinuation { continuation in
      deletionContinuation = continuation
      controller.performRequests()
    }
    self.controller = nil
    anchor = nil
    await completeDeletion(result, session: session)
  }

  // The same result handler serves system authorization and view integration tests.
  func completeDeletion(_ result: Result<Data?, any Error>, session: SessionStore) async {
    defer { signingIn = false }
    session.finishAppleDeletionAuthorization()
    session.message = nil
    switch result {
    case .success(let data):
      guard let data, let code = String(data: data, encoding: .utf8), !code.isEmpty else {
        session.message = SessionStore.deletionFailureMessage
        return
      }
      await session.deleteAccount(appleAuthorizationCode: code)
    case .failure(let error):
      if !Self.isCancellation(error) { session.message = SessionStore.deletionFailureMessage }
    }
  }

  func authorizationController(controller: ASAuthorizationController,
    didCompleteWithAuthorization authorization: ASAuthorization)
  {
    let credential = authorization.credential as? ASAuthorizationAppleIDCredential
    deletionContinuation?.resume(returning: .success(credential?.authorizationCode))
    deletionContinuation = nil
  }

  func authorizationController(controller: ASAuthorizationController,
    didCompleteWithError error: any Error)
  {
    deletionContinuation?.resume(returning: .failure(error))
    deletionContinuation = nil
  }

  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    anchor ?? ASPresentationAnchor()
  }

  private static func isCancellation(_ error: any Error) -> Bool {
    (error as? ASAuthorizationError)?.code == .canceled
  }

  static func digest(_ nonce: String) -> String {
    SHA256.hash(data: Data(nonce.utf8)).map { String(format: "%02x", $0) }.joined()
  }
}
