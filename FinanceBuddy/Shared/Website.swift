import SafariServices
import SwiftUI

enum Website {
  static let url = URL(string: "https://finance-buddy-self.vercel.app")!
  static let dashboard = url.appending(path: "dashboard")
}
