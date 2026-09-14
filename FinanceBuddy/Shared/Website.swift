import SafariServices
import SwiftUI

enum Website {
  static let url = URL(string: "https://financebuddy.tech")!
  static let dashboard = url.appending(path: "dashboard")
}
