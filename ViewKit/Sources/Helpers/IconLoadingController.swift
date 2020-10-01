import Foundation
import Cocoa

public class IconLoadingController {
  let cache = NSCache<NSString, NSImage>()
  private(set) public static var shared: IconLoadingController = IconLoadingController(workspace: NSWorkspace.shared)
  private let workspace: NSWorkspace

  private init(workspace: NSWorkspace) {
    self.workspace = workspace
  }

  public func loadIcon(identifier: String, at path: String) -> NSImage {
    if let image = cache.object(forKey: identifier as NSString) {
      return image
    }

    let image = workspace.icon(forFile: path)
    cache.setObject(image, forKey: identifier as NSString)
    return image
  }
}
