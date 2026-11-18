import ApplicationSystem
#if DEBUG
import Cocoa
import Foundation

extension Application.Workspace {
  enum Testing {
    @TaskLocal public static var mock: Mock = Mock()
  }

  struct Mock: Sendable {
    var frontmostApplication: ApplicationSystem.RunningApplication?
    var openApplication: @Sendable (
      _ applicationURL: URL,
      _ configuration: NSWorkspace.OpenConfiguration,
    ) async throws -> ApplicationSystem.RunningApplication

    init(frontmostApplication: ApplicationSystem.RunningApplication? = nil,
         openApplication: @Sendable @escaping (_ applicationURL: URL, _ configuration: NSWorkspace.OpenConfiguration) async throws -> ApplicationSystem.RunningApplication = { _, _ in ApplicationSystem.RunningApplication(.testing(nil)) }) {
      self.frontmostApplication = frontmostApplication
      self.openApplication = openApplication
    }
  }
}
#endif
