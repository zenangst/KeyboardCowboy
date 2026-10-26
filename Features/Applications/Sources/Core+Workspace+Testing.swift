#if DEBUG
import Cocoa
import CowboyCore
import Foundation

extension Core.Workspace {
  public enum Testing {
    @TaskLocal public static var mock: Mock = Mock()
  }

  public struct Mock: Sendable {
    var frontmostApplication: Core.RunningApplication?
    var openApplication: @Sendable (_ applicationURL: URL, _ configuration: NSWorkspace.OpenConfiguration) -> Core.RunningApplication

    init(frontmostApplication: Core.RunningApplication? = nil,
         openApplication: @Sendable @escaping (_ applicationURL: URL, _ configuration: NSWorkspace.OpenConfiguration) -> Core.RunningApplication = { _, _ in Core.RunningApplication(.testing(nil)) }) {
      self.frontmostApplication = frontmostApplication
      self.openApplication = openApplication
    }
  }
}
#endif
