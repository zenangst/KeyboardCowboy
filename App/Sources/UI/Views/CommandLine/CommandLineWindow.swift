import Cocoa
import SwiftUI

protocol CommandLineWindowEventDelegate: AnyObject {
  @MainActor
  func shouldConsumeEvent(_ event: NSEvent) -> Bool
}

final class CommandLineWindow: NSWindow {
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
    self.hasShadow = false
    self.level = .modalPanel
    self.backgroundColor = .clear
    self.isOpaque = false
    self.isMovableByWindowBackground = true
    self.acceptsMouseMovedEvents = true
    self.contentViewController = NSHostingController(rootView: rootView)
    self.identifier = .init("CommandLineWindow")

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
