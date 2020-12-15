import Cocoa

public enum HotKeyNotification: String {
  case enableHotKeys
  case enableRecordingHotKeys
  case disableHotKeys

  public var notification: Notification.Name {
    Notification.Name.init(rawValue)
  }
}

public extension NotificationCenter {
  func post(_ hotKeyNotification: HotKeyNotification) {
    self.post(.init(name: .init(rawValue: hotKeyNotification.rawValue)))
  }
}
