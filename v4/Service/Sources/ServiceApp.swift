import AppKit
import SwiftUI

@main
struct ServiceApp: App {
  #if DEBUG || WINDOW_FOCUS_VALIDATION
  @NSApplicationDelegateAdaptor(SmokeDelegate.self) private var smoke
  #endif

  var body: some Scene {
    MenuBarExtra("Keyboard Cowboy", systemImage: "keyboard") {
      Button("Edit Configuration…") {
        Task {
          do {
            try await EditorLauncher.open()
          } catch {
            NSAlert(error: error).runModal()
          }
        }
      }
      Divider()
      Button("Quit Keyboard Cowboy") { NSApp.terminate(nil) }
        .keyboardShortcut("q")
    }
  }
}
