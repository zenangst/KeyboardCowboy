import Foundation
import ModelKit

public protocol TransportControllerReceiver: AnyObject {
  func receive(_ context: KeyboardShortcutValidationContext)
}

public enum KeyboardShortcutValidationContext {
  case valid(ModelKit.KeyboardShortcut)
  case invalid(ModelKit.KeyboardShortcut)
}

public class TransportController {
  public weak var receiver: TransportControllerReceiver?
  public static var shared = TransportController()

  init() {}

  public func send(_ context: KeyboardShortcutValidationContext) {
    receiver?.receive(context)
  }
}
