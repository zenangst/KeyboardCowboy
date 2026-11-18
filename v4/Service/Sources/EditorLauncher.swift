import AppKit

@MainActor
enum EditorLauncher {
  static func open() async throws {
    let bundle = Bundle.main
    let editor: URL
    if bundle.bundleURL.pathExtension == "app" {
      editor = bundle.bundleURL.appending(path: "Contents/Helpers/Keyboard Cowboy Editor.app")
    } else {
      #if DEBUG
      editor = URL(filePath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appending(path: "Editor/.build/app/debug/Keyboard Cowboy.app")
      #else
      throw missingEditor("Run the assembled Keyboard Cowboy.app to open its bundled Editor.")
      #endif
    }

    guard FileManager.default.fileExists(atPath: editor.path) else {
      throw missingEditor("Editor not found at \(editor.path). For development, run v4/Editor/Scripts/build-app.sh first.")
    }
    let configuration = NSWorkspace.OpenConfiguration()
    configuration.activates = true
    configuration.createsNewApplicationInstance = false
    try await NSWorkspace.shared.openApplication(at: editor, configuration: configuration)
  }

  private static func missingEditor(_ message: String) -> NSError {
    NSError(domain: "EditorLauncher", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
  }
}
