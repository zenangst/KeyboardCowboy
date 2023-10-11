import AXEssibility
import Cocoa
import Foundation

enum UserSpaceError: Error {
  case unableToResolveFrontMostApplication
  case unableToGetSelection
  case unableToGetDocumentPath
}

final class UserSpace {
  struct Snapshot {
    let documentPath: String?
    let selectedText: String

    func replaceSelectedText(_ value: String) -> String {
      value.replacingOccurrences(of: "$SELECTED_TEXT", with: selectedText)
    }
  }
  static let shared = UserSpace()

  private init() {}

  func snapshot() -> Snapshot {
    Snapshot(documentPath: try? documentPath(),
             selectedText: selectedText())
  }

  private func currentApplication() throws -> AppAccessibilityElement {
    guard let frontmostApplication = NSWorkspace.shared.frontmostApplication else {
      throw WindowCommandRunnerError.unableToResolveFrontmostApplication
    }

    return AppAccessibilityElement(frontmostApplication.processIdentifier)
  }

  private func documentPath() throws -> String? {
    try currentApplication()
      .focusedWindow()
      .document
  }

  private func selectedText() -> String {
    (try? currentApplication()
      .focusedUIElement()
      .selectedText()) ?? ""
  }
}
