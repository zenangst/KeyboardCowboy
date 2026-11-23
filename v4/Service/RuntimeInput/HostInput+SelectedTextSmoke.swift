#if DEBUG
import AccessibilitySystem
import AppKit
import MouseFeature
import OSLog

package extension HostInput {
  @MainActor
  static func smokeSelectedText(arguments: [String]) async {
    let log = Logger(subsystem: "com.zenangst.keyboardcowboy.v4", category: "SelectedTextSmoke")
    let caret = arguments == ["--caret"]
    let bounds = arguments == ["--bounds"]
    let xcode = arguments == ["--xcode-anchors"]
    guard arguments.isEmpty || caret || bounds || xcode else {
      log.notice("Expected --smoke-selected-text [--caret | --bounds | --xcode-anchors]")
      return
    }
    let bundleIdentifier = xcode ? "com.apple.dt.Xcode" : "com.apple.TextEdit"
    guard NSWorkspace.shared.frontmostApplication?.bundleIdentifier == bundleIdentifier else {
      log.notice("Focus \(xcode ? "Xcode" : "TextEdit", privacy: .public) first; nothing was changed")
      return
    }
    do {
      if xcode {
        let client = AccessibilitySystem.Client()
        for anchor in [Mouse.Anchor.leading, .center, .trailing] {
          guard NSWorkspace.shared.frontmostApplication?.bundleIdentifier == bundleIdentifier else { return }
          let point = try await Mouse.focusedTarget(at: anchor, applicationBundleIdentifier: bundleIdentifier, using: client)
          log.notice("Xcode anchor \(String(describing: anchor), privacy: .public): \(point.map { String(describing: $0) } ?? "unavailable", privacy: .public)")
        }
        return
      }
      if bounds {
        let (isCaret, frame) = try await AccessibilitySystem.Client().withFocusedElement { focused in
          let range = try focused.read(.selectedTextRange)
          return (range.length == 0, try focused.bounds(for: range))
        }
        log.notice("AX text bounds: \(String(describing: frame), privacy: .public); caret: \(isCaret, privacy: .public)")
        return
      }
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
