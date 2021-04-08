import Carbon
import Foundation
import ModelKit

public protocol KeyCodeMapping {
  func hashTable() -> [String: Int]
  func map(_ keyCode: Int, modifiers: UInt32) throws -> (rawValue: String,
                                                         displayValue: String)
}

public enum KeyCodeMappingError: Error {
  case unableToMapKeyCode(Int)
}

final class KeyCodeMapper: KeyCodeMapping {
  let inputSource: InputSource
  let inputController: InputSourceController
  static var inputController = InputSourceController()
  static var shared: KeyCodeMapper = KeyCodeMapper()

  private(set) public var keyCodeLookup = [Int: String]()
  private(set) public var stringLookup = [String: Int]()

  init(inputSource: InputSource? = nil, then handler: (() -> KeyCodeMapper)? = nil) {
    let inputController = Self.inputController
    self.inputSource = inputSource ?? inputController.currentInputSource()
    self.inputController = inputController
    self.cache()
  }

  func cache() {
    guard stringLookup.isEmpty else { return }

    stringLookup = hashTable()
    for (key, value) in stringLookup {
      keyCodeLookup[value] = key
    }
  }

  func hashTable() -> [String: Int] {
    var table = [String: Int]()

    let modifiersCombinations: [UInt32] = [
      0,
      UInt32(shiftKey >> 8) & 0xFF,
    ]

    for integer in 0..<128 {
      for modifiers in modifiersCombinations {
        if let container = try? map(integer, modifiers: modifiers) {
          if table[container.rawValue] == nil {
            table[container.rawValue] = integer
          }
          if table[container.displayValue] == nil {
            table[container.displayValue] = integer
            table[container.displayValue.uppercased()] = integer
          }
        }
      }
    }

    return table
  }

  func map(_ keyCode: Int, modifiers: UInt32) throws -> (rawValue: String,
                                                         displayValue: String) {
    let layoutData = TISGetInputSourceProperty(inputSource.source, kTISPropertyUnicodeKeyLayoutData)
    let dataRef = unsafeBitCast(layoutData, to: CFData.self)
    let keyLayout = unsafeBitCast(CFDataGetBytePtr(dataRef), to: UnsafePointer<CoreServices.UCKeyboardLayout>.self)
    let keyTranslateOptions = OptionBits(CoreServices.kUCKeyTranslateNoDeadKeysBit)
    var deadKeyState: UInt32 = 0
    let maxChars = 256
    var chars = [UniChar](repeating: 0, count: maxChars)
    var length = 0
    let error = CoreServices.UCKeyTranslate(keyLayout,
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
      throw KeyCodeMappingError.unableToMapKeyCode(keyCode)
    }

    let rawValue = NSString(characters: &chars, length: length) as String
    let displayValue: String

    if let specialKey = KeyCodes.specialKeys[keyCode] {
      displayValue = specialKey
    } else {
      displayValue = rawValue.uppercased()
    }

    return (rawValue: rawValue,
            displayValue: displayValue)
  }
}
