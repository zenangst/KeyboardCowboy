import AppKit

@main
@MainActor
struct WorkspaceSmokeFixture {
  static func main() {
    let app = NSApplication.shared
    app.setActivationPolicy(.regular)
    app.finishLaunching()
    let mainMenu = NSMenu()
    let item = NSMenuItem(title: "Window", action: nil, keyEquivalent: "")
    let windowsMenu = NSMenu(title: "Window")
    item.submenu = windowsMenu
    mainMenu.addItem(item)
    app.mainMenu = mainMenu
    app.windowsMenu = windowsMenu
    let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 420, height: 250),
                          styleMask: [.titled, .closable, .resizable, .miniaturizable], backing: .buffered, defer: false)
    window.title = ProcessInfo.processInfo.processName
    window.center()
    window.makeKeyAndOrderFront(nil)
    DispatchQueue.main.asyncAfter(deadline: .now() + 45) { app.terminate(nil) }
    withExtendedLifetime(window) { app.run() }
  }
}
