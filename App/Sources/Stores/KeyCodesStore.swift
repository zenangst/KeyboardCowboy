import AppKit
import Carbon
import Combine
import Foundation
import InputSources
import KeyCodes

final class KeyCodesStore {
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

  private var subscription: AnyCancellable?
  private var virtualKeyContainer: VirtualKeyContainer?
  private var virtualSystems = [VirtualKey]()

  internal init() {
    subscription = NotificationCenter.default.publisher(for: NSTextInputContext.keyboardSelectionDidChangeNotification)
      .sink(receiveValue: { [weak self] _ in
        self?.mapKeys()
      })
    mapKeys()
  }

  func systemKeys() -> [VirtualKey] {
    virtualSystems
  }

  func specialKeys() -> [Int: String] {
    VirtualSpecialKey.keys
  }

  func virtualKey(for string: String) -> VirtualKey? {
    virtualKeyContainer?.valueForString(string, matchDisplayValue: false)
  }

  func keyCode(for string: String, matchDisplayValue: Bool) -> Int? {
    virtualKeyContainer?.valueForString(string, modifier: nil,
                                        matchDisplayValue: matchDisplayValue)?.keyCode
  }

  func string(for keyCode: Int) -> String? {
    virtualKeyContainer?.valueForKeyCode(keyCode, modifier: nil)?.rawValue
  }

  func displayValue(for keyCode: Int) -> String? {
    virtualKeyContainer?.valueForKeyCode(keyCode, modifier: nil)?.displayValue
  }

  private func mapKeys() {
    Task {
      let controller = InputSourceController()
      let keyCodes = KeyCodes()
      let input = try controller.currentInputSource()
      virtualKeyContainer = try await keyCodes.mapKeyCodes(from: input.source)
      virtualSystems = try keyCodes.systemKeys(from: input.source)
    }
  }
}
