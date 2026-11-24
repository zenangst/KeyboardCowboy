import Darwin
import Foundation

public enum SystemCommand {
  public enum Action: String, Codable, CaseIterable, Sendable {
    case missionControl
    case applicationWindows
    case showDesktop

    fileprivate var dockNotification: String {
      switch self {
      case .missionControl: "com.apple.expose.awake"
      case .applicationWindows: "com.apple.expose.front.awake"
      case .showDesktop: "com.apple.showdesktop.awake"
      }
    }
  }

  public enum Completion: Equatable, Sendable {
    /// The Dock function returned; this does not confirm any visible effect.
    case invoked
  }

  public enum ExecutionError: Error, Equatable {
    case dockUnavailable
  }

  @MainActor
  public struct Executor {
    private let sendDockNotification: @MainActor (String) throws -> Void

    public init() {
      self.init(sendDockNotification: Self.sendToDock)
    }

    init(sendDockNotification: @escaping @MainActor (String) throws -> Void) {
      self.sendDockNotification = sendDockNotification
    }

    /// Checks cancellation before invoking Dock. An invocation cannot be undone.
    public func run(_ action: Action) throws -> Completion {
      try Task.checkCancellation()
      try sendDockNotification(action.dockNotification)
      return .invoked
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
