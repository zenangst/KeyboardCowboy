import Foundation

final class KeyboardCowboyApplicationRoutine: ApplicationRoutine, Sendable {
  let notificationCenter: NotificationCenter

  init(notificationCenter: NotificationCenter = .default) {
    self.notificationCenter = notificationCenter
  }

  func run() async -> Bool {
    await MainActor.run {
      notificationCenter.post(.init(name: Notification.Name("OpenMainWindow")))
    }
    return true
  }
}
