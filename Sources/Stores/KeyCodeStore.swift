import Carbon
import Foundation

public enum KeyCodeStoreError: Error {
  case unableToMapKeyCode(Int)
}

final class KeyCodeStore {
  typealias MappingResult = (rawValue: String, displayValue: String)
  private let inputSource: InputSource
  private let controller: InputSourceController

  private var keyCodeLookup = [Int: String]()
  private var stringLookup = [String: Int]()


  internal init(source: InputSource? = nil,
                controller: InputSourceController) {
    self.inputSource = source ?? controller.currentInputSource()
    self.controller = controller
    self.createCache(inputSource)
  }

  private func createCache(_ inputSource: InputSource) {
    let modifiersCombinations: [UInt32] = [
      0,
      UInt32(shiftKey >> 8) & 0xFF,
    ]

    var stringLookup = [String: Int]()
    var keyCodeLookup = [Int: String]()

    for keyCode in 0..<128 {
      for modifiers in modifiersCombinations {
        guard let (rawValue, displayValue) = try? mapInputSource(
          inputSource,
          keyCode: keyCode,
          modifiers: modifiers) else {
          continue
        }

        if stringLookup[rawValue] == nil {
          stringLookup[rawValue] = keyCode
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
}
