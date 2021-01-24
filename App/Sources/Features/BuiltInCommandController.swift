import Cocoa
import Combine
import LogicFramework
import ModelKit

class BuiltInCommandController: BuiltInCommandControlling {
  enum BuiltInCommandError: Error {
    case noWindowController
  }

  var windowController: QuickRunWindowController?
  private var previousApplication: RunningApplication?
  private var subscriptions = [AnyCancellable]()

  init() {
    NSWorkspace.shared
      .publisher(for: \.frontmostApplication)
      .removeDuplicates()
      .filter({ $0?.bundleIdentifier != bundleIdentifier })
      .sink(receiveValue: { [weak self] application in
        self?.previousApplication = application
      }).store(in: &subscriptions)
  }

  func run(_ command: BuiltInCommand) -> CommandPublisher {
    Future { promise in
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        switch command.kind {
        case .quickRun:
          guard let windowController = self.windowController else {
            promise(.failure(BuiltInCommandError.noWindowController))
            return
          }
          if windowController.window?.isVisible == true {
            windowController.close()
            _ = self.previousApplication?.activate(options: .activateIgnoringOtherApps)
          } else {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.mainWindow?.close()
            windowController.viewController.shouldFocusOnQuickRunTextField = true
            windowController.showWindow(nil)
            windowController.becomeFirstResponder()
          }
        }
        promise(.success(()))
      }
    }.eraseToAnyPublisher()
  }
}
