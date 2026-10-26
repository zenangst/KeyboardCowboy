import Cocoa
import CowboyCore
import Foundation

extension Core {
  final class Workspace {
    let env: Environment

    init(_ env: Environment) {
      self.env = env
    }

    var frontmostApplication: RunningApplication? {
      switch env {
      case .production: NSWorkspace.shared.frontmostApplication?.asRunningApplication()
      #if DEBUG
      case .testing: Testing.mock.frontmostApplication
      #endif
      }
    }

    @discardableResult
    func openApplication(
      at applicationURL: URL,
      configuration: NSWorkspace.OpenConfiguration,
    ) async throws -> RunningApplication {
      switch env {
      case .production:
        try await NSWorkspace.shared
          .openApplication(at: applicationURL, configuration: configuration)
          .asRunningApplication()
      #if DEBUG
      case .testing: Testing.mock.openApplication(applicationURL, configuration)
      #endif
      }
    }
  }
}

private extension NSRunningApplication {
  func asRunningApplication() -> Core.RunningApplication {
    Core.RunningApplication(.production(self))
  }
}
