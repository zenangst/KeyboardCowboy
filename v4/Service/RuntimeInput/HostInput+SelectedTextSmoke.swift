#if DEBUG
import AccessibilitySystem
import AppKit
import OSLog

package extension HostInput {
  @MainActor
  static func smokeSelectedText(arguments: [String]) async {
    let log = Logger(subsystem: "com.zenangst.keyboardcowboy.v4", category: "SelectedTextSmoke")
    let caret = arguments == ["--caret"]
    guard arguments.isEmpty || caret else {
      log.notice("Expected --smoke-selected-text [--caret]")
      return
    }
    guard NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.TextEdit" else {
      log.notice("No edit: focus the disposable TextEdit document first")
      return
    }
    do {
      let replaced = try await AccessibilitySystem.Client().withFocusedElement { focused in
        if caret {
          guard try focused.read(.textValue) == "before [AX replaced] after",
                try focused.read(.selectedText).isEmpty else { return false }
          try focused.write(.selectedText, value: " [AX caret]")
          return true
        }
        guard try focused.read(.selectedText) == "replace me" else { return false }
        try focused.write(.selectedText, value: "AX replaced")
        return true
      }
      if caret {
        if replaced {
          log.notice("AX empty-caret insertion succeeded")
        } else {
          log.notice("No edit: use the unchanged disposable test text and an empty selection")
        }
      } else if replaced {
        log.notice("Selected-text read and write succeeded")
      } else {
        log.notice("No edit: select only replace me, without the brackets")
      }
    } catch let failure as AccessibilitySystem.Failure {
      log.error("Selected-text check failed: \(String(describing: failure.kind), privacy: .public)")
    } catch {
      log.error("Selected-text check failed")
    }
  }
}
#endif
