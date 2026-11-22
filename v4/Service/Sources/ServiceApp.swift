import AppKit
#if DEBUG
import HostInput
import HostOpen
#endif
import SwiftUI

@main
struct ServiceApp: App {
  #if DEBUG
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

#if DEBUG
@MainActor
private final class SmokeDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    let arguments = CommandLine.arguments.dropFirst()
    guard let command = arguments.first,
          command == "--smoke-open-browser" || command == "--smoke-selected-text" else { return }
    Task {
      if command == "--smoke-open-browser" {
        await HostOpen.smokeBrowser(arguments: Array(arguments.dropFirst()))
      } else {
        await HostInput.smokeSelectedText(arguments: Array(arguments.dropFirst()))
      }
      NSApp.terminate(nil)
    }
  }
}
#endif
