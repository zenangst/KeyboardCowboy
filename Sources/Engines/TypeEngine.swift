import Foundation

final class TypeEngine {
  private let keyboardEngine: KeyboardEngine

  internal init(keyboardEngine: KeyboardEngine) {
    self.keyboardEngine = keyboardEngine
  }

  func run(_ typeCommand: TypeCommand) async throws {
    let input = typeCommand.input.compactMap(String.init)
    for character in input {
      var modifiers: [ModifierKey] = []
      if character.uppercased() == character {
        modifiers.append(.shift)
      }
      let command = KeyboardCommand(
        keyboardShortcut: .init(key: character, modifiers: modifiers))
      try keyboardEngine.run(command, type: .keyDown, with: nil)
    }
  }
}
