import Cocoa
import SwiftUI

final class CommandPanel: NSPanel {
  init<Content>(identifier: String,
                minSize: CGSize,
                rootView: Content) where Content: View {
    let styleMask: StyleMask = [
      .fullSizeContentView,
      .resizable,
      .borderless,
      .nonactivatingPanel,
      .unifiedTitleAndToolbar
    ]

    super.init(contentRect: .init(origin: .zero, size: minSize),
               styleMask: styleMask, backing: .buffered, defer: true)

    self.minSize = minSize
    self.hasShadow = true
    self.backgroundColor = .clear
    self.isOpaque = false
    self.acceptsMouseMovedEvents = true
    self.contentViewController = NSHostingController(rootView: rootView)
    self.identifier = .init("CommandLineWindow-" + identifier)
    self.becomesKeyOnlyIfNeeded = true
    self.worksWhenModal = true
    self.isFloatingPanel = true
    self.level = .floating
    self.collectionBehavior.insert(.fullScreenAuxiliary)
    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true
    self.isMovableByWindowBackground = true
    self.isReleasedWhenClosed = false

    self.standardWindowButton(.closeButton)?.isHidden = true
    self.standardWindowButton(.miniaturizeButton)?.isHidden = true
    self.standardWindowButton(.zoomButton)?.isHidden = true
  }

  override var canBecomeKey: Bool { true }
}
