import CoreGraphics
import CowboyCore

public extension Application {
  final class Executor: Sendable {
    /// A host may restore a previous application instead of hiding on peek release.
    public enum PeekReleaseAction: Sendable {
      case hide
      /// Supply an ordinary open command for the application's previous target.
      case open(Command.Application)
      case none
    }

    public struct SelfApplicationHandler: Sendable {
      let bundleIdentifier: Core.BundleIdentifier
      let open: @Sendable () async -> Void

      public init(bundleIdentifier: Core.BundleIdentifier, open: @escaping @Sendable () async -> Void) {
        self.bundleIdentifier = bundleIdentifier
        self.open = open
      }
    }

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
    private let windowOwnerNames: (@Sendable () async -> [String])?
    private let willExecute: (@Sendable (Command.Application) async -> Void)?
    private let selfApplication: SelfApplicationHandler?
    private let peekRelease: (@Sendable (Command.Application) async -> PeekReleaseAction)?

    /// The host supplies eligible release events, cached window owners and optional adapters.
    public convenience init(_ env: Core.Environment,
                            windowOwnerNames: (@Sendable () async -> [String])? = nil,
                            willExecute: (@Sendable (Command.Application) async -> Void)? = nil,
                            selfApplication: SelfApplicationHandler? = nil,
                            peekRelease: (@Sendable (Command.Application) async -> PeekReleaseAction)? = nil,
                            sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }) {
      self.init(env, wait: Operation.Wait(env, sleep: sleep), windowOwnerNames: windowOwnerNames,
                willExecute: willExecute, selfApplication: selfApplication, peekRelease: peekRelease)
    }

    init(_ env: Core.Environment, wait: Operation.Wait,
         windowOwnerNames: (@Sendable () async -> [String])? = nil,
         willExecute: (@Sendable (Command.Application) async -> Void)? = nil,
         selfApplication: SelfApplicationHandler? = nil,
         peekRelease: (@Sendable (Command.Application) async -> PeekReleaseAction)? = nil) {
      self.env = env
      self.operation = Operations(
        activate: Operation.Activate(env),
        bringToFront: Operation.BringToFront(env),
        close: Operation.Close(env),
        hide: Operation.Hide(env),
        launch: Operation.Launch(env),
        unhide: Operation.Unhide(env),
        wait: wait,
      )
      self.workspace = Core.Workspace(env)
      self.windowOwnerNames = windowOwnerNames
      self.willExecute = willExecute
      self.selfApplication = selfApplication
      self.peekRelease = peekRelease
    }

    @discardableResult
    /// Execution cooperatively respects task cancellation; callers control task ownership.
    public func execute(_ command: Command.Application,
                        cgEventType: CGEventType?,
                        snapshot: UserSpace.Snapshot) async throws -> UserSpace.Snapshot {
      try Task.checkCancellation()
      await willExecute?(command)
      try Task.checkCancellation()
      let shouldSkip = shouldSkipBecauseApplicationIsRunning(for: command)
      try Task.checkCancellation()
      guard !shouldSkip else {
        return snapshot
      }

      let bundleIdentifier = BundleIdentifier(command.application.bundleIdentifier)
      if let selfApplication, selfApplication.bundleIdentifier == bundleIdentifier {
        await selfApplication.open()
        try Task.checkCancellation()
        return snapshot
      }

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
          let releaseAction = await peekRelease?(command) ?? .hide
          try Task.checkCancellation()
          switch releaseAction {
          case .hide:
            await operation.hide(bundleIdentifier, snapshot: snapshot)
          case .open(let previous):
            try await open(previous)
          case .none:
            break
          }
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
      let owners = await windowOwnerNames?()
      try Task.checkCancellation()
      let isFrontMostApplication = bundleIdentifier == workspace.frontmostApplication?.bundleIdentifier

      if isFrontMostApplication {
        let result = operation.activate(bundleIdentifier)
        try Task.checkCancellation()
        switch result {
        case .activated:
          if let owners {
            if owners.contains(command.application.bundleName) {
              do {
                try await operation.launch(at: command.application.path, with: command.modifiers)
              } catch is CancellationError {
                throw CancellationError()
              } catch {
                try Task.checkCancellation()
                try operation.bringToFront()
              }
            } else {
              // Keep fallback work owned by this task rather than detaching it.
              try operation.bringToFront()
            }
          }
        case .cancelled:
          throw CancellationError()
        case .missingFrontmost, .missingTarget, .rejected:
          try operation.bringToFront()
        }
      } else {
        try await operation.launch(at: command.application.path, with: command.modifiers)
        try Task.checkCancellation()
        if let owners {
          if owners.contains(command.application.bundleName) {
            // Legacy treats post-launch activation as best effort.
            operation.activate(bundleIdentifier)
          } else {
            guard let target = Core.RunningApplication.application(with: bundleIdentifier, env: env) else {
              return
            }

            try Task.checkCancellation()
            if let frontmost = workspace.frontmostApplication {
              target.activate(from: frontmost, options: .activateAllWindows)
            } else {
              target.activate(options: .activateAllWindows)
            }
          }
        }
      }

      try Task.checkCancellation()
      if command.modifiers.contains(.waitForAppToLaunch),
         Core.RunningApplication.application(with: bundleIdentifier, env: env)?.isFinishedLaunching != true {
        // Match legacy behavior: a timeout does not fail the command.
        try await operation.wait(for: bundleIdentifier)
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
