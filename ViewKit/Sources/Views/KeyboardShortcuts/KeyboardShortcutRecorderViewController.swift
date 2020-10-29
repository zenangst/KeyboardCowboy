import Cocoa
import SwiftUI
import ModelKit

class KeyboardShortcutRecorderViewController: NSObject, ObservableObject, NSSearchFieldDelegate {
  typealias OnCommit = (ModelKit.KeyboardShortcut?) -> Void
  var onCommit: OnCommit?

  private static var keyMapper = KeyCodeMapper()
  private static var keyIndex = [Int: String]()

  private var eventMonitor: Any?
  private var keyboardShortcut: ModelKit.KeyboardShortcut?

  init(keyboardShortcut: ModelKit.KeyboardShortcut?) {
    self.keyboardShortcut = keyboardShortcut
  }

  func didBecomeFirstResponder() {
    let eventsOfInterest: NSEvent.EventTypeMask = [.keyUp, .flagsChanged]
    eventMonitor = NSEvent.addLocalMonitorForEvents(matching: eventsOfInterest, handler: { [weak self] e -> NSEvent? in
      guard let self = self else { return e }
      let modifiers = ModifierKey.fromNSEvent(e.modifierFlags)
      let keyCode = Int(e.keyCode)
      let specialKeys: [NSEvent.SpecialKey] = [.delete, .deleteForward, .backspace]
      let character = Self.keyMapper.keyCodeLookup[keyCode] ?? ""

      if let specialKey = e.specialKey, specialKeys.contains(specialKey) {
        return nil
      }

      let keyboardShortcut = KeyboardShortcut(id: self.keyboardShortcut?.id ?? UUID().uuidString,
                                              key: character, modifiers: modifiers)

      self.onCommit?(keyboardShortcut)

      return e
    })
  }

  func removeMonitorIfNeeded() {
    if let eventMonitor = eventMonitor {
      NSEvent.removeMonitor(eventMonitor)
    }
  }

  func controlTextDidEndEditing(_ obj: Notification) {
    removeMonitorIfNeeded()
  }
}
