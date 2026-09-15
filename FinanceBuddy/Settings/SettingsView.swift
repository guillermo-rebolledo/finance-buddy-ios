import FinanceBuddyCore
import GoogleSignIn
import SwiftUI

struct SettingsView: View {
  @Bindable var session: SessionStore
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @State private var appleSignIn = AppleSignInFlow()
  @State private var confirmEverywhere = false
  @State private var confirmDeletion = false
  @State private var deletionConfirmed = false
  @State private var browser: BrowserDestination?
  var body: some View {
    Form {
      Section("Account") {
        if let user = session.user {
          LabeledContent("Name", value: user.name)
          LabeledContent("Email", value: user.email).textSelection(.enabled)
        }
      }
      Section("Sessions") {
        Button("Sign Out", role: .destructive) {
          Task {
            await session.signOut(everywhere: false)
            GIDSignIn.sharedInstance.signOut()
          }
        }.disabled(session.busy || appleSignIn.signingIn)
        Button("Sign Out Everywhere", role: .destructive) { confirmEverywhere = true }.disabled(
          session.busy || appleSignIn.signingIn || session.client.access.offline)
      }
      Section("About") {
        LabeledContent(
          "Version",
          value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "1.0")
        LabeledContent(
          "Build",
          value: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1")
        Button {
          browser = BrowserDestination(url: Website.url)
        } label: {
          Label {
            Text("Finance Buddy website").fixedSize(horizontal: false, vertical: true)
          } icon: {
            Image(systemName: "arrow.up.right.square")
          }
          .labelStyle(.titleAndIcon)
        }
        Text(
          "A private personal finance journal. Recorded activity in MXN, using Mexico City calendar dates."
        ).font(.footnote).foregroundStyle(.secondary)
      }
      Section("Legal & Support") {
        Button { browser = BrowserDestination(url: Website.privacy) } label: {
          Text("Privacy Policy").fixedSize(horizontal: false, vertical: true)
            .frame(minHeight: 44)
        }.accessibilityIdentifier("privacyPolicy")
        Button { browser = BrowserDestination(url: Website.support) } label: {
          Text("Support").fixedSize(horizontal: false, vertical: true)
            .frame(minHeight: 44)
        }.accessibilityIdentifier("support")
      }
      Section("Delete Account") {
        Button("Delete Account", role: .destructive) { confirmDeletion = true }
          .frame(minHeight: 44)
          .disabled(session.busy || appleSignIn.signingIn || session.client.access.offline)
          .accessibilityIdentifier("deleteAccount")
        if let message = session.message {
          Text(message).fixedSize(horizontal: false, vertical: true)
            .task(id: message) { AccessibilityNotification.Announcement(message).post() }
        }
      }
    }.navigationTitle("Settings")
      .confirmationDialog(
        "Sign out everywhere?", isPresented: $confirmEverywhere, titleVisibility: .visible
      ) {
        Button("Sign Out Everywhere", role: .destructive) {
          Task {
            await session.signOut(everywhere: true)
            GIDSignIn.sharedInstance.signOut()
          }
        }
        Button("Keep Sessions", role: .cancel) {}
      } message: {
        Text(
          "Every session ends, including this phone and any browser signed in to Finance Buddy. Each device has to sign in again. Your journal is unchanged."
        )
      }
      .sheet(isPresented: $confirmDeletion, onDismiss: {
        guard deletionConfirmed else { return }
        deletionConfirmed = false
        Task {
          await session.deleteAccount()
          if session.appleAuthorizationRequired {
            await appleSignIn.authorizeDeletion(session: session)
          }
          if session.state == .signedOut { GIDSignIn.sharedInstance.signOut() }
        }
      }) {
        DeleteAccountView(disabled: session.busy || appleSignIn.signingIn || session.client.access.offline) {
          deletionConfirmed = true
          confirmDeletion = false
        }.dynamicTypeSize(dynamicTypeSize)
      }
      .sheet(item: $browser) { SafariView(url: $0.url) }
  }
}
