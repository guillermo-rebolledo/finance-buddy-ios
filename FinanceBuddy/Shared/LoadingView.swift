import SwiftUI

struct LoadingView: View {
  let title: String

  var body: some View {
    ProgressView {
      Text(title)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }
    .progressViewStyle(.circular)
    .frame(maxWidth: .infinity, alignment: .center)
    .padding(.vertical, 12)
  }
}

extension View {
  /// Animates placeholders turning into content and rows arriving, unless Reduce Motion is on.
  func smoothChanges(_ value: some Equatable) -> some View { modifier(SmoothChanges(value: value)) }
}

private struct SmoothChanges<Value: Equatable>: ViewModifier {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let value: Value
  func body(content: Content) -> some View {
    content.animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: value)
  }
}

#Preview("Loading – light") {
  List { LoadingView(title: "Loading categories…") }
    .preferredColorScheme(.light)
}

#Preview("Loading – dark") {
  List { LoadingView(title: "Loading categories…") }
    .preferredColorScheme(.dark)
}

#Preview("Loading – accessibility") {
  List { LoadingView(title: "Creating spreadsheet…") }
    .environment(\.dynamicTypeSize, .accessibility5)
}
