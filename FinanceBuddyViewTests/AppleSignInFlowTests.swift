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

@MainActor struct AppleDeletionFlowTests {
  @Test func authorizationCodeIsForwardedExactly() async {
    let api = FakeAPIClient()
    api.requiresAppleAuthorization = true
    let session = SessionStore(client: api)
    await session.restore()
    let flow = AppleSignInFlow()
    let request = ASAuthorizationAppleIDProvider().createRequest()
    flow.prepareDeletion(request, session: session)
    #expect(request.requestedScopes == [])
    #expect(request.nonce == nil)
    await flow.completeDeletion(.success(Data("one-time-code".utf8)), session: session)
    #expect(api.accountDeletionRequests == ["one-time-code"])
    #expect(session.state == .signedOut)
    #expect(flow.signingIn == false)
  }

  @Test func cancellationKeepsAccountWithoutMessage() async {
    let api = FakeAPIClient()
    let session = SessionStore(client: api)
    await session.restore()
    let flow = AppleSignInFlow()
    flow.prepareDeletion(ASAuthorizationAppleIDProvider().createRequest(), session: session)
    await flow.completeDeletion(.failure(ASAuthorizationError(.canceled)), session: session)
    #expect(api.accountDeletionRequests.isEmpty)
    #expect(session.state == .signedIn)
    #expect(session.message == nil)
    #expect(session.appleAuthorizationRequired == false)
    #expect(flow.signingIn == false)
  }

  @Test(arguments: [nil, Data(), Data([0xff])] as [Data?])
  func missingOrInvalidCodeDoesNotDelete(data: Data?) async {
    let api = FakeAPIClient()
    let session = SessionStore(client: api)
    await session.restore()
    await AppleSignInFlow().completeDeletion(.success(data), session: session)
    #expect(api.accountDeletionRequests.isEmpty)
    #expect(session.state == .signedIn)
    #expect(session.message == SessionStore.deletionFailureMessage)
  }

  @Test func authorizationFailureDoesNotDelete() async {
    let api = FakeAPIClient()
    let session = SessionStore(client: api)
    await session.restore()
    await AppleSignInFlow().completeDeletion(.failure(ASAuthorizationError(.failed)), session: session)
    #expect(api.accountDeletionRequests.isEmpty)
    #expect(session.state == .signedIn)
    #expect(session.message == SessionStore.deletionFailureMessage)
  }
}
