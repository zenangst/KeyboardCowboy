import Cocoa

class HelpMenu: NSMenuItem {
  init() {
    super.init(title: "", action: nil, keyEquivalent: "")
    submenu = NSMenu(title: "Help")
    let helpMenuSearch = NSMenuItem()
    helpMenuSearch.view = NSTextField()

    let sendFeedback = NSMenuItem(title: "Send feedback", action: #selector(Self.sendFeedback), keyEquivalent: "")
    sendFeedback.target = self

    let sponsor = NSMenuItem(title: "Support this support", action: #selector(Self.supportProject), keyEquivalent: "")
    sponsor.target = self

    submenu?.items = [
      helpMenuSearch,
      sendFeedback,
      sponsor
    ]
  }

  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Actions

  @objc func sendFeedback() {
    NSWorkspace.shared.open(URL(string: "https://github.com/zenangst/KeyboardCowboy3/issues/new")!)
  }

  @objc func supportProject() {
    NSWorkspace.shared.open(URL(string: "https://github.com/sponsors/zenangst")!)
  }
}
