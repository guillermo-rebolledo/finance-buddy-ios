import FinanceBuddyCore
import GoogleSignIn
import SwiftUI

@MainActor enum GoogleSignInFlow {
  static func signIn(session: SessionStore) async {
    guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
      let serverID = Bundle.main.object(forInfoDictionaryKey: "GIDServerClientID") as? String,
      clientID.hasSuffix(".apps.googleusercontent.com"),
      serverID.hasSuffix(".apps.googleusercontent.com"),
      clientID.first?.isNumber == true, serverID.first?.isNumber == true
    else {
      session.message = "Sign-in is not configured for this app build."
      return
    }
    guard
      let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first(
        where: { $0.activationState == .foregroundActive }),
      var controller = scene.windows.first(where: \.isKeyWindow)?.rootViewController
    else { return }
    while let presented = controller.presentedViewController { controller = presented }
    do {
      let nonce = try SignInNonce.make()
      GIDSignIn.sharedInstance.configuration = GIDConfiguration(
        clientID: clientID, serverClientID: serverID)
      // GoogleSignIn 10.0.0: signIn(withPresenting:hint:additionalScopes:nonce:) async throws.
      let result = try await GIDSignIn.sharedInstance.signIn(
        withPresenting: controller, hint: nil, additionalScopes: nil, nonce: nonce)
      guard let token = result.user.idToken?.tokenString else {
        throw ClientError.missingSignedToken
      }
      await session.authenticate(provider: .google, idToken: token, nonce: nonce)
      if session.state != .signedIn { GIDSignIn.sharedInstance.signOut() }
    } catch { session.message = Refusal.signInMessage }
  }
}
