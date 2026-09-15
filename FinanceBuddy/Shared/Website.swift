import SafariServices
import SwiftUI

enum Website {
  static let url = URL(string: "https://financebuddy.tech")!
  static let privacy = url.appending(path: "privacy")
  static let support = url.appending(path: "support")
  static let dashboard = url.appending(path: "dashboard")
}
