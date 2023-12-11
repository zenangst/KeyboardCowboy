import Carbon
import Cocoa
import KeyCodes
import Foundation

final class TextCommandRunner {
  private let keyboardCommandRunner: KeyboardCommandRunner

  internal init(_ keyboardCommandRunner: KeyboardCommandRunner) {
    self.keyboardCommandRunner = keyboardCommandRunner
  }

  func run(_ input: String, mode: TextCommand.TypeCommand.Mode) async throws {
    switch mode {
    case .typing:
      let newLines = CharacterSet.newlines
      for character in input {
        let characterString = String(character)
        var flags = CGEventFlags()
        let keyCode: Int

        if CharacterSet(charactersIn: characterString).isSubset(of: newLines) {
          keyCode = 36
        } else if let virtualKey = keyboardCommandRunner.virtualKey(for: characterString, matchDisplayValue: true) {
          keyCode = virtualKey.keyCode
        } else if let virtualKey = keyboardCommandRunner.virtualKey(for: characterString, modifiers: [.shift], matchDisplayValue: true) {
          keyCode = virtualKey.keyCode
          flags.insert(.maskShift)
        } else if let virtualKey = keyboardCommandRunner.virtualKey(for: characterString, modifiers: [.option], matchDisplayValue: true) {
          keyCode = virtualKey.keyCode
          flags.insert(.maskAlternate)
        } else if let virtualKey = keyboardCommandRunner.virtualKey(for: characterString, modifiers: [.option, .shift], matchDisplayValue: true) {
          keyCode = virtualKey.keyCode
          flags.insert(.maskShift)
          flags.insert(.maskAlternate)
        } else if let virtualKey = keyboardCommandRunner.virtualKey(for: characterString, matchDisplayValue: false) {
          keyCode = virtualKey.keyCode
        } else {
          continue
        }

        try keyboardCommandRunner.machPort?.post(keyCode, type: .keyDown, flags: flags)
      }
    case .instant:
      let pasteboard = NSPasteboard.general
      pasteboard.clearContents()
      pasteboard.setString(input, forType: .string)

      try keyboardCommandRunner.machPort?.post(kVK_ANSI_V, type: .keyDown, flags: .maskCommand)
    }
  }
}
