import Cocoa
import SwiftUI

class SnapshotWindow<Content>: NSWindow where Content: View {
  let viewController: NSViewController

  init(_ view: Content, size: CGSize) {
    let viewController = NSHostingController(rootView: view)
    viewController.view.wantsLayer = true
    viewController.view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    self.viewController = viewController
    super.init(contentRect: .zero,
               styleMask: [.closable, .miniaturizable, .resizable],
               backing: .buffered, defer: false)
    self.contentViewController = viewController
    setFrame(.init(origin: .zero, size: size), display: true)
  }
}
