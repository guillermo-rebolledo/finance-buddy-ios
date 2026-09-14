import SwiftUI

struct ToastModifier: ViewModifier {
  @Binding var message: ToastMessage?
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver

  func body(content: Content) -> some View {
    content.overlay(alignment: .bottom) {
      if let message {
        HStack(alignment: .top, spacing: 12) {
          Image(systemName: message.isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
            .foregroundStyle(message.isError ? Color.orange : Color.green)
            .padding(.top, 12)
            .accessibilityHidden(true)
          VStack(alignment: .leading, spacing: 4) {
            Text(message.text)
              .fixedSize(horizontal: false, vertical: true)
              .padding(.top, 10)
            if let title = message.actionTitle, let action = message.action {
              Button(title) {
                self.message = nil
                action()
              }.foregroundStyle(.tint).frame(minHeight: 44)
            }
          }.frame(maxWidth: .infinity, alignment: .leading)
          Button {
            self.message = nil
          } label: {
            Image(systemName: "xmark").frame(width: 44, height: 44)
          }
          .accessibilityLabel("Dismiss notification")
          .foregroundStyle(.secondary)
        }
        .font(.callout)
        .foregroundStyle(.primary)
        .buttonStyle(.borderless)
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
          RoundedRectangle(cornerRadius: 20).stroke(.primary.opacity(0.1), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
        .padding(16)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("toast")
        .id(message.id)
        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
        .task(id: message.id) {
          AccessibilityNotification.Announcement(message.text).post()
          guard !message.isError, message.action == nil, !voiceOver else { return }
          do { try await Task.sleep(for: .seconds(5)) } catch { return }
          if self.message?.id == message.id { self.message = nil }
        }
      }
    }
    .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: message?.id)
  }
}

extension View {
  func toast(_ message: Binding<ToastMessage?>) -> some View {
    modifier(ToastModifier(message: message))
  }
}
