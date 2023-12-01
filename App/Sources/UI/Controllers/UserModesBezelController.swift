import AppKit
import Combine
import SwiftUI

@MainActor
final class UserModesBezelController {
  static let shared = UserModesBezelController()

  lazy var windowController: NSWindowController = {
    let content = CurrentUserModesView(publisher: UserSpace.shared.userModesPublisher)
    let window = NotificationPanel(animationBehavior: .utilityWindow, 
                                   styleMask: [.borderless, .nonactivatingPanel],
                                   content: content)
    let windowController = NSWindowController(window: window)
    return windowController
  }()

  private init() { }

  func show() {
    windowController.showWindow(nil)
  }

  func hide() {
    windowController.close()
  }
}
