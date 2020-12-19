import Combine
import Foundation
import ModelKit

public protocol TransportControllerReceiver: AnyObject {
  func receive(_ context: KeyboardShortcutUpdateContext)
}

public enum KeyboardShortcutUpdateContext {
  case valid(ModelKit.KeyboardShortcut)
  case systemShortcut(ModelKit.KeyboardShortcut)
  case delete(ModelKit.KeyboardShortcut)
  case cancel(ModelKit.KeyboardShortcut)
}

public class TransportController: ObservableObject {
  public weak var receiver: TransportControllerReceiver?
  public static var shared = TransportController()

  init() {}

  public func send(_ context: KeyboardShortcutUpdateContext) {
    receiver?.receive(context)
  }
}
