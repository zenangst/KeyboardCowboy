import Carbon
import Foundation

final class TypeEngine {
  private let keyboardEngine: KeyboardEngine

  internal init(keyboardEngine: KeyboardEngine) {
    self.keyboardEngine = keyboardEngine
  }

  // TODO: Fix issue with inserting characters that depend on option modifer
  func run(_ command: TypeCommand) async throws {
    let input = command.input
    let uppercaseLetters = CharacterSet.uppercaseLetters
    let newLines = CharacterSet.newlines
    let punctuationCharacters = CharacterSet.punctuationCharacters

    for character in input {
      var string = String(character)
      var modifiers: [ModifierKey] = []

      let charSet = CharacterSet(charactersIn: string)
      if charSet.isSubset(of: uppercaseLetters) {
        modifiers.append(.shift)
      }

      if charSet.isSubset(of: punctuationCharacters) {
        modifiers.append(.shift)
      }

      if charSet.isSubset(of: newLines) {
        string = KeyCodes.specialKeys[kVK_Return]!
      }

      let command = KeyboardCommand(
        keyboardShortcut: .init(key: string, modifiers: modifiers))

      try keyboardEngine.run(command, type: .keyDown, with: nil)
    }
  }
}
