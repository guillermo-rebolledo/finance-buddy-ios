import Foundation
import Testing

@testable import FinanceBuddyCore

@MainActor struct SessionTests {
  @Test func restoresSessionAndSignsOut() async {
    let api = FakeAPIClient()
    let store = SessionStore(client: api)
    await store.restore()
    #expect(store.state == .signedIn)
    #expect(store.user?.email == "owner@example.com")
    await store.signOut(everywhere: false)
    #expect(store.state == .signedOut)
    #expect(store.user == nil)
    await store.restore()
    #expect(store.state == .signedOut)
  }
  @Test func nonceUsesFreshRandomBytes() throws {
    let first = try SignInNonce.make()
    let second = try SignInNonce.make()
    #expect(first.count == 64)
    #expect(first != second)
    #expect(first.allSatisfy { $0.isHexDigit })
  }

  @Test(arguments: SignInProvider.allCases)
  func providerSignInRestoresServerSession(provider: SignInProvider) async {
    let (client, tokens) = ClientTests().makeClient(token: nil) { request in
      if request.url?.path == "/api/auth/sign-in/social" {
        let object =
          (try? JSONSerialization.jsonObject(with: StubProtocol.body(request)))
          as? [String: Any]
        #expect(object?["provider"] as? String == provider.rawValue)
        #expect(
          object?["idToken"] as? [String: String] == ["token": "identity", "nonce": "original"])
        return (200, ["set-auth-token": "signed-session"], Data(#"{"token":"unsigned"}"#.utf8))
      }
      #expect(request.url?.path == "/api/auth/get-session")
      #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer signed-session")
      return (200, [:], try! JSONEncoder().encode(Fixtures.session))
    }
    let store = SessionStore(client: client)
    await store.authenticate(provider: provider, idToken: "identity", nonce: "original")
    #expect(store.state == .signedIn)
    #expect(store.user?.id == Fixtures.session.user.id)
    #expect(store.user?.email == Fixtures.session.user.email)
    #expect(!store.busy)
    #expect(store.message == nil)
    #expect(tokens.token == "signed-session")
  }

  @Test(arguments: [401, 503])
  func appleRefusalLeavesSignInAvailable(status: Int) async {
    let (client, tokens) = ClientTests().makeClient(token: nil) { _ in
      (status, [:], Data(#"{"error":"Provider rejected the token"}"#.utf8))
    }
    let store = SessionStore(client: client)
    await store.authenticate(provider: .apple, idToken: "rejected", nonce: "original")
    #expect(store.state == .signedOut)
    #expect(store.user == nil)
    #expect(!store.busy)
    #expect(store.message != nil)
    #expect(tokens.token == nil)
  }
}
