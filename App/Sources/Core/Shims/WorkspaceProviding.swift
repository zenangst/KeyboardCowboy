import AppKit

public typealias WorkspaceCompletion = ((RunningApplication?, Error?) -> Void)

public protocol WorkspaceProviding: Sendable {
  var applications: [RunningApplication] { get }
  var frontApplication: RunningApplication? { get }

  func openApplication(at applicationURL: URL, configuration: NSWorkspace.OpenConfiguration) async throws -> NSRunningApplication

  func open(_ urls: [URL], withApplicationAt applicationURL: URL, configuration: NSWorkspace.OpenConfiguration) async throws -> NSRunningApplication

  func open(_ url: URL, configuration: NSWorkspace.OpenConfiguration) async throws -> NSRunningApplication

  func reveal(_ path: String)
}

extension NSWorkspace: WorkspaceProviding, @unchecked @retroactive Sendable {
  public var applications: [RunningApplication] {
    runningApplications
  }

  public var frontApplication: RunningApplication? {
    frontmostApplication
  }

  public func reveal(_ path: String) {
    selectFile(path, inFileViewerRootedAtPath: "")
  }
}
