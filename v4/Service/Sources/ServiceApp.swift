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
          ["--smoke-open-browser", "--smoke-selected-text", "--smoke-hit-test",
           "--smoke-capture", "--smoke-ui-element", "--smoke-static-text"].contains(command) else { return }
    Task {
      let options = Array(arguments.dropFirst())
      switch command {
      case "--smoke-open-browser":
        await HostOpen.smokeBrowser(arguments: options)
      case "--smoke-selected-text":
        await HostInput.smokeSelectedText(arguments: options)
      case "--smoke-hit-test":
        await HostInput.smokeHitTest(arguments: options)
      case "--smoke-ui-element":
        await HostInput.smokeUIElement(arguments: options)
      case "--smoke-static-text":
        await HostInput.smokeStaticText(arguments: options)
      case "--smoke-capture":
        await HostInput.smokeCapture(arguments: options) { hit in
          let frame = hit.frame
          try await EditorLauncher.open(arguments: [
            "--capture-preview", hit.role ?? "",
            String(Double(frame.minX)), String(Double(frame.minY)),
            String(Double(frame.width)), String(Double(frame.height)),
          ])
        }
      default: return
      }
      NSApp.terminate(nil)
    }
  }
}
#endif
