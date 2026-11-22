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
          ["--smoke-open-browser", "--smoke-selected-text", "--smoke-hit-test"].contains(command) else { return }
    Task {
      switch command {
      case "--smoke-open-browser":
        await HostOpen.smokeBrowser(arguments: Array(arguments.dropFirst()))
      case "--smoke-selected-text":
        await HostInput.smokeSelectedText(arguments: Array(arguments.dropFirst()))
      default:
        await HostInput.smokeHitTest(arguments: Array(arguments.dropFirst()))
      }
      NSApp.terminate(nil)
    }
  }
}
#endif
