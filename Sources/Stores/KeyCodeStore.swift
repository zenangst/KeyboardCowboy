import Carbon
import Foundation

public enum KeyCodeStoreError: Error {
  case unableToMapKeyCode(Int)
}

final class KeyCodeStore {
  enum KeyCodeModifier: CaseIterable {
    case clear
    case shift
    case option
    case shiftOption

    var int: UInt32 {
      switch self {
      case .clear:
        return 0
      case .shift:
        return UInt32(shiftKey >> 8) & 0xFF
      case .option:
        return UInt32(optionKey >> 8) & 0xFF
      case .shiftOption:
        return KeyCodeModifier.shift.int | KeyCodeModifier.option.int
      }
    }

    var modifierKeys: [ModifierKey] {
      switch self {
      case .clear:
        return []
      case .shift:
        return [.shift]
      case .option:
        return [.option]
      case .shiftOption:
        return [.option, .shift]
      }
    }
  }

  typealias MappingResult = (rawValue: String, displayValue: String)
  private let inputSource: InputSource
  private let controller: InputSourceController

  private var keyCodeLookup = [Int: String]()
  private var stringLookup = [String: Int]()
  private var storage = [String: (Int, KeyCodeModifier)]()

  internal init(source: InputSource? = nil,
                controller: InputSourceController) {
    self.inputSource = source ?? controller.currentInputSource()
    self.controller = controller
    self.createCache(inputSource)
  }

  func stringWithModifier(for string: String) -> (keyCode: Int, modifier: KeyCodeModifier)? {
    storage[string]
  }

  func keyCode(for string: String) -> Int? {
    stringLookup[string]
  }

  func string(for keyCode: Int) -> String? {
    keyCodeLookup[keyCode]
  }

  func mapInputSource(_ inputSource: InputSource,
                      keyCode: Int,
                      modifiers: UInt32) throws -> MappingResult {
    let layoutData = TISGetInputSourceProperty(inputSource.source, kTISPropertyUnicodeKeyLayoutData)
    let dataRef = unsafeBitCast(layoutData, to: CFData.self)
    let keyLayout = unsafeBitCast(CFDataGetBytePtr(dataRef), to: UnsafePointer<CoreServices.UCKeyboardLayout>.self)
    let keyTranslateOptions = OptionBits(CoreServices.kUCKeyTranslateNoDeadKeysBit)
    var deadKeyState: UInt32 = 0
    let maxChars = 256
    var chars = [UniChar](repeating: 0, count: maxChars)
    var length = 0
    let error = CoreServices.UCKeyTranslate(
      keyLayout,
      UInt16(keyCode),
      UInt16(CoreServices.kUCKeyActionDisplay),
      modifiers,
      UInt32(LMGetKbdType()),
      keyTranslateOptions,
      &deadKeyState,
      maxChars,
      &length,
      &chars)

    if error != noErr {
      throw KeyCodeStoreError.unableToMapKeyCode(keyCode)
    }

    let rawValue = NSString(characters: &chars, length: length) as String
    let displayValue: String

    if let specialKey = KeyCodes.specialKeys[keyCode] {
      displayValue = specialKey
    } else {
      displayValue = rawValue.uppercased()
    }

    return (rawValue: rawValue, displayValue: displayValue)
  }

  // MARK: Private methods

  private func createCache(_ inputSource: InputSource) {
    var stringLookup = [String: Int]()
    var stringLookupWithModifier = [String: (Int, KeyCodeModifier)]()
    var keyCodeLookup = [Int: String]()

    for keyCode in 0..<128 {
      for modifier in KeyCodeModifier.allCases {
        guard let (rawValue, displayValue) = try? mapInputSource(
          inputSource,
          keyCode: keyCode,
          modifiers: modifier.int) else {
          continue
        }

        if stringLookup[rawValue] == nil {
          stringLookup[rawValue] = keyCode
          stringLookupWithModifier[rawValue] = (keyCode, modifier)
        }
        if stringLookup[displayValue] == nil {
          stringLookup[displayValue] = keyCode
          stringLookup[displayValue.uppercased()] = keyCode
        }
      }
    }

    for (keyCode, stringValue) in stringLookup {
      keyCodeLookup[stringValue] = keyCode
    }

    self.stringLookup = stringLookup
    self.keyCodeLookup = keyCodeLookup
    self.storage = stringLookupWithModifier
  }
}
