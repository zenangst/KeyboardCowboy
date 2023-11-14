import Foundation

extension Notification.Name {
  static let newWorkflow = AppNotification.newWorkflow.notificationName
}

enum AppNotification: String {
  case newWorkflow = "com.zenangst.KeyboardCowboy.newWorkflow"

  var notificationName: Notification.Name {
    switch self {
    case .newWorkflow:
      Notification.Name(rawValue)
    }
  }
}

extension NotificationCenter {
  func post(_ appNotification: AppNotification) {
    post(name: appNotification.notificationName, object: nil)
  }
}
