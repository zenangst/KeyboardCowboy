import Darwin
import Foundation

extension Operation {
  @MainActor
  struct Dock {
    enum Action: String {
      case missionControl = "com.apple.expose.awake"
      case applicationWindows = "com.apple.expose.front.awake"
      case showDesktop = "com.apple.showdesktop.awake"
    }

    let sendNotification: @MainActor (Action) throws -> Void

    func callAsFunction(_ action: Action) throws {
      try sendNotification(action)
    }

    static func sendToDock(_ action: Action) throws {
      // v3's Dock package calls this private SPI and receives no status.
      // Resolve it dynamically so an OS change can be reported as a thrown error.
      let framework = "/System/Library/Frameworks/ApplicationServices.framework/Versions/A/ApplicationServices"
      guard let handle = dlopen(framework, RTLD_LAZY) else {
        throw SystemCommand.ExecutionError.dockUnavailable
      }

      defer { dlclose(handle) }
      guard let symbol = dlsym(handle, "CoreDockSendNotification") else {
        throw SystemCommand.ExecutionError.dockUnavailable
      }

      typealias SendNotification = @convention(c) (CFString, Int) -> Void
      let send = unsafeBitCast(symbol, to: SendNotification.self)
      send(action.rawValue as CFString, 0)
    }
  }
}
