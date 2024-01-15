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
    debouncer = DebounceManager(for: .milliseconds(250)) { [weak self] userModes in
      self?.publish(userModes)
    }
    windowController.showWindow(nil)
  }

  func show(_ userModes: [UserMode]) {
    debouncer?.send(userModes)
  }

  func hide() {
    debouncer?.send([])
  }

  private func publish(_ userModes: [UserMode]) {
    withAnimation {
      UserSpace.shared.userModesPublisher.publish(userModes)
    }
  }
}
