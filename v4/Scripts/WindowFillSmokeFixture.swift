import AppKit

@main
@MainActor
struct WindowFillSmokeFixture {
  static func main() {
    guard CommandLine.arguments.count == 4, let displayID = UInt32(CommandLine.arguments[3]) else { exit(2) }

    let app = NSApplication.shared
    let mode = CommandLine.arguments[1]
    let minimizing = mode == "system-minimize"
    app.setActivationPolicy(.regular)
    app.finishLaunching()
    let key = NSDeviceDescriptionKey("NSScreenNumber")
    guard let screen = NSScreen.screens.first(where: {
      ($0.deviceDescription[key] as? NSNumber)?.uint32Value == displayID
    }) else { exit(2) }

    let area = screen.visibleFrame
    let style: NSWindow.StyleMask = minimizing ? [.titled, .resizable, .miniaturizable] : [.titled, .resizable]
    let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 420, height: 250),
                          styleMask: style, backing: .buffered, defer: false, screen: screen)
    window.setFrameOrigin(CGPoint(x: area.minX + 200, y: area.minY + 100))
    window.title = "Window Management Fill Fixture"
    window.minSize = CGSize(width: 200, height: 150)
    if mode == "constrained" {
      window.maxSize = CGSize(width: 800, height: 600)
    }
    let replacement: NSWindow?
    if mode == "switch-focus" || mode == "system-fill" || minimizing {
      let other = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 420, height: 250),
                           styleMask: style, backing: .buffered, defer: false, screen: screen)
      other.title = "Window Management Fill Replacement"
      other.setFrameOrigin(CGPoint(x: area.minX + 310, y: area.minY + 140))
      other.orderFront(nil)
      replacement = other
    } else {
      replacement = nil
    }
    var control: NSWindow?
    if mode == "system-fill" || minimizing {
      let menu = NSMenu()
      let windowItem = NSMenuItem(title: "Window", action: nil, keyEquivalent: "")
      let windowMenu = NSMenu(title: "Window")
      windowItem.submenu = windowMenu
      menu.addItem(windowItem)
      app.mainMenu = menu
      app.windowsMenu = windowMenu
      if minimizing {
        let item = windowMenu.addItem(withTitle: "Minimize All", action: #selector(NSApplication.miniaturizeAll(_:)),
                                      keyEquivalent: "")
        item.target = app
      } else if let secondary = NSScreen.screens.first(where: { $0 != screen }) {
        let frame = secondary.visibleFrame
        let other = NSWindow(contentRect: CGRect(x: frame.minX + 200, y: frame.minY + 100, width: 420, height: 250),
                             styleMask: [.titled, .resizable], backing: .buffered, defer: false, screen: secondary)
        other.title = "Window Management Fill Control"
        other.orderFront(nil)
        control = other
      }
    }
    window.makeKeyAndOrderFront(nil)
    app.activate()
    let initialOrigin = window.frame.origin
    let observer = NotificationCenter.default.addObserver(
      forName: NSWindow.didMoveNotification, object: window, queue: .main,
    ) { _ in
      MainActor.assumeIsolated {
        if mode == "switch-focus", window.frame.origin != initialOrigin, window.isKeyWindow {
          replacement?.makeKeyAndOrderFront(nil)
        }
      }
    }
    defer { NotificationCenter.default.removeObserver(observer) }
    do {
      let numbers = [window, replacement, control].compactMap { $0?.windowNumber }
      try numbers.map(String.init).joined(separator: " ").write(toFile: CommandLine.arguments[2], atomically: true, encoding: .utf8)
    } catch {
      exit(1)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 25) { app.terminate(nil) }
    withExtendedLifetime((window, replacement, control)) { app.run() }
  }
}
