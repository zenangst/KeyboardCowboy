import Cocoa
import CowboyCore
import Foundation

extension Core {
  final class Workspace {
    let env: Environment

    public enum Testing {
      @TaskLocal public static var mock: Mock = Mock()
    }

    public struct Mock: Sendable {
      var frontmostApplication: RunningApplication?
      var openApplication: RunningApplication

      init(frontmostApplication: RunningApplication? = nil, openApplication: RunningApplication = RunningApplication(.testing)) {
        self.frontmostApplication = frontmostApplication
        self.openApplication = openApplication
      }
    }

    init(_ env: Environment) {
      self.env = env
    }

    var frontmostApplication: RunningApplication? {
      switch env {
      case .production: NSWorkspace.shared.frontmostApplication?.asRunningApplication()
      case .testing: Testing.mock.frontmostApplication
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
      case .testing: Testing.mock.openApplication
      }
    }
  }
}

private extension NSRunningApplication {
  func asRunningApplication() -> Core.RunningApplication {
    Core.RunningApplication(.production(self))
  }
}
