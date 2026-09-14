import Foundation
import Observation

@MainActor @Observable public final class SessionStore {
  public enum State { case loading, signedOut, signedIn, unavailable }
  public private(set) var state: State = .loading
  public private(set) var user: User?
  public var message: String?
  public private(set) var busy = false
  public let client: any APIClient
  public init(client: any APIClient) { self.client = client }
  public func restore() async {
    guard !client.access.upgradeRequired else { return }
    busy = true
    defer { busy = false }
    do {
      if let reply = try await client.session() {
        user = reply.user
        state = .signedIn
        client.access.signedOut = false
        message = nil
      } else {
        user = nil
        state = .signedOut
      }
    } catch let refusal as Refusal
      where refusal.code == .unauthenticated || refusal.code == .forbidden
    {
      didLoseSession()
    } catch {
      message = error.localizedDescription
      state = .unavailable
    }
  }
  public func authenticate(provider: SignInProvider, idToken: String, nonce: String) async {
    guard !busy else { return }
    busy = true
    message = nil
    do {
      try await client.signIn(provider: provider, idToken: idToken, nonce: nonce)
      busy = false
      await restore()
    } catch {
      busy = false
      message = error.localizedDescription
      state = .signedOut
    }
  }
  public func didLoseSession() {
    user = nil
    state = .signedOut
    message = "You were signed out. Sign in again to continue."
  }
  public func signOut(everywhere: Bool) async {
    guard !busy else { return }
    busy = true
    defer { busy = false }
    do {
      try await client.signOut(everywhere: everywhere)
      message = nil
    } catch {
      message =
        everywhere
        ? "This phone is signed out. Sign-out on other devices could not be confirmed. Use the website to try again."
        : nil
    }
    do { try client.clearToken() } catch { message = error.localizedDescription }
    user = nil
    state = .signedOut
  }
}
