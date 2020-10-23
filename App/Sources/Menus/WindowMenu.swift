import Cocoa

final class WindowMenu: NSMenuItem {
  init() {
    super.init(title: "", action: nil, keyEquivalent: "")
    submenu = NSMenu(title: "Window")
    submenu?.items = [
      NSMenuItem(title: "Minmize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m"),
      NSMenuItem(title: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: ""),
      NSMenuItem.separator(),
      NSMenuItem(title: "Show All", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "m")
    ]
  }

  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
