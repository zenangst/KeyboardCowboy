import Cocoa
import MachPort

final class ModifierTriggerMachPortCoordinator: Sendable {
  fileprivate nonisolated(unsafe) static var debug: Bool = false
  private let functionKeyRemap: [Int64: Int64] = [
    // Arrow Keys
    126: 116, // Up Arrow -> Page Up
    125: 121, // Down Arrow -> Page Down
    124: 119, // Right Arrow -> End
    123: 115, // Left Arrow -> Home

    // Enter/Return Key
    36: 76, // Return -> Keypad Enter

    // Function Keys (F1–F12)
    145: 122, // Brightness Down -> F1
    144: 120, // Brightness Up -> F2
    160: 99, // Mission Control -> F3
    131: 118, // Launchpad -> F4
    153: 96, // Keyboard Light ↓ -> F5
    150: 97, // Keyboard Light ↑ -> F6
    114: 98, // Previous Track -> F7
    176: 100, // Play/Pause -> F8
    115: 101, // Next Track -> F9
    113: 109, // Mute -> F10
    111: 103, // Volume Down -> F11
    110: 111, // Volume Up -> F12

    // Delete/Backspace
    51: 117, // Delete -> Forward Delete

    // Escape Key
    53: 126, // Escape -> Special Fn Behavior (if applicable, can vary)

    // Numeric Keypad Emulation
    82: 92, // Keypad 0
    83: 93, // Keypad 1
    84: 94, // Keypad 2
    85: 95, // Keypad 3
    86: 96, // Keypad 4
    87: 97, // Keypad 5
    88: 98, // Keypad 6
    89: 99, // Keypad 7
    90: 100, // Keypad 8
    91: 101, // Keypad 9

    // Other Keys (Power, Eject, etc.)
    96: 0, // Power Key (mapped to system behavior)
    71: 0, // Eject Key (mapped to system behavior)
  ]
  private let machPort: MachPortEventController

  init(machPort: MachPortEventController) {
    self.machPort = machPort
  }

  @discardableResult
  func set(_ key: KeyShortcut, on machPortEvent: MachPortEvent) -> Self {
    machPortEvent.event.setIntegerValueField(.keyboardEventKeycode, value: Int64(key.keyCode!))
    debugModifier("\(key) on \(machPortEvent.keyCode)")
    return self
  }

  @discardableResult
  func decorateEvent(_ machPortEvent: MachPortEvent, with modifiers: [ModifierKey]) -> Self {
    var cgEventFlags = CGEventFlags()
    for modifier in modifiers {
      machPortEvent.event.flags.insert(modifier.cgEventFlags)
      machPortEvent.result?.takeUnretainedValue().flags.insert(modifier.cgEventFlags)
      cgEventFlags.insert(modifier.cgEventFlags)
    }

    if machPortEvent.event.flags.contains(.maskSecondaryFn) {
      let keyCode: Int64
      // Remap using the functionKeyRemap dictionary
      if let remappedKeyCode = functionKeyRemap[machPortEvent.keyCode] {
        machPortEvent.event.setIntegerValueField(.keyboardEventKeycode, value: remappedKeyCode)
        machPortEvent.result?.takeUnretainedValue().setIntegerValueField(.keyboardEventKeycode, value: remappedKeyCode)
        keyCode = remappedKeyCode
      } else {
        keyCode = machPortEvent.keyCode
      }

      if SpecialKeys.numericPadKeys.contains(Int(keyCode)) {
        machPortEvent.event.flags.insert(.maskNumericPad)
        machPortEvent.result?.takeUnretainedValue().flags.insert(.maskNumericPad)
      }
    }

    debugModifier("\(machPortEvent.keyCode)")
    return self
  }

  @discardableResult
  func discardSystemEvent(on machPortEvent: MachPortEvent) -> Self {
    machPortEvent.result = nil
    debugModifier("")
    return self
  }

  @discardableResult
  func post(_ key: KeyShortcut) -> Self {
    _ = try? machPort.post(key.keyCode!, type: .keyDown, flags: .maskNonCoalesced)
    _ = try? machPort.post(key.keyCode!, type: .keyUp, flags: .maskNonCoalesced)
    debugModifier("")
    return self
  }

  @discardableResult
  func postKeyDown(_ key: KeyShortcut) -> Self {
    _ = try? machPort.post(key.keyCode!, type: .keyUp, flags: .maskNonCoalesced)
    debugModifier("")
    return self
  }

  @discardableResult
  func postKeyUp(_ key: KeyShortcut) -> Self {
    _ = try? machPort.post(key.keyCode!, type: .keyUp, flags: .maskNonCoalesced)
    debugModifier("")
    return self
  }

  @discardableResult
  func post(_ key: KeyShortcut, modifiers: [ModifierKey], flags: CGEventFlags? = nil) -> Self {
    var flags = flags ?? CGEventFlags.maskNonCoalesced
    for modifier in modifiers {
      flags.insert(modifier.cgEventFlags)
    }

    _ = try? machPort.post(key.keyCode!, type: .flagsChanged, flags: flags)
    return self
  }

  @discardableResult
  func post(_ machPortEvent: MachPortEvent) -> Self {
    machPort.repost(machPortEvent)
    return self
  }

  @discardableResult
  func postFlagsChanged(modifiers: [ModifierKey]) -> Self {
    var flags = CGEventFlags.maskNonCoalesced
    for modifier in modifiers {
      flags.insert(modifier.cgEventFlags)
    }

    guard let firstModifier = modifiers.first else {
      return self
    }

    _ = try? machPort.post(firstModifier.key, type: .flagsChanged, flags: flags)
    return self
  }

  @discardableResult
  func postMaskNonCoalesced() -> Self {
    _ = try? machPort.post(.maskNonCoalesced)
    debugModifier("")
    return self
  }

  @discardableResult
  func setMaskNonCoalesced(on machPortEvent: MachPortEvent) -> Self {
    machPortEvent.event.flags = .maskNonCoalesced
    machPortEvent.result?.takeUnretainedValue().flags = .maskNonCoalesced
    debugModifier("\(machPortEvent.keyCode)")
    return self
  }
}

private func debugModifier(_ handler: @autoclosure @escaping () -> String, function: StaticString = #function, line: UInt = #line) {
  guard ModifierTriggerMachPortCoordinator.debug else { return }

  let dateFormatter = DateFormatter()
  dateFormatter.dateStyle = .short
  dateFormatter.timeStyle = .short

  let formattedDate = dateFormatter.string(from: Date())

  print(formattedDate, function, line, handler())
}
