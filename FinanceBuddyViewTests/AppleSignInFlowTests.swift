import AuthenticationServices
import FinanceBuddyCore
import Testing

@MainActor struct AppleSignInFlowTests {
  @Test func nonceDigestMatchesBackendSHA256Contract() {
    #expect(
      AppleSignInFlow.digest("abc")
        == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
  }

  @Test func cancellationAllowsRetryWithFreshNonce() async {
    let session = SessionStore(client: FakeAPIClient())
    let flow = AppleSignInFlow()
    let first = ASAuthorizationAppleIDProvider().createRequest()
    session.message = "Previous failure"
    flow.prepare(first, session: session)
    #expect(first.requestedScopes == [.email])
    #expect(first.nonce?.count == 64)
    #expect(flow.signingIn)
    #expect(session.message == nil)
    await flow.complete(.failure(ASAuthorizationError(.canceled)), session: session)
    #expect(!flow.signingIn)
    #expect(session.message == nil)
    let retry = ASAuthorizationAppleIDProvider().createRequest()
    flow.prepare(retry, session: session)
    #expect(retry.nonce != first.nonce)
    await flow.complete(.failure(ASAuthorizationError(.failed)), session: session)
    #expect(!flow.signingIn)
    #expect(session.message == Refusal.signInMessage)
  }
}
