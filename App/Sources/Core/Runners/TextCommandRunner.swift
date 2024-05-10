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
        try keyboardCommandRunner.machPort?.post(keyCode, type: .keyUp, flags: flags)
      }
    case .instant:
      let pasteboard = NSPasteboard.general
      pasteboard.clearContents()

      var input = input
      let cursor = "${}"
      let positionFromEnd: Int
      if let range = input.range(of: cursor) {
        positionFromEnd = input.distance(from: range.upperBound, to: input.endIndex)
        input = input.replacingOccurrences(of: cursor, with: "")
      } else {
        positionFromEnd = 0
      }

      pasteboard.setString(input, forType: .string)
      try await Task.sleep(for: .milliseconds(10))
      try keyboardCommandRunner.machPort?.post(kVK_ANSI_V, type: .keyDown, flags: .maskCommand)
      try keyboardCommandRunner.machPort?.post(kVK_ANSI_V, type: .keyUp, flags: .maskCommand)

      guard positionFromEnd > 0 else { return }
      for _ in 0..<positionFromEnd {
        try keyboardCommandRunner.machPort?.post(kVK_LeftArrow, type: .keyDown, flags: [.maskNonCoalesced, .maskNumericPad, .maskSecondaryFn])
        try keyboardCommandRunner.machPort?.post(kVK_LeftArrow, type: .keyUp, flags: [.maskNonCoalesced, .maskNumericPad, .maskSecondaryFn])
      }
      try await Task.sleep(for: .milliseconds(10))
    }
  }
}
