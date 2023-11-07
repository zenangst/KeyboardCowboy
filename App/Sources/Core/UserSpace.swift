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

    func interpolateUserSpaceVariables(_ value: String) -> String {
      var interpolatedString = value.replacingOccurrences(of: "$SELECTED_TEXT", with: selectedText)

      if let documentPath {
        // Create a URL from the document path
        let url = URL(fileURLWithPath: documentPath)
        // Attempt to create URLComponents from the URL
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
          // Extract the directory from the path, replacing any URL-encoded spaces
          let directory = (components.path as NSString)
            .deletingLastPathComponent
            .replacingOccurrences(of: "%20", with: " ")
          // Replace placeholders in the interpolated string with actual values
          interpolatedString = interpolatedString
            .replacingOccurrences(of: "$DIRECTORY", with: directory)
            .replacingOccurrences(of: "$FILE", with: url.lastPathComponent)
            .replacingOccurrences(of: "$FILENAME", with: (url.lastPathComponent as NSString).deletingPathExtension)
            .replacingOccurrences(of: "$EXTENSION", with: (url.lastPathComponent as NSString).pathExtension)
        }
      }
      return interpolatedString
    }

    func terminalEnvironment() -> [String: String] {
      var environment = ProcessInfo.processInfo.environment
      environment["TERM"] = "xterm-256color"

      if let documentPath {
        let url = URL(filePath: documentPath)
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
          let directory = (components.path as NSString)
            .deletingLastPathComponent
            .replacingOccurrences(of: "%20", with: " ")
          environment["DIRECTORY"] = directory
          environment["FILE"] = url.lastPathComponent
          environment["FILENAME"] = (url.lastPathComponent as NSString).deletingPathExtension
          environment["EXTENSION"] = (url.lastPathComponent as NSString).pathExtension
        }
      }

      return environment
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
