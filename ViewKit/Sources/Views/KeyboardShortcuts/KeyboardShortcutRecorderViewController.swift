import BridgeKit
import Cocoa
import SwiftUI
import ModelKit

class KeyboardShortcutRecorderViewController: NSObject, NSSearchFieldDelegate, TransportControllerReceiver {
  typealias OnSuccess = (ModelKit.KeyboardShortcut?) -> Void
  typealias OnFailure = (ModelKit.KeyboardShortcut?) -> Void
  var onSuccess: OnSuccess?
  var onFailure: OnFailure?

  private var keyboardShortcut: ModelKit.KeyboardShortcut?

  init(keyboardShortcut: ModelKit.KeyboardShortcut?) {
    self.keyboardShortcut = keyboardShortcut
  }

  func didBecomeFirstResponder() {
    TransportController.shared.receiver = self
    NotificationCenter.default.post(.enableRecordingHotKeys)
  }

  // MARK: TransportControllerReceiver

  func receive(_ context: KeyboardShortcutValidationContext) {
    guard let existingKey = self.keyboardShortcut else { return }

    switch context {
    case .valid(let keyboardShortcut):
      let modifiedKey = ModelKit.KeyboardShortcut(id: existingKey.id,
                                                  key: keyboardShortcut.key,
                                                  modifiers: keyboardShortcut.modifiers)
      onSuccess?(modifiedKey)
    case .invalid(let keyboardShortcut):
      onFailure?(keyboardShortcut)
    }
  }
}
