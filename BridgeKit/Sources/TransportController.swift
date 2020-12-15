import Foundation
import ModelKit

public protocol TransportControllerReceiver: AnyObject {
  func receive(_ keyboardShortcut: ModelKit.KeyboardShortcut)
}

public class TransportController {
  public weak var receiver: TransportControllerReceiver?
  public static var shared = TransportController()

  init() {}

  public func send(_ keyboardShortcut: ModelKit.KeyboardShortcut) {
    receiver?.receive(keyboardShortcut)
  }
}
