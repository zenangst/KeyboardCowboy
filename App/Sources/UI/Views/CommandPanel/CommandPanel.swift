import Cocoa
import SwiftUI

protocol CommandPanelEventDelegate: AnyObject {
  @MainActor
  func shouldConsumeEvent(_ event: NSEvent, for window: NSWindow, runner: CommandPanelRunner) -> Bool
}

final class CommandPanel: NSPanel {
  weak var eventDelegate: CommandPanelEventDelegate?
  var localMonitor: Any?

  init(identifier: String,
       runner: CommandPanelRunner,
       minSize: CGSize,
       rootView: some View) {
    let styleMask: StyleMask = [
      .fullSizeContentView,
      .resizable,
      .closable,
      .borderless,
      .nonactivatingPanel,
      .unifiedTitleAndToolbar,
    ]

    super.init(contentRect: .init(origin: .zero, size: minSize),
               styleMask: styleMask, backing: .buffered, defer: true)

    self.minSize = minSize
    hasShadow = true
    backgroundColor = .clear
    isOpaque = false
    acceptsMouseMovedEvents = true
    contentViewController = NSHostingController(rootView: rootView)
    self.identifier = .init("CommandPanel-" + identifier)
    becomesKeyOnlyIfNeeded = true
    worksWhenModal = true
    isFloatingPanel = false
    level = .floating
    collectionBehavior.insert(.fullScreenAuxiliary)
    titleVisibility = .hidden
    titlebarAppearsTransparent = true
    isMovableByWindowBackground = true
    isReleasedWhenClosed = false

    standardWindowButton(.closeButton)?.isHidden = true
    standardWindowButton(.miniaturizeButton)?.isHidden = true
    standardWindowButton(.zoomButton)?.isHidden = true

    localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp], handler: { [weak self] event in
      guard let self, isVisible else { return event }

      if let eventDelegate, eventDelegate.shouldConsumeEvent(event, for: self, runner: runner) == true {
        return nil
      }
      return event
    })
  }

  override var canBecomeKey: Bool { true }
}
