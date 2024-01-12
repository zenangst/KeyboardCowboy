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

  var debouncer: DebounceManager<[UserMode]>?

  private init() { 
    debouncer = DebounceManager { [weak self] userModes in
      self?.publish(userModes)
    }
  }

  func show(_ userModes: [UserMode]) {
    debouncer?.send(userModes)
  }

  func hide() {
    debouncer?.send([])
  }

  private func publish(_ userModes: [UserMode]) {
    if !userModes.isEmpty {
      windowController.showWindow(nil)
    } else {
      windowController.close()
    }
    UserSpace.shared.userModesPublisher.publish(userModes)
  }
}
