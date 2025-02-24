import Cocoa

/// Handle `.moveFocusToNextWindowFront` `.moveFocusToPreviousWindowFront` for apps with no windows.
final class OpenApplicationWithNoWindowsSystemRoutine: SystemRoutine {
  let application: UserSpace.Application

  init(application: UserSpace.Application) {
    self.application = application
  }

  func run(_ kind: SystemCommand.Kind) {
    switch kind {
    case .moveFocusToNextWindowFront, .moveFocusToPreviousWindowFront:
      // Invoke the `openApplication` so that application opens a new window.
      let configuration = NSWorkspace.OpenConfiguration()
      configuration.activates = true
      let _ = NSWorkspace.shared.openApplication(
        at: URL(filePath: application.path),
        configuration: configuration
      )
    default:
      break
    }
  }

  func run(_ kind: WindowFocusCommand.Kind) {
    switch kind {
    case .moveFocusToNextWindowFront, .moveFocusToPreviousWindowFront:
      // Invoke the `openApplication` so that application opens a new window.
      let configuration = NSWorkspace.OpenConfiguration()
      configuration.activates = true
      let _ = NSWorkspace.shared.openApplication(
        at: URL(filePath: application.path),
        configuration: configuration
      )
    default:
      break
    }
  }

}
