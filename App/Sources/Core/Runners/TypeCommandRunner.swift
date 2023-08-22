import Carbon
import Cocoa
import KeyCodes
import Foundation

final class TypeCommandRunner {
  private let keyboardCommandRunner: KeyboardCommandRunner

  internal init(_ keyboardCommandRunner: KeyboardCommandRunner) {
    self.keyboardCommandRunner = keyboardCommandRunner
  }

  func run(_ command: TypeCommand) async throws {
    let input = command.input

    switch command.mode {
    case .typing:
      let newLines = CharacterSet.newlines
      for character in input {
        let characterString = String(character)
        var flags = CGEventFlags()
        let keyCode: Int
        if let virtualKey = keyboardCommandRunner.virtualKey(for: characterString, matchDisplayValue: true) {
          keyCode = virtualKey.keyCode
        } else if let virtualKey = keyboardCommandRunner.virtualKey(for: characterString, modifiers: [.shift], matchDisplayValue: true) {
          keyCode = virtualKey.keyCode
          flags.insert(.maskShift)
        } else if let virtualKey = keyboardCommandRunner.virtualKey(for: characterString, modifiers: [.option], matchDisplayValue: true) {
          keyCode = virtualKey.keyCode
          flags.insert(.maskAlternate)
        } else if CharacterSet(charactersIn: characterString).isSubset(of: newLines) {
          keyCode = 36
        } else {
          continue
        }

        try keyboardCommandRunner.machPort?.post(keyCode, type: .keyDown, flags: flags)
      }
    case .instant:
      let pasteboard = NSPasteboard.general
      pasteboard.clearContents()
      pasteboard.setString(command.input, forType: .string)

      let keyCode = 9 // v
      try keyboardCommandRunner.machPort?.post(keyCode, type: .keyDown, flags: .maskCommand)
    }
  }
}
