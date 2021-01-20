import Cocoa
import Combine
import LogicFramework
import ModelKit

class BuiltInCommandController: BuiltInCommandControlling {
  var windowController: NSWindowController?

  func run(_ command: BuiltInCommand) -> CommandPublisher {
    Future { promise in
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        switch command.kind {
        case .quickRun:
          if self.windowController?.window?.isVisible == true {
            self.windowController?.close()
          } else {
            NSApp.activate(ignoringOtherApps: true)
            self.windowController?.showWindow(nil)
            self.windowController?.becomeFirstResponder()
          }
        }
        promise(.success(()))
      }
    }.eraseToAnyPublisher()
  }
}
