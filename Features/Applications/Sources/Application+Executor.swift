import CowboyCore

public extension Application {
  final class Executor {
    struct Operations {
      let activate: Operation.Activate
      let close: Operation.Close
      let hide: Operation.Hide
      let launch: Operation.Launch
      let unhide: Operation.Unhide
      let wait: Operation.Wait
    }

    private let operation: Operations
    private let env: Core.Environment
    private let workspace: Core.Workspace

    init(_ env: Core.Environment) {
      self.env = env
      self.operation = Operations(
        activate: Operation.Activate(env),
        close: Operation.Close(env),
        hide: Operation.Hide(env),
        launch: Operation.Launch(env),
        unhide: Operation.Unhide(env),
        wait: Operation.Wait(env),
      )
      self.workspace = Core.Workspace(env)
    }

    func execute(_ command: Command.Application,
                 snapshot: UserSpace.Snapshot) async throws {
      guard !shouldSkipBecauseApplicationIsRunning(for: command) else {
        return
      }

      let bundleIdentifier = BundleIdentifier(command.application.bundleIdentifier)

      switch command.action {
      case .open: try await open(command)
      case .close: try await operation.close(bundleIdentifier)
      case .hide: await operation.hide(bundleIdentifier, snapshot: snapshot)
      case .unhide: await operation.unhide(bundleIdentifier, snapshot: snapshot)
      case .peek: break
      }
    }

    // MARK: Private methods

    private func open(_ command: Command.Application) async throws {
      if command.requiresLaunchAndWait {
        try await operation.launch(at: command.application.path, with: command.modifiers)
        try await operation.wait(BundleIdentifier(command.application.bundleIdentifier))
        return
      }

      let bundleIdentifier = BundleIdentifier(command.application.bundleIdentifier)
      let isFrontMostApplication = bundleIdentifier == workspace.frontmostApplication?.bundleIdentifier

      if isFrontMostApplication {
        operation.activate(bundleIdentifier)
      }
    }

    private func shouldSkipBecauseApplicationIsRunning(for command: Command.Application) -> Bool {
      if command.modifiers.contains(.onlyIfNotRunning),
         Core.RunningApplication.runningApplication(
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
