import Cocoa

class KeyboardShortcutRecorderViewController: NSObject, ObservableObject, NSSearchFieldDelegate {
  typealias OnCommit = (KeyboardShortcutViewModel?) -> Void
  var onCommit: OnCommit?

  private static var keyMapper = KeyCodeMapper()
  private static var keyIndex = [Int: String]()

  private var eventMonitor: Any?
  private var keyboardShortcutIdentifier: String

  init(identifier: String) {
    self.keyboardShortcutIdentifier = identifier
  }

  func didBecomeFirstResponder() {
    let eventsOfInterest: NSEvent.EventTypeMask = [.keyDown]
    eventMonitor = NSEvent.addLocalMonitorForEvents(matching: eventsOfInterest, handler: { [weak self] e -> NSEvent? in
      guard let self = self else { return nil }
      let modifiers = ModifierKey.fromNSEvent(e.modifierFlags)
      let keyCode = Int(e.keyCode)
      if let character = Self.keyMapper.keyCodeLookup[keyCode] {
        let newViewModel = KeyboardShortcutViewModel(id: self.keyboardShortcutIdentifier,
                                                     index: 0,
                                                     key: character,
                                                     modifiers: modifiers)
        self.onCommit?(newViewModel)
      }

      return e
    })
  }

  func controlTextDidEndEditing(_ obj: Notification) {
    if let eventMonitor = eventMonitor {
      NSEvent.removeMonitor(eventMonitor)
    }
  }
}
