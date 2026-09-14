#if DEBUG
  import SwiftUI
  struct DebugFixtureAppearance: ViewModifier {
    private var arguments: [String] { ProcessInfo.processInfo.arguments }
    func body(content: Content) -> some View {
      content
        .transformEnvironment(\.dynamicTypeSize) { size in
          if arguments.contains("-useFakeAPI") && arguments.contains("-largestType") {
            size = .accessibility5
          }
        }
        .preferredColorScheme(
          arguments.contains("-useFakeAPI")
            ? arguments.contains("-light") ? .light : arguments.contains("-dark") ? .dark : nil
            : nil)
    }
  }
#endif
