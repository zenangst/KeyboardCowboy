import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
  lazy var windowController = NSWindowController(window: notificationWindow)
  lazy var coordinator = NotificationCoordinator(.init())
  lazy var notificationWindow: NotificationWindow = {
    NotificationWindow(contentRect: .init(origin: .init(x: 8, y: 0),
                                          size: .init(width: 1000, height: 100)), content: {
      NotificationListView(publisher: self.coordinator.publisher)
    })
  }()

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    FileLogger.log("🤠 \(#function)")
    switch KeyboardCowboy.env {
    case .development:
      guard !isRunningPreview else { return }
      KeyboardCowboy.activate()
      return
      self.windowController.showWindow(nil)

      withAnimation {
        let newPayload: [NotificationViewModel] = [
          .init(id: UUID().uuidString,
                icon: IconViewModel(bundleIdentifier: "com.apple.Finder",
                                    path: "/System/Library/CoreServices/Finder.app"),
                name: "Finder",
                result: .success),
          .init(id: UUID().uuidString,
                icon: IconViewModel(bundleIdentifier: "com.apple.Calendar",
                                    path: "/System/Library/CoreServices/Calendar.app"),
                name: "Calendar",
                result: .success)
        ]
        self.coordinator.publisher.publish(newPayload)

        guard let intrinsicContentSize = self.notificationWindow.contentView?.intrinsicContentSize else { return }

        let rect = CGRect(origin: .init(x: 8, y: intrinsicContentSize.height + 8),
                          size: intrinsicContentSize)
        self.windowController.window?.animator().setFrame(rect, display: true, animate: true)
      }
    case .production:
      KeyboardCowboy.mainWindow?.close()
    }
  }
}
