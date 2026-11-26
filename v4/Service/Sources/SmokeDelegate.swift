#if DEBUG || WINDOW_FOCUS_VALIDATION
import AppKit
import HostInput
#if DEBUG
import HostOpen
#endif

@MainActor
final class SmokeDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    let arguments = CommandLine.arguments.dropFirst()
    #if DEBUG
    let commands = ["--smoke-open-browser", "--smoke-selected-text", "--smoke-hit-test",
                    "--smoke-capture", "--smoke-ui-element", "--smoke-static-text",
                    "--smoke-window-id", "--smoke-next-window", "--smoke-previous-window"]
    #else
    let commands = ["--smoke-next-window", "--smoke-previous-window"]
    #endif
    guard let command = arguments.first, commands.contains(command) else { return }

    Task {
      let options = Array(arguments.dropFirst())
      switch command {
      case "--smoke-next-window", "--smoke-previous-window":
        await HostInput.smokeWindowFocus(previous: command == "--smoke-previous-window", arguments: options)
      #if DEBUG
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
      case "--smoke-window-id":
        await HostInput.smokeWindowID(arguments: options)
      case "--smoke-capture":
        await HostInput.smokeCapture(arguments: options) { hit in
          let frame = hit.frame
          try await EditorLauncher.open(arguments: [
            "--capture-preview", hit.role?.rawValue ?? "",
            String(Double(frame.minX)), String(Double(frame.minY)),
            String(Double(frame.width)), String(Double(frame.height)),
          ])
        }
      #endif
      default: return
      }
      NSApp.terminate(nil)
    }
  }
}
#endif
