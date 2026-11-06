import CoreGraphics
import CowboyCore

public extension Application {
  final class Executor: Sendable {
    public enum ExecutionError: Error, Equatable, Sendable {
      case failedToTerminate(Core.BundleIdentifier)
      case failedToActivate(Core.BundleIdentifier)
      case applicationNotRunning(Core.BundleIdentifier)
      case missingFrontmostApplication
    }

    struct Operations: Sendable {
      let activate: Operation.Activate
      let bringToFront: Operation.BringToFront
      let close: Operation.Close
      let hide: Operation.Hide
      let launch: Operation.Launch
      let unhide: Operation.Unhide
      let wait: Operation.Wait
    }

    private let env: Core.Environment
    private let operation: Operations
    private let workspace: Core.Workspace

    public init(_ env: Core.Environment) {
      self.env = env
      self.operation = Operations(
        activate: Operation.Activate(env),
        bringToFront: Operation.BringToFront(env),
        close: Operation.Close(env),
        hide: Operation.Hide(env),
        launch: Operation.Launch(env),
        unhide: Operation.Unhide(env),
        wait: Operation.Wait(env),
      )
      self.workspace = Core.Workspace(env)
    }

    @discardableResult
    /// Execution cooperatively respects task cancellation; callers control task ownership.
    public func execute(_ command: Command.Application,
                        cgEventType: CGEventType?,
                        snapshot: UserSpace.Snapshot) async throws -> UserSpace.Snapshot {
      try Task.checkCancellation()
      guard !shouldSkipBecauseApplicationIsRunning(for: command) else {
        return snapshot
      }

      let bundleIdentifier = BundleIdentifier(command.application.bundleIdentifier)

      switch command.action {
      case .open:
        try await open(command)
        try Task.checkCancellation()
        return await snapshot.refreshing(frontmost: workspace.frontmostApplication)
      case .close:
        try await operation.close(bundleIdentifier)
        try Task.checkCancellation()
        return await snapshot.refreshing(frontmost: workspace.frontmostApplication)
      case .hide:
        await operation.hide(bundleIdentifier, snapshot: snapshot)
      case .unhide:
        await operation.unhide(bundleIdentifier, snapshot: snapshot)
      case .peek:
        guard let cgEventType else { return snapshot }

        switch cgEventType {
        case .keyUp:
          await operation.hide(bundleIdentifier, snapshot: snapshot)
        case .keyDown:
          try await open(command)
        default: break
        }
      }
      try Task.checkCancellation()
      return snapshot
    }

    // MARK: Private methods

    private func open(_ command: Command.Application) async throws {
      if command.requiresLaunchAndWait {
        try await operation.launch(at: command.application.path, with: command.modifiers)
        try Task.checkCancellation()
        try await operation.wait(for: BundleIdentifier(command.application.bundleIdentifier))
        return
      }

      let bundleIdentifier = BundleIdentifier(command.application.bundleIdentifier)
      let isFrontMostApplication = bundleIdentifier == workspace.frontmostApplication?.bundleIdentifier

      if isFrontMostApplication {
        let result = operation.activate(bundleIdentifier)
        try Task.checkCancellation()
        switch result {
        case .activated: break
        case .missingFrontmost: throw ExecutionError.missingFrontmostApplication
        case .missingTarget: throw ExecutionError.applicationNotRunning(bundleIdentifier)
        case .rejected: throw ExecutionError.failedToActivate(bundleIdentifier)
        }
      } else {
        try await operation.launch(at: command.application.path, with: command.modifiers)
      }
    }

    private func shouldSkipBecauseApplicationIsRunning(for command: Command.Application) -> Bool {
      if command.modifiers.contains(.onlyIfNotRunning),
         Core.RunningApplication.application(
           with: BundleIdentifier(command.application.bundleIdentifier),
           env: env) != nil {
        return true
      }
      return false
    }
  }
}

private extension Command.Application {
  var requiresLaunchAndWait: Bool {
    modifiers.contains(.background) || application.metadata.isElectron
  }
}
