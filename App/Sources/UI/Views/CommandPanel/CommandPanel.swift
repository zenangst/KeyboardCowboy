import Cocoa
import SwiftUI

protocol CommandPanelEventDelegate: AnyObject {
  @MainActor
  func shouldConsumeEvent(_ event: NSEvent, for window: NSWindow, runner: CommandPanelRunner) -> Bool
}

final class CommandPanel: NSPanel {
  weak var eventDelegate: CommandPanelEventDelegate?
  var localMonitor: Any?

  init<Content>(identifier: String,
                runner: CommandPanelRunner,
                minSize: CGSize,
                rootView: Content) where Content: View {
    let styleMask: StyleMask = [
      .fullSizeContentView,
      .resizable,
      .closable,
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
    self.identifier = .init("CommandPanel-" + identifier)
    self.becomesKeyOnlyIfNeeded = true
    self.worksWhenModal = true
    self.isFloatingPanel = false
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
      if let eventDelegate, eventDelegate.shouldConsumeEvent(event, for: self, runner: runner) == true {
        return nil
      }
      return event
    })
  }

  override var canBecomeKey: Bool { true }
}
