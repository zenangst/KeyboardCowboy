import Cocoa

class AppMenu: NSMenu {
  override init(title: String) {
    super.init(title: title)
    items = [
      MainMenu(),
      FileMenu(),
      EditMenu(),
      WindowMenu(),
      HelpMenu()
    ]
  }

  required init(coder: NSCoder) {
    super.init(coder: coder)
  }
}
