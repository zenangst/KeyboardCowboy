import Carbon
import KeyCodes
import Foundation

final class TypeEngine {
  enum NaturalTyping: TimeInterval {
    case disabled = 0
    case slow = 0.0275
    case medium = 0.0175
    case fast = 0.01
  }

  private let keyboardEngine: KeyboardEngine
  private var naturalTyping: NaturalTyping = .fast

  internal init(keyboardEngine: KeyboardEngine) {
    self.keyboardEngine = keyboardEngine
  }

  func run(_ command: TypeCommand) async throws {
    let input = command.input
    let newLines = CharacterSet.newlines

    for character in input {
      let string = String(character)
      let charSet = CharacterSet(charactersIn: string)
      var flags = CGEventFlags()
      let keyCode: Int
        if let virtualKey = keyboardEngine.virtualKey(for: String(character), matchDisplayValue: true) {
          keyCode = virtualKey.keyCode
        } else if let virtualKey = keyboardEngine.virtualKey(for: String(character), modifiers: [.shift], matchDisplayValue: true) {
          keyCode = virtualKey.keyCode
          flags.insert(.maskShift)
        } else if let virtualKey = keyboardEngine.virtualKey(for: String(character), modifiers: [.option], matchDisplayValue: true) {
          keyCode = virtualKey.keyCode
          flags.insert(.maskAlternate)
        } else if charSet.isSubset(of: newLines) {
          keyCode = 36
        } else {
          continue
        }

      try keyboardEngine.machPort?.post(keyCode, type: .keyDown, flags: flags)
    }
  }
}
