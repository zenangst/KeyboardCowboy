import Carbon

public protocol HotkeyHandling: AnyObject {
  var delegate: HotkeyHandlerDelegate? { get set }
  var hotkeySupplier: HotkeySupplying? { get set }
  func installEventHandler()
  func register(_ hotkey: Hotkey, withSignature signature: String) -> Bool
  func sendKeyboardEvent(_ event: EventRef, hotkeys: Set<Hotkey>) -> Result<Void, HotkeySendKeyboardError>
  func unregister(_ reference: EventHotKeyRef)
}

public enum HotkeySendKeyboardError: Error {
  case getEventParameter(Int32)
  case unableToFindHotkey
  case unknownEvent

  var ossStatus: OSStatus {
    switch self {
    case .getEventParameter(let value):
      return value
    case .unableToFindHotkey, .unknownEvent:
      return noErr
    }
  }
}

public protocol HotkeyHandlerDelegate: AnyObject {
  func hotkeyHandler(_ handler: HotkeyHandling, didInvokeHotkey hotkey: Hotkey)
}

class HotkeyHandler: HotkeyHandling {
  weak var delegate: HotkeyHandlerDelegate?
  weak var hotkeySupplier: HotkeySupplying?
  static var shared: HotkeyHandler = HotkeyHandler()
  private var counter: UInt32 = 0

  func installEventHandler() {
    let targetReference: EventTargetRef = GetEventDispatcherTarget()
    let handler: EventHandlerUPP = { _, event, _ -> OSStatus in
      if let event = event,
         let hotkeys = HotkeyHandler.shared.hotkeySupplier?.hotkeys {
        switch HotkeyHandler.shared.sendKeyboardEvent(event, hotkeys: hotkeys) {
        case .success:
          return noErr
        case .failure(let error):
          if case .getEventParameter(let status) = error {
            return status
          } else { return noErr }
        }
      }

      return noErr
    }
    let numType: Int = 1
    var list: EventTypeSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                            eventKind: UInt32(kEventHotKeyPressed))
    let userData: UnsafeMutableRawPointer? = nil
    let outReference: UnsafeMutablePointer<EventHandlerRef?>? = nil

    InstallEventHandler(targetReference, handler, numType, &list, userData, outReference)
  }

  func register(_ hotkey: Hotkey, withSignature signature: String) -> Bool {
    let signature = UTGetOSTypeFromString(signature as CFString)
    let identifier = EventHotKeyID(signature: signature, id: counter)
    let options: OptionBits = 0
    let keyCode: UInt32 = UInt32(hotkey.keyCode)
    let modifiers: UInt32 = UInt32(hotkey.modifiers)
    let targetReference: EventTargetRef = GetEventDispatcherTarget()
    var reference: EventHotKeyRef?
    let error = RegisterEventHotKey(keyCode, modifiers,
                                    identifier, targetReference,
                                    options, &reference)

    guard error == noErr else {
      return false
    }

    hotkey.identifier = identifier
    hotkey.reference = reference
    defer { counter += 1 }

    return true
  }

  func sendKeyboardEvent(_ event: EventRef, hotkeys: Set<Hotkey>) -> Result<Void, HotkeySendKeyboardError> {
    let name: EventParamName = EventParamName(kEventParamDirectObject)
    let desiredType: EventParamType = EventParamName(typeEventHotKeyID)
    let actualType: UnsafeMutablePointer<EventParamType>? = nil
    let bufferSize: Int = MemoryLayout<EventHotKeyID>.size
    let actualSize: UnsafeMutablePointer<Int>? = nil
    var identifier = EventHotKeyID()
    let error = GetEventParameter(event, name, desiredType, actualType,
                                  bufferSize, actualSize, &identifier)

    guard error == noErr else {
      return .failure(.getEventParameter(error))
    }

    guard let hotkey = hotkeys.first(where: { $0.identifier?.id == identifier.id }) else {
      return .failure(.unableToFindHotkey)
    }

    switch GetEventKind(event) {
    case EventParamName(kEventHotKeyPressed):
      delegate?.hotkeyHandler(self, didInvokeHotkey: hotkey)
      return .success(())
    default:
      return .failure(.unknownEvent)
    }
  }

  func unregister(_ reference: EventHotKeyRef) {
    UnregisterEventHotKey(reference)
  }
}
