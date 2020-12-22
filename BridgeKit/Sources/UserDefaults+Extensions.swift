import Foundation

public extension UserDefaults {
  @objc var hideMenuBarIcon: Bool {
    get { bool(forKey: #function) }
    set { set(newValue, forKey: #function) }
  }

  @objc var hideDockIcon: Bool {
    get { bool(forKey: #function) }
    set { set(newValue, forKey: #function) }
  }

  @objc var groupSelection: String? {
    get { string(forKey: #function) }
    set { set(newValue, forKey: #function) }
  }

  @objc var workflowSelection: String? {
    get { string(forKey: #function) }
    set { set(newValue, forKey: #function) }
  }
}

private extension StringProtocol {
  var lines: [SubSequence] { split(whereSeparator: \.isNewline) }
}
