import Cocoa

class MainMenu: NSMenuItem {
  private lazy var applicationName = ProcessInfo.processInfo.processName

  init() {
    super.init(title: "", action: nil, keyEquivalent: "")

    submenu = NSMenu(title: "MainMenu")
    submenu?.items = [
      NSMenuItem(title: "About \(applicationName)", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
                 keyEquivalent: ""),
      NSMenuItem.separator(),
      NSMenuItem(title: "Preferences...", action: nil, keyEquivalent: ","),
      NSMenuItem.separator(),
      NSMenuItem(title: "Hide \(applicationName)", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"),
      NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h"),
      NSMenuItem(title: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: ""),
      NSMenuItem.separator(),
      NSMenuItem(title: "Quit \(applicationName)", action: #selector(NSApplication.shared.terminate(_:)),
                 keyEquivalent: "q")
    ]
  }

  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
