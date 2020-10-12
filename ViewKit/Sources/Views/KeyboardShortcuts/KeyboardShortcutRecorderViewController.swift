import Cocoa
import SwiftUI

class KeyboardShortcutRecorderViewController: NSObject, ObservableObject, NSSearchFieldDelegate {
  typealias OnCommit = (KeyboardShortcutViewModel?) -> Void
  var onCommit: OnCommit?

  private static var keyMapper = KeyCodeMapper()
  private static var keyIndex = [Int: String]()

  private var eventMonitor: Any?
  private var keyboardShortcut: KeyboardShortcutViewModel?

  init(keyboardShortcut: KeyboardShortcutViewModel?) {
    self.keyboardShortcut = keyboardShortcut
  }

  func didBecomeFirstResponder() {
    let eventsOfInterest: NSEvent.EventTypeMask = [.keyDown]
    eventMonitor = NSEvent.addLocalMonitorForEvents(matching: eventsOfInterest, handler: { [weak self] e -> NSEvent? in
      guard let self = self else { return nil }
      let modifiers = ModifierKey.fromNSEvent(e.modifierFlags)
      let keyCode = Int(e.keyCode)

      if var character = Self.keyMapper.keyCodeLookup[keyCode] {

        let specialKeys: [NSEvent.SpecialKey] = [.delete, .deleteForward, .backspace]
        if let specialKey = e.specialKey, specialKeys.contains(specialKey) {
          character = ""
        }

        let keyboardShortcut = KeyboardShortcutViewModel(id: self.keyboardShortcut?.id ?? UUID().uuidString,
                                                         index: self.keyboardShortcut?.index ?? 0,
                                                         key: character, modifiers: modifiers)
        self.onCommit?(keyboardShortcut)
        return nil
      }

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
