import AXEssibility
import Carbon
import Cocoa
import KeyCodes
import Foundation

@MainActor
final class TextCommandRunner {
  private let keyboardCommandRunner: KeyboardCommandRunner

  internal init(_ keyboardCommandRunner: KeyboardCommandRunner) {
    self.keyboardCommandRunner = keyboardCommandRunner
  }

  func run(_ command: TextCommand.TypeCommand, snapshot: UserSpace.Snapshot, runtimeDictionary: [String: String]) async throws {
    let input = snapshot.interpolateUserSpaceVariables(command.input, runtimeDictionary: runtimeDictionary)
    guard !input.isEmpty .self else { return }
    switch command.mode {
    case .typing:
      let newLines = CharacterSet.newlines
      for character in input {
        let characterString = String(character)
        KeyViewer.instance.handleString(characterString)
        var flags = CGEventFlags()
        let keyCode: Int

        if CharacterSet(charactersIn: characterString).isSubset(of: newLines) {
          keyCode = 36
        } else if let virtualKey = keyboardCommandRunner.virtualKey(for: characterString, matchDisplayValue: true) {
          keyCode = virtualKey.keyCode
        } else if let virtualKey = keyboardCommandRunner.virtualKey(for: characterString, modifiers: [.leftShift], matchDisplayValue: true) {
          keyCode = virtualKey.keyCode
          flags.insert(.maskShift)
        } else if let virtualKey = keyboardCommandRunner.virtualKey(for: characterString, modifiers: [.leftOption], matchDisplayValue: true) {
          keyCode = virtualKey.keyCode
          flags.insert(.maskAlternate)
        } else if let virtualKey = keyboardCommandRunner.virtualKey(for: characterString, modifiers: [.leftOption, .leftShift], matchDisplayValue: true) {
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
      if let focusedElement = try? SystemAccessibilityElement().focusedUIElement(),
         focusedElement.selectedText() != nil {
        focusedElement.setSelectedText(input)
      } else {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(input, forType: .string)

        KeyViewer.instance.handleString(input)

        try await Task.sleep(for: .milliseconds(100))

        try keyboardCommandRunner.machPort?.post(kVK_ANSI_V, type: .keyDown, flags: .maskCommand)
        try keyboardCommandRunner.machPort?.post(kVK_ANSI_V, type: .keyUp, flags: .maskCommand)
      }
    }

    if command.actions.contains(.insertEnter) {
      KeyViewer.instance.handleInput(.returnKey)
      try await Task.sleep(for: .milliseconds(50))
      try keyboardCommandRunner.machPort?.post(kVK_Return, type: .keyDown, flags: [])
      try keyboardCommandRunner.machPort?.post(kVK_Return, type: .keyUp, flags: [])
    }
  }
}
