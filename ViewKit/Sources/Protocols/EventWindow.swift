import Cocoa
import Combine

public protocol EventWindow: NSWindow {
  var keyEventPublisher: AnyPublisher<NSEvent, Never> { get }
}
