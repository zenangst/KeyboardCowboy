import BridgeKit
import Cocoa
import SwiftUI
import ModelKit

class KeyboardShortcutRecorderViewController: NSObject, NSSearchFieldDelegate, TransportControllerReceiver {
  typealias OnCommit = (ModelKit.KeyboardShortcut?) -> Void
  var onCommit: OnCommit?

  private var keyboardShortcut: ModelKit.KeyboardShortcut?

  init(keyboardShortcut: ModelKit.KeyboardShortcut?) {
    self.keyboardShortcut = keyboardShortcut
  }

  func didBecomeFirstResponder() {
    TransportController.shared.receiver = self
    NotificationCenter.default.post(.enableRecordingHotKeys)
  }

  // MARK: TransportControllerReceiver

  func receive(_ keyboardShortcut: ModelKit.KeyboardShortcut) {
    guard let existingKey = self.keyboardShortcut else { return }
    let modifiedKey = ModelKit.KeyboardShortcut(id: existingKey.id,
                                                key: keyboardShortcut.key,
                                                modifiers: keyboardShortcut.modifiers)
    onCommit?(modifiedKey)
  }
}
