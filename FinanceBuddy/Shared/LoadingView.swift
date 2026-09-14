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
