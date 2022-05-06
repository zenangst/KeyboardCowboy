import Carbon
import Foundation

final class TypeEngine {
  private let keyboardEngine: KeyboardEngine
  private let store: KeyCodeStore

  internal init(keyboardEngine: KeyboardEngine, store: KeyCodeStore) {
    self.keyboardEngine = keyboardEngine
    self.store = store
  }

  func run(_ command: TypeCommand) async throws {
    let input = command.input
    let uppercaseLetters = CharacterSet.uppercaseLetters
    let newLines = CharacterSet.newlines

    for character in input {
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
