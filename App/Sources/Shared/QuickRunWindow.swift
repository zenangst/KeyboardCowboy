import Cocoa
import Combine
import ViewKit

class QuickRunWindow: NSWindow, EventWindow {
  private let publisher = PassthroughSubject<NSEvent, Never>()
  var keyEventPublisher: AnyPublisher<NSEvent, Never> {
    publisher.eraseToAnyPublisher()
  }

  required init(contentRect: CGRect) {
    super.init(contentRect: contentRect,
               styleMask: [.resizable, .titled, .closable, .miniaturizable, .fullSizeContentView],
               backing: .buffered,
               defer: false)
    collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
    level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.maximumWindow)))
    titlebarAppearsTransparent = true
    titleVisibility = .hidden
    standardWindowButton(.closeButton)?.isHidden = true
    standardWindowButton(.zoomButton)?.isHidden = true
    standardWindowButton(.miniaturizeButton)?.isHidden = true
  }

  override func keyUp(with event: NSEvent) {
    publisher.send(event)
  }
}
