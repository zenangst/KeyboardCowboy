import Cocoa
import MachPort

final class ModifierTriggerMachPortCoordinator: Sendable {
  nonisolated(unsafe) static fileprivate var debug: Bool = false
  let machPort: MachPortEventController

  init(machPort: MachPortEventController) {
    self.machPort = machPort
  }

  @discardableResult
  func set(_ key: AdditionalKey, on machPortEvent: MachPortEvent) -> Self {
    machPortEvent.event.setIntegerValueField(.keyboardEventKeycode, value: key.keyCode)
    debugModifier("\(key) on \(machPortEvent.keyCode)")
    return self
  }

  @discardableResult
  func decorateEvent(_ machPortEvent: MachPortEvent, with modifiers: [ModifierKey]) -> Self {
    var cgEventFlags: CGEventFlags = CGEventFlags()
    modifiers.forEach { modifier in
      machPortEvent.event.flags.insert(modifier.cgEventFlags)
      machPortEvent.result?.takeUnretainedValue().flags.insert(modifier.cgEventFlags)
      cgEventFlags.insert(modifier.cgEventFlags)
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
  func post(_ key: AdditionalKey) -> Self {
    _ = try? machPort.post(Int(key.keyCode), type: .keyDown, flags: .maskNonCoalesced)
    _ = try? machPort.post(Int(key.keyCode), type: .keyUp, flags: .maskNonCoalesced)
    debugModifier("")
    return self
  }

  @discardableResult
  func post(_ key: AdditionalKey, modifiers: [ModifierKey], flags: CGEventFlags? = nil) -> Self {
    var flags = flags ?? CGEventFlags.maskNonCoalesced
    modifiers.forEach { modifier in
      flags.insert(modifier.cgEventFlags)
    }
    _ = try? machPort.post(Int(key.keyCode), type: .flagsChanged, flags: flags)
    return self
  }

  @discardableResult
  func postFlagsChanged(modifiers: [ModifierKey]) -> Self {
    var flags = CGEventFlags.maskNonCoalesced
    modifiers.forEach { modifier in
      flags.insert(modifier.cgEventFlags)
    }

    modifiers.forEach { modifier in
      _ = try? machPort.post(modifier.key, type: .flagsChanged, flags: flags)
    }
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

fileprivate func debugModifier(_ handler: @autoclosure @escaping () -> String, function: StaticString = #function, line: UInt = #line) {
  guard ModifierTriggerMachPortCoordinator.debug else { return }

  let dateFormatter = DateFormatter()
  dateFormatter.dateStyle = .short
  dateFormatter.timeStyle = .short

  let formattedDate = dateFormatter.string(from: Date())

  print(formattedDate, function, line, handler())
}
