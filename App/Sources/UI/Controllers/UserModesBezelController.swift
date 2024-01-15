import AppKit
import Combine
import SwiftUI

@MainActor
final class UserModesBezelController {
  @MainActor
  static let shared = UserModesBezelController()

  lazy var windowController: NSWindowController = NSWindowController(window: window)
  lazy var window: NotificationPanel = {
    let content = CurrentUserModesView(publisher: UserSpace.shared.userModesPublisher)
    return NotificationPanel(
      animationBehavior: .utilityWindow,
      styleMask: [
        .borderless,
        .nonactivatingPanel
      ],
      content: content
    )
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

  // MARK: Private methods

  private func publish(_ userModes: [UserMode]) {
    guard let contentView = window.contentView else { return }
    UserSpace.shared.userModesPublisher.publish(userModes)
    DispatchQueue.main.async {
      self.resizeAndAlignWindow(to: contentView.fittingSize)
    }
  }

  private func resizeAndAlignWindow(to contentSize: CGSize) {
    if let screen = window.screen {
      let screenVisibleFrame = screen.visibleFrame
      let newWindowOriginX = screenVisibleFrame.maxX - contentSize.width
      let newWindowOriginY = screenVisibleFrame.minY

      let newWindowFrame = NSRect(x: newWindowOriginX, y: newWindowOriginY, width: contentSize.width, height: contentSize.height)
      window.setFrame(newWindowFrame, display: true, animate: false)
    }
  }
}
