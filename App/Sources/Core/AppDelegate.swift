import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
  lazy var coordinator = NotificationCoordinator(.init())

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    switch KeyboardCowboy.env {
    case .designTime:
      break
    case .development:
      KeyboardCowboy.activate()
    case .production:
      KeyboardCowboy.mainWindow?.close()
    }
  }
}
