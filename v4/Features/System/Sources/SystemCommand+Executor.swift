import ApplicationsFeature
import Commands
import CoreGraphics
import Darwin
import Foundation
import UserSpace

public enum SystemCommand {
  public enum Action: String, Codable, CaseIterable, Sendable {
    case activateLastApplication
    case missionControl
    case applicationWindows
    case showDesktop
  }

  public enum Completion: Equatable, Sendable {
    /// The Dock function returned; this does not confirm any visible effect.
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
    struct PreviousApplication {
      let bundleIdentifier: String
      let bundleURL: URL?
    }

    private let sendDockNotification: @MainActor (String) throws -> Void
    private let previousApplication: @MainActor () -> (PreviousApplication?, UserSpace.Snapshot)
    private let openApplication: @MainActor (Command.Application, CGEventType?, UserSpace.Snapshot) async throws -> Void

    /// Keep the executor (or its shared UserSpace) alive to accumulate activation history.
    public init() {
      self.init(
        userSpace: UserSpace(.production),
        applicationExecutor: Application.Executor(.production),
      )
    }

    public init(userSpace: UserSpace, applicationExecutor: Application.Executor) {
      self.init(
        sendDockNotification: Self.sendToDock,
        previousApplication: {
          let snapshot = userSpace.takeSnapshot()
          let previous = snapshot.apps.previous.flatMap { app -> PreviousApplication? in
            guard !app.runningApplication.isTerminated else { return nil }

            return PreviousApplication(bundleIdentifier: app.bundleIdentifier.value, bundleURL: app.runningApplication.bundleURL)
          }
          return (previous, snapshot)
        },
        openApplication: { command, event, snapshot in
          _ = try await applicationExecutor.execute(command, cgEventType: event, snapshot: snapshot)
        },
      )
    }

    init(
      sendDockNotification: @escaping @MainActor (String) throws -> Void,
      previousApplication: @escaping @MainActor () -> (PreviousApplication?, UserSpace.Snapshot),
      openApplication: @escaping @MainActor (Command.Application, CGEventType?, UserSpace.Snapshot) async throws -> Void,
    ) {
      self.sendDockNotification = sendDockNotification
      self.previousApplication = previousApplication
      self.openApplication = openApplication
    }

    /// Checks cancellation before dispatch. An effect that already took place cannot be undone.
    public func run(_ action: Action) async throws -> Completion {
      try Task.checkCancellation()
      switch action {
      case .activateLastApplication: return try await activateLastApplication()
      case .missionControl: try sendDockNotification("com.apple.expose.awake")
      case .applicationWindows: try sendDockNotification("com.apple.expose.front.awake")
      case .showDesktop: try sendDockNotification("com.apple.showdesktop.awake")
      }
      return .invoked
    }

    private func activateLastApplication() async throws -> Completion {
      let (previous, snapshot) = previousApplication()
      try Task.checkCancellation()
      guard let previous else { return .noPreviousApplication }
      guard let url = previous.bundleURL else {
        throw ExecutionError.missingPreviousApplicationBundleURL(previous.bundleIdentifier)
      }

      let bundle = Bundle(url: url)
      let name = bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? url.deletingPathExtension().lastPathComponent
      let command = Command.Application(application: .init(
        bundleIdentifier: previous.bundleIdentifier, bundleName: name, path: url.path,
      ))
      try await openApplication(command, nil, snapshot)
      return .applicationOpenCompleted
    }

    private static func sendToDock(_ notification: String) throws {
      // v3's Dock package calls this private SPI and receives no status.
      // Resolve it dynamically so an OS change can be reported as a thrown error.
      let framework = "/System/Library/Frameworks/ApplicationServices.framework/Versions/A/ApplicationServices"
      guard let handle = dlopen(framework, RTLD_LAZY) else {
        throw ExecutionError.dockUnavailable
      }

      defer { dlclose(handle) }
      guard let symbol = dlsym(handle, "CoreDockSendNotification") else {
        throw ExecutionError.dockUnavailable
      }

      typealias SendNotification = @convention(c) (CFString, Int) -> Void
      let send = unsafeBitCast(symbol, to: SendNotification.self)
      send(notification as CFString, 0)
    }
  }
}
