import Cocoa

class FloatingWindow: NSWindow {
  required init(contentRect: CGRect) {
    super.init(contentRect: contentRect,
               styleMask: [.borderless],
               backing: .buffered,
               defer: false)
    collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
    level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.maximumWindow)))
    backgroundColor = .clear
  }
}
