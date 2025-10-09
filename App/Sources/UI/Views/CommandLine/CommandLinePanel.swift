import Cocoa
import SwiftUI

protocol CommandLineWindowEventDelegate: AnyObject {
  @MainActor
  func shouldConsumeEvent(_ event: NSEvent) -> Bool
}

final class CommandLinePanel: NSPanel {
  weak var eventDelegate: CommandLineWindowEventDelegate?
  var localMonitor: Any?

  init(_ minSize: CGSize, rootView: some View) {
    let styleMask: StyleMask = [
      .fullSizeContentView,
      .resizable,
      .borderless,
      .nonactivatingPanel,
      .unifiedTitleAndToolbar,
      .closable,
    ]

    super.init(contentRect: .init(origin: .zero, size: minSize),
               styleMask: styleMask, backing: .buffered, defer: true)

    self.minSize = minSize
    hasShadow = true
    backgroundColor = .clear
    isOpaque = false
    acceptsMouseMovedEvents = true
    contentViewController = NSHostingController(rootView: rootView)
    identifier = .init("CommandLinePanel")
    becomesKeyOnlyIfNeeded = true
    worksWhenModal = true
    isFloatingPanel = true
    level = .floating
    collectionBehavior.insert(.fullScreenAuxiliary)
    titleVisibility = .hidden
    titlebarAppearsTransparent = true
    isMovableByWindowBackground = true
    isReleasedWhenClosed = false

    standardWindowButton(.closeButton)?.isHidden = true
    standardWindowButton(.miniaturizeButton)?.isHidden = true
    standardWindowButton(.zoomButton)?.isHidden = true

    localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged], handler: { [weak self] event in
      guard let self, isVisible else { return event }

      if let eventDelegate, eventDelegate.shouldConsumeEvent(event) == true {
        return nil
      }
      return event
    })
  }

  override var canBecomeKey: Bool { true }
}
