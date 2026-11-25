import AccessibilitySystem
import AppKit
import Commands

public extension MenuBar {
  enum TargetError: Error, Equatable {
    case frontmostApplicationUnavailable
    case launchRegistrationTimedOut
    case activationFailed(processIdentifier: Int32)
  }

  /// Resolves a saved command's target before handing it to the PID-scoped executor.
  @MainActor @discardableResult
  static func execute(
    _ command: Command.MenuBar,
    using accessibility: AccessibilitySystem.Client = .init(),
    budget: AccessibilitySystem.TraversalBudget = .init(),
  ) async throws -> Bool {
    let clock = ContinuousClock()
    return try await execute(
      command, workspace: .live,
      now: { clock.now },
      sleep: { try await clock.sleep(until: $0) },
      pick: { tokens, pid in
        try await executeAttempt(tokens, processIdentifier: pid, using: accessibility, budget: budget)
      },
    )
  }
}

extension MenuBar {
  @MainActor
  struct Workspace {
    let frontmost: () -> Int32?
    let firstRunning: (String) -> Int32?
    let launch: @MainActor (URL) async throws -> Void
    let activate: (Int32) -> Bool

    static var live: Self {
      Self(
        frontmost: { NSWorkspace.shared.frontmostApplication?.processIdentifier },
        firstRunning: { identifier in
          NSRunningApplication.runningApplications(withBundleIdentifier: identifier)
            .first(where: { !$0.isTerminated })?.processIdentifier
        },
        launch: { url in
          let configuration = NSWorkspace.OpenConfiguration()
          configuration.activates = false
          _ = try await NSWorkspace.shared.openApplication(at: url, configuration: configuration)
        },
        activate: { NSRunningApplication(processIdentifier: $0)?.activate() ?? false },
      )
    }
  }

  @MainActor
  static func execute(
    _ command: Command.MenuBar,
    workspace: Workspace,
    now: () -> ContinuousClock.Instant,
    sleep: @MainActor (ContinuousClock.Instant) async throws -> Void,
    pick: @MainActor ([Token], Int32) async throws -> Bool,
  ) async throws -> Bool {
    try Task.checkCancellation()
    guard !command.tokens.isEmpty else { throw ExecutionError.emptyTokens }

    let pid: Int32
    var launched = false
    if let application = command.application {
      if let running = workspace.firstRunning(application.bundleIdentifier) {
        pid = running
      } else {
        try Task.checkCancellation()
        do {
          try await workspace.launch(URL(filePath: application.path))
          launched = true
        } catch {
          try Task.checkCancellation()
          throw error
        }
        // Bound registration polling separately from the workspace launch request.
        let deadline = now() + .seconds(1)
        while true {
          try Task.checkCancellation()
          let instant = now()
          guard instant < deadline else { throw TargetError.launchRegistrationTimedOut }
          if let running = workspace.firstRunning(application.bundleIdentifier) {
            pid = running
            break
          }
          try await sleep(min(instant + .milliseconds(100), deadline))
        }
      }

      try Task.checkCancellation()
      if workspace.frontmost() != pid {
        try Task.checkCancellation()
        guard workspace.activate(pid) else { throw TargetError.activationFailed(processIdentifier: pid) }
      }
    } else {
      guard let frontmost = workspace.frontmost() else { throw TargetError.frontmostApplicationUnavailable }
      pid = frontmost
    }

    let deadline = now() + .seconds(1)
    while true {
      try Task.checkCancellation()
      do {
        return try await pick(command.tokens, pid)
      } catch let failure as StartupReadFailure {
        try Task.checkCancellation()
        let instant = now()
        guard launched, instant < deadline else { throw failure.underlying }
        try await sleep(min(instant + .milliseconds(50), deadline))
        try Task.checkCancellation()
        guard now() < deadline else { throw failure.underlying }
      }
    }
  }
}
