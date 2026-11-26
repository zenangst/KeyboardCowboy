import ApplicationsFeature
import Commands
import CoreGraphics
import ScriptingFeature
import UserSpace

public enum SystemCommand {
  public enum Action: String, Codable, CaseIterable, Sendable {
    case activateLastApplication
    case missionControl
    case applicationWindows
    case showDesktop
    case hideAllApps
    case minimizeAllOpenWindows
    case showNotificationCenter
    case fillAllOpenWindows
  }

  public enum Completion: Equatable, Sendable {
    /// The system operation returned; this does not confirm every visible effect.
    case invoked
    /// The Applications executor finished its ordinary open request; focus is not verified.
    case applicationOpenCompleted
    case noPreviousApplication
  }

  public enum ExecutionError: Error, Equatable {
    case dockUnavailable
    case missingPreviousApplicationBundleURL(String)
  }

  @MainActor
  public struct Executor {
    typealias PreviousApplication = Operation.ActivateLastApplication.PreviousApplication

    private let dock: Operation.Dock
    private let activateLastApplication: Operation.ActivateLastApplication
    private let hideAllApps: @MainActor ([Command.Application]) async throws -> Void
    private let minimizeAllOpenWindows: @MainActor ([String]?) async throws -> Void
    private let showNotificationCenter: Operation.ShowNotificationCenter
    private let fillAllOpenWindows: @MainActor () async throws -> Void

    /// Keep the executor (or its shared UserSpace) alive to accumulate activation history.
    public init() {
      self.init(
        userSpace: UserSpace(.production),
        applicationExecutor: Application.Executor(.production),
      )
    }

    public init(userSpace: UserSpace, applicationExecutor: Application.Executor) {
      self.init(
        sendDockNotification: Operation.Dock.sendToDock,
        previousApplication: {
          let snapshot = userSpace.takeSnapshot()
          let previous = snapshot.apps.previous.flatMap { app -> PreviousApplication? in
            guard !app.runningApplication.isTerminated else { return nil }

            return PreviousApplication(
              bundleIdentifier: app.bundleIdentifier.value,
              bundleURL: app.runningApplication.bundleURL,
            )
          }
          return (previous, snapshot)
        },
        openApplication: { command, event, snapshot in
          _ = try await applicationExecutor.execute(command, cgEventType: event, snapshot: snapshot)
        },
      )
    }

    init(
      sendDockNotification: @escaping @MainActor (Operation.Dock.Action) throws -> Void,
      previousApplication: @escaping @MainActor () -> (PreviousApplication?, UserSpace.Snapshot),
      openApplication: @escaping @MainActor (
        Command.Application,
        CGEventType?,
        UserSpace.Snapshot,
      ) async throws -> Void,
      hideAllApps: @escaping @MainActor ([Command.Application]) async throws -> Void = {
        try await Operation.HideAllApps.live()($0)
      },
      minimizeAllOpenWindows: @escaping @MainActor ([String]?) async throws -> Void = {
        try await Operation.MinimizeAllWindows.live()($0)
      },
      executeScript: @escaping @MainActor (ScriptRequest) async throws -> String? = {
        try await ScriptCommandDispatcher(.production).execute($0)
      },
      fillAllOpenWindows: @escaping @MainActor () async throws -> Void = {
        try await Operation.FillAllWindows.live()()
      },
    ) {
      self.dock = Operation.Dock(sendNotification: sendDockNotification)
      self.activateLastApplication = Operation.ActivateLastApplication(
        previousApplication: previousApplication,
        openApplication: openApplication,
      )
      self.hideAllApps = hideAllApps
      self.minimizeAllOpenWindows = minimizeAllOpenWindows
      self.showNotificationCenter = Operation.ShowNotificationCenter(executeScript: executeScript)
      self.fillAllOpenWindows = fillAllOpenWindows
    }

    /// Checks cancellation before dispatch. An effect that already took place cannot be undone.
    public func run(_ action: Action) async throws -> Completion {
      try await run(action, workflowApplications: [])
    }

    /// For Hide All Apps, supply all application commands in workflow order.
    public func run(_ action: Action, workflowApplications: [Command.Application]) async throws -> Completion {
      try await run(action, workflowApplications: workflowApplications, visibleWindowOwners: nil)
    }

    /// Supply snapshot window-owner names for Minimize All. Nil uses the live inventory.
    public func run(
      _ action: Action,
      workflowApplications: [Command.Application] = [],
      visibleWindowOwners: [String]?,
    ) async throws -> Completion {
      try Task.checkCancellation()
      switch action {
      case .activateLastApplication: return try await activateLastApplication()
      case .missionControl: try dock(.missionControl)
      case .applicationWindows: try dock(.applicationWindows)
      case .showDesktop: try dock(.showDesktop)
      case .hideAllApps: try await hideAllApps(workflowApplications)
      case .minimizeAllOpenWindows: try await minimizeAllOpenWindows(visibleWindowOwners)
      case .showNotificationCenter: try await showNotificationCenter()
      case .fillAllOpenWindows: try await fillAllOpenWindows()
      }
      return .invoked
    }
  }
}
