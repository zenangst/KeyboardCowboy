import AXEssibility
import Apps
import ScriptingBridge
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
    let selections: [String]

    init(documentPath: String? = nil, selectedText: String = "", selections: [String] = []) {
      self.documentPath = documentPath
      self.selectedText = selectedText
      self.selections = selections
    }

    func interpolateUserSpaceVariables(_ value: String) -> String {
      var interpolatedString = value.replacingOccurrences(of: "$SELECTED_TEXT", with: selectedText)

      if let filePath = documentPath, let url = URL(string: filePath) {
        // Attempt to create URLComponents from the URL
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
          // Extract the directory from the path, replacing any URL-encoded spaces
          let directory = (components.path as NSString)
            .replacingOccurrences(of: "%20", with: " ")
          // Replace placeholders in the interpolated string with actual values
          let lastPathComponent = (url.lastPathComponent as NSString)
          let cwd = lastPathComponent.contains(".")
              ? (directory as NSString).deletingLastPathComponent
              : directory

          interpolatedString = interpolatedString
            .replacingOccurrences(of: "$CURRENT_WORKING_DIRECTORY", with: cwd)
            .replacingOccurrences(of: "$DIRECTORY", with: (directory as NSString).deletingLastPathComponent)
            .replacingOccurrences(of: "$FILEPATH", with: components.path.replacingOccurrences(of: "%20", with: " "))
            .replacingOccurrences(of: "$FILENAME", with: (url.lastPathComponent as NSString).deletingPathExtension)
            .replacingOccurrences(of: "$FILE", with: lastPathComponent as String)
            .replacingOccurrences(of: "$EXTENSION", with: (url.lastPathComponent as NSString).pathExtension)
        }
      }
      return interpolatedString
    }

    func terminalEnvironment() -> [String: String] {
      var environment = ProcessInfo.processInfo.environment
      environment["TERM"] = "xterm-256color"
      environment["SELECTED_TEXT"] = selectedText

      if let filePath = documentPath {
        let url = URL(filePath: filePath)
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
          let directory = (components.path as NSString)
            .replacingOccurrences(of: "%20", with: " ")
          let lastPathComponent = (url.lastPathComponent as NSString)
          let cwd = lastPathComponent.contains(".")
          ? (directory as NSString).deletingLastPathComponent
          : directory

          environment["CURRENT_WORKING_DIRECTORY"] = cwd
          environment["DIRECTORY"] = (directory as NSString).deletingLastPathComponent
          environment["FILE"] = url.lastPathComponent
          environment["FILEPATH"] = components.path.replacingOccurrences(of: "%20", with: " ")
          environment["FILENAME"] = (url.lastPathComponent as NSString).deletingPathExtension
          environment["EXTENSION"] = (url.lastPathComponent as NSString).pathExtension
        }
      }

      return environment
    }
  }

  static let shared = UserSpace()

  private init() {}

  @MainActor
  func snapshot() -> Snapshot {
    var selections = [String]()
    var documentPath: String?
    var selectedText: String = ""

    if let frontmostApplication = try? frontmostApplication() {
      if let documentPathFromAX = try? self.documentPath(for: frontmostApplication) {
        documentPath = documentPathFromAX
      } else if let bundleIdentifier = frontmostApplication.bundleIdentifier {
        // Only invoke this if the user isn't dragging using the mouse.
        if !MouseMonitor.shared.isDraggingUsingTheMouse {
          ScriptingBridgeResolver.resolve(
            bundleIdentifier,
            firstUrl: &documentPath,
            selections: &selections
          )
        }
      }

      if let resolvedText = try? self.selectedText(for: frontmostApplication) {
        selectedText = resolvedText
      }
    }

    return Snapshot(documentPath: documentPath,
                    selectedText: selectedText,
                    selections: selections)
  }

  private func frontmostApplication() throws -> NSRunningApplication {
    guard let frontmostApplication = NSWorkspace.shared.frontmostApplication else {
      throw WindowCommandRunnerError.unableToResolveFrontmostApplication
    }

    return frontmostApplication
  }

  private func currentApplication(for runningApplication: NSRunningApplication) throws -> AppAccessibilityElement {
    return AppAccessibilityElement(runningApplication.processIdentifier)
  }

  private func documentPath(for runningApplication: NSRunningApplication) throws -> String? {
    try currentApplication(for: runningApplication)
      .focusedWindow()
      .document
  }

  private func selectedText(for runningApplication: NSRunningApplication) throws -> String {
    let app = try currentApplication(for: runningApplication)
    let focusedElement = try app.focusedUIElement()
    let selectedText = focusedElement.selectedText()

    return selectedText ?? ""
  }
}
