import Foundation

extension UserDefaults {
  @objc var hideMenuBarIcon: Bool {
    get { bool(forKey: #function) }
    set { set(newValue, forKey: #function) }
  }

  @objc var hideDockIcon: Bool {
    get { bool(forKey: #function) }
    set { set(newValue, forKey: #function) }
  }
}
