import AppKit
#if DEBUG
import HostOpen
#endif
import SwiftUI

@main
struct ServiceApp: App {
  #if DEBUG
  @NSApplicationDelegateAdaptor(BrowserSmokeDelegate.self) private var browserSmoke
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
private final class BrowserSmokeDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    let arguments = CommandLine.arguments.dropFirst()
    guard arguments.first == "--smoke-open-browser" else { return }
    Task {
      await HostOpen.smokeBrowser(arguments: Array(arguments.dropFirst()))
      NSApp.terminate(nil)
    }
  }
}
#endif
