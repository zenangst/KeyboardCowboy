import Foundation
import Cocoa

class IconController: IconLoader {
  @Published var icon: NSImage?

  public func load(identifier: String, at path: String) {
    icon = IconLoadingController.shared.loadIcon(identifier: identifier, at: path)
  }
}
