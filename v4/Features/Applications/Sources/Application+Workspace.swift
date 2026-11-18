import ApplicationSystem
import Cocoa
import Foundation
import RuntimeEnvironment

extension Application {
  final class Workspace: Sendable {
    let env: RuntimeEnvironment.Mode

    init(_ env: RuntimeEnvironment.Mode) {
      self.env = env
    }

    var frontmostApplication: ApplicationSystem.RunningApplication? {
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
    ) async throws -> ApplicationSystem.RunningApplication {
      switch env {
      case .production:
        try await NSWorkspace.shared
          .openApplication(at: applicationURL, configuration: configuration)
          .asRunningApplication()
      #if DEBUG
      case .testing: try await Testing.mock.openApplication(applicationURL, configuration)
      #endif
      }
    }
  }
}

private extension NSRunningApplication {
  func asRunningApplication() -> ApplicationSystem.RunningApplication {
    ApplicationSystem.RunningApplication(.production(self))
  }
}
