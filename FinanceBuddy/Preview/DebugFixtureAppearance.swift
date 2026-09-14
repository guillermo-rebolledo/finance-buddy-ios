#if DEBUG
  import SwiftUI
  struct DebugFixtureAppearance: ViewModifier {
    @Environment(\.dynamicTypeSize) private var size
    private var arguments: [String] { ProcessInfo.processInfo.arguments }
    func body(content: Content) -> some View {
      content
        .dynamicTypeSize(
          arguments.contains("-useFakeAPI") && arguments.contains("-largestType")
            ? .accessibility5 : size
        )
        .preferredColorScheme(
          arguments.contains("-useFakeAPI")
            ? arguments.contains("-light") ? .light : arguments.contains("-dark") ? .dark : nil
            : nil)
    }
  }
#endif
