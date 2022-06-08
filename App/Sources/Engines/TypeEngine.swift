import Carbon
import Foundation

final class TypeEngine {
  enum NaturalTyping: TimeInterval {
    case disabled = 0
    case slow = 0.0275
    case medium = 0.0175
    case fast = 0.01
  }

  private let keyboardEngine: KeyboardEngine
  private let store: KeyCodeStore
  private var naturalTyping: NaturalTyping = .disabled

  internal init(keyboardEngine: KeyboardEngine, store: KeyCodeStore) {
    self.keyboardEngine = keyboardEngine
    self.store = store
  }

  func run(_ command: TypeCommand) async throws {
    let input = command.input
    let uppercaseLetters = CharacterSet.uppercaseLetters
    let newLines = CharacterSet.newlines

    for character in input {
      if naturalTyping != .disabled {
        let sleepTime = TimeInterval.random(in: 0...naturalTyping.rawValue)
        Thread.sleep(forTimeInterval: sleepTime)
      }

      let string = String(character)
      let charSet = CharacterSet(charactersIn: string)
      var modifiers: [ModifierKey] = .init()
      var key: String = string

      if let container = store.stringWithModifier(for: string),
         let rawValue = store.string(for: container.keyCode) {
        key = rawValue
        modifiers = container.modifier.modifierKeys

        if charSet.isSubset(of: uppercaseLetters) {
          modifiers = [.shift]
          key = string
        }
      } else {
        if charSet.isSubset(of: newLines) {
          modifiers = []
          key = KeyCodes.specialKeys[kVK_Return]!
        } else if charSet.isSubset(of: uppercaseLetters) {
          modifiers = [.shift]
        }
      }

      let keyboardShortcut = KeyShortcut(key: key, modifiers: modifiers)
      let command = KeyboardCommand(keyboardShortcut: keyboardShortcut)
      try keyboardEngine.run(command, type: .keyDown, with: nil)
    }
  }
}
