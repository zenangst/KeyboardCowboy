import Cocoa

@MainActor
public final class UserSpace {
  let env: Core.Environment

  public init(_ env: Core.Environment) {
    self.env = env
  }

  /// The host supplies the previous application from its activation history, if available.
  public func takeSnapshot(previous: Application? = nil) -> Snapshot {
    let runningApplication: Core.RunningApplication?
    switch env {
    case .production:
      runningApplication = NSWorkspace.shared.frontmostApplication.map { .init(.production($0)) }
    #if DEBUG
    case .testing:
      runningApplication = Testing.mock.frontmostApplication
    #endif
    }

    let frontMost = runningApplication.flatMap { application -> Application? in
      guard !application.isTerminated, let identifier = application.bundleIdentifier else { return nil }
      return Application(bundleIdentifier: identifier, runningApplication: application)
    }
    let previous = previous.flatMap { $0.runningApplication.isTerminated ? nil : $0 }
    return Snapshot(apps: .init(frontMost: frontMost, previous: previous))
  }
}
