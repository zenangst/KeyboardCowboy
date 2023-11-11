import Cocoa

/// Handle `.moveFocusToNextWindowFront` `.moveFocusToPreviousWindowFront` when Finder has no open windows.
final class FinderSystemRoutine: SystemRoutine {
  let application: UserSpace.Application

  init(application: UserSpace.Application) {
    self.application = application
  }

  func run(_ kind: SystemCommand.Kind) {
    switch kind {
    case .moveFocusToNextWindowFront, .moveFocusToPreviousWindowFront:
      // Invoke the `openApplication` so that Finder opens a new window at its default location.
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
