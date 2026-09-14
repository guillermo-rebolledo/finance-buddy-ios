import SwiftUI

struct ToastMessage: Identifiable {
  let id = UUID()
  let text: String
  var isError = false
  var actionTitle: String?
  var action: (@MainActor () -> Void)?
}
