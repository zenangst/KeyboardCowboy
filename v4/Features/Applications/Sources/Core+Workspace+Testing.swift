import ApplicationSystem
#if DEBUG
import Cocoa
import CowboyCore
import Foundation

extension Core.Workspace {
  enum Testing {
    @TaskLocal public static var mock: Mock = Mock()
  }

  struct Mock: Sendable {
    var frontmostApplication: Core.RunningApplication?
    var openApplication: @Sendable (
      _ applicationURL: URL,
      _ configuration: NSWorkspace.OpenConfiguration,
    ) async throws -> Core.RunningApplication

    init(frontmostApplication: Core.RunningApplication? = nil,
         openApplication: @Sendable @escaping (_ applicationURL: URL, _ configuration: NSWorkspace.OpenConfiguration) async throws -> Core.RunningApplication = { _, _ in Core.RunningApplication(.testing(nil)) }) {
      self.frontmostApplication = frontmostApplication
      self.openApplication = openApplication
    }
  }
}
#endif
