import Cocoa
import SwiftUI

protocol CommandLineWindowEventDelegate: AnyObject {
  @MainActor
  func shouldConsumeEvent(_ event: NSEvent) -> Bool
}

final class CommandLinePanel: NSPanel {
  weak var eventDelegate: CommandLineWindowEventDelegate?
  var localMonitor: Any?

  init<Content>(_ minSize: CGSize, rootView: Content) where Content: View {
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
    self.identifier = .init("CommandLinePanel")
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


    self.localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp], handler: { [weak self] event in
      guard let self, isVisible else { return event }
      if let eventDelegate, eventDelegate.shouldConsumeEvent(event) == true {
        return nil
      }
      return event
    })
  }

  override var canBecomeKey: Bool { true }
}
