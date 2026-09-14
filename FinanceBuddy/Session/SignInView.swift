import AuthenticationServices
import FinanceBuddyCore
import SwiftUI

struct SignInView: View {
  @Bindable var session: SessionStore
  @State private var signingIn = false
  @State private var appleSignIn = AppleSignInFlow()
  private var signInDisabled: Bool {
    signingIn || appleSignIn.signingIn || session.busy || session.client.access.offline
  }
  var body: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(spacing: 28) {
          Image(systemName: "book.closed").font(.largeTitle).foregroundStyle(.tint)
            .accessibilityHidden(true)
          VStack(spacing: 12) {
            Text("Finance Buddy").font(.largeTitle.bold()).fixedSize(
              horizontal: false, vertical: true)
            Text("A little clarity. Every day.").font(.title3).foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)
          }
          VStack(spacing: 12) {
            SignInWithAppleButton(.continue) { request in
              appleSignIn.prepare(request, session: session)
            } onCompletion: { result in
              Task { await appleSignIn.complete(result, session: session) }
            }
            .signInWithAppleButtonStyle(.whiteOutline)
            .frame(maxWidth: 340).frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityIdentifier("appleSignIn")
            .disabled(signInDisabled)
            Button {
              signingIn = true
              session.message = nil
              Task {
                await GoogleSignInFlow.signIn(session: session)
                signingIn = false
              }
            } label: {
              HStack(spacing: 12) {
                Image("GoogleLogo").renderingMode(.original).accessibilityHidden(true)
                Text("Continue with Google").font(.body.weight(.medium)).foregroundStyle(
                  Color.black
                )
                .fixedSize(horizontal: false, vertical: true)
              }.padding(.horizontal, 16).padding(.vertical, 12).frame(maxWidth: 340, minHeight: 44)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
                .overlay { RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1) }
                .contentShape(Rectangle())
            }.buttonStyle(.plain)
              .accessibilityLabel("Continue with Google")
              .frame(minHeight: 50).disabled(signInDisabled)
          }
          if signingIn || appleSignIn.signingIn || session.busy {
            LoadingView(title: "Signing in…")
          }
          if let message = session.message {
            Text(message).foregroundStyle(.secondary).accessibilityIdentifier("signInMessage")
          }
          Text(
            "Use the same verified email to access your journal with either account. Hide My Email creates a separate journal."
          ).font(.footnote).foregroundStyle(
            .secondary)
        }.multilineTextAlignment(.center).padding(32)
          .frame(maxWidth: .infinity, minHeight: geometry.size.height)
      }
    }
  }
}
