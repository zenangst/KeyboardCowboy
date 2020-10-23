import Cocoa

final class EditMenu: NSMenuItem {
  init() {
    super.init(title: "", action: nil, keyEquivalent: "")
    submenu = NSMenu(title: "Edit")
    submenu?.items = [
      NSMenuItem(title: "Undo", action: #selector(UndoManager.undo), keyEquivalent: "z"),
      NSMenuItem(title: "Redo", action: #selector(UndoManager.redo), keyEquivalent: "Z"),
      NSMenuItem.separator(),
      NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"),
      NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"),
      NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"),
      NSMenuItem.separator(),
      NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"),
      NSMenuItem.separator(),
      NSMenuItem(title: "Duplicate", action: #selector(NSApplication.copy), keyEquivalent: "d")
    ]
  }

  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
