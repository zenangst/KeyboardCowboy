import ApplicationSystem
import CowboyCore

import Cocoa
import Combine

@MainActor
public final class UserSpace {
  let env: Core.Environment
  private var history: [Application] = []
  private var activationObserver: AnyCancellable?

  public init(_ env: Core.Environment) {
    self.env = env
    if case .production = env {
      let workspace = NSWorkspace.shared
      let center = workspace.notificationCenter
      let observer = center.addObserver(forName: NSWorkspace.didActivateApplicationNotification,
                                        object: nil, queue: .main) { [weak self] notification in
        guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
          return
        }
        MainActor.assumeIsolated {
          self?.recordActivation(.init(.production(application)))
        }
      }
      activationObserver = AnyCancellable { center.removeObserver(observer) }
      if let current = workspace.frontmostApplication {
        recordActivation(.init(.production(current)))
      }
    }
  }

  /// Record an activation from the host's event stream when using a custom environment.
  public func recordActivation(_ application: Core.RunningApplication) {
    history.removeAll { $0.runningApplication.isTerminated }
    guard !application.isTerminated, let identifier = application.bundleIdentifier else { return }
    history.removeAll { $0.runningApplication.isSameApplication(as: application) }
    history.insert(Application(bundleIdentifier: identifier, runningApplication: application), at: 0)
  }

  /// The optional host-supplied previous app overrides locally tracked history.
  /// Without a current app, the most recent live history entry is used as previous.
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
    if let frontMost { recordActivation(frontMost.runningApplication) }
    history.removeAll { $0.runningApplication.isTerminated }
    let previous = previous.flatMap { $0.runningApplication.isTerminated ? nil : $0 }
      ?? history.first { candidate in
        guard let frontMost else { return true }
        return !candidate.runningApplication.isSameApplication(as: frontMost.runningApplication)
      }
    return Snapshot(apps: .init(frontMost: frontMost, previous: previous))
  }
}
