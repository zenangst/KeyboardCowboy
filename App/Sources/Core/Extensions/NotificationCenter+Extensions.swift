import Foundation

extension Notification {
  static let openKeyboardCowboy = Notification(name: .openKeyboardCowboy)
}

extension Notification.Name {
  static let newWorkflow = AppNotification.newWorkflow.notificationName
  static let openKeyboardCowboy = AppNotification.openKeyboardCowboy.notificationName
}

enum AppNotification: String {
  case newWorkflow = "com.zenangst.KeyboardCowboy.newWorkflow"
  case openKeyboardCowboy = "com.zenangst.KeyboardCowboy.openApp"

  var notificationName: Notification.Name { Notification.Name(rawValue) }
}

extension NotificationCenter {
  func post(_ appNotification: AppNotification) {
    post(name: appNotification.notificationName, object: nil)
  }
}
