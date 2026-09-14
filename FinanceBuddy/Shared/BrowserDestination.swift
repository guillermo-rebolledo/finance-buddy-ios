import SafariServices
import SwiftUI

struct BrowserDestination: Identifiable {
  let url: URL
  var id: URL { url }
}
