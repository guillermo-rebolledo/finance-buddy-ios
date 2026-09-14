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
}
