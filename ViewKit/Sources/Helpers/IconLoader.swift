import Cocoa
import SwiftUI

class IconLoader: ObservableObject {
  @Published public private(set) var image: Image?

  func load(_ path: String) {
    image = Image(nsImage: NSWorkspace.shared.icon(forFile: path))
  }

  func cancel() {
    image = nil
  }

  deinit {
    cancel()
  }
}
