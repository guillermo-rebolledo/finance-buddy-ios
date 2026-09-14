import FinanceBuddyCore
import SwiftUI

struct SignInView: View {
  @Bindable var session: SessionStore
  @State private var signingIn = false
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
          Button {
            signingIn = true
            Task {
              await GoogleSignInFlow.signIn(session: session)
              signingIn = false
            }
          } label: {
            HStack(spacing: 12) {
              Image("GoogleLogo").renderingMode(.original).accessibilityHidden(true)
              Text("Continue with Google").font(.body.weight(.medium)).foregroundStyle(Color.black)
                .fixedSize(horizontal: false, vertical: true)
            }.padding(.horizontal, 16).padding(.vertical, 12).frame(maxWidth: 340, minHeight: 44)
              .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
              .overlay { RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1) }
              .contentShape(Rectangle())
          }.buttonStyle(.plain)
            .accessibilityLabel("Continue with Google")
            .frame(minHeight: 44).disabled(
              signingIn || session.busy || session.client.access.offline)
          if signingIn || session.busy { LoadingView(title: "Signing in…") }
          if let message = session.message {
            Text(message).foregroundStyle(.secondary).accessibilityIdentifier("signInMessage")
          }
          Text("Access is limited to the workspace owner.").font(.footnote).foregroundStyle(
            .secondary)
        }.multilineTextAlignment(.center).padding(32)
          .frame(maxWidth: .infinity, minHeight: geometry.size.height)
      }
    }
  }
}
