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

  private var debouncer: DebounceManager<[UserMode]>?
  private var subscription: AnyCancellable?

  private init() { 
    debouncer = DebounceManager(for: .milliseconds(250)) { [weak self] userModes in
      self?.publish(userModes)
    }
    windowController.showWindow(nil)
    subscription = NotificationCenter.default
      .publisher(for: NSApplication.didChangeScreenParametersNotification)
      .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
      .sink { [weak self] _ in
        guard let self, let contentView = window.contentView else { return }
        self.resizeAndAlignWindow(to: contentView.fittingSize, animate: false)
      }
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
      self.resizeAndAlignWindow(to: contentView.fittingSize, animate: true)
    }
  }

  private func resizeAndAlignWindow(to contentSize: CGSize, animate: Bool) {
    guard let screen = NSScreen.main else { return }
    let screenFrame = screen.frame
    let newWindowOriginX = screenFrame.maxX - contentSize.width
    let newWindowOriginY = screenFrame.minY
    let newWindowFrame = NSRect(x: newWindowOriginX, y: newWindowOriginY, width: contentSize.width, height: contentSize.height)

    window.setFrame(newWindowFrame, display: true, animate: animate)
  }
}
