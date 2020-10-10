import Cocoa

class FileMenu: NSMenuItem {
  init() {
    super.init(title: "", action: nil, keyEquivalent: "")
    submenu = NSMenu(title: "File")
    submenu?.items = [
      NSMenuItem(title: "Close Window",
                 action: #selector(NSWindow.performClose(_:)),
                 keyEquivalent: "w")
    ]
  }

  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
