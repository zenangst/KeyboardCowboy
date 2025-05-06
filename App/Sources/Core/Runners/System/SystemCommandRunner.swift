import Apps
import AXEssibility
import Cocoa
import Combine
import Dock
import Foundation
import MachPort
import Windows

final class SystemCommandRunner: @unchecked Sendable {
  var machPort: MachPortEventController?

  private let applicationActivityMonitor: ApplicationActivityMonitor<UserSpace.Application>
  private let applicationStore: ApplicationStore
  private let workspace: WorkspaceProviding

  init(_ applicationStore: ApplicationStore = .shared, 
       applicationActivityMonitor: ApplicationActivityMonitor<UserSpace.Application>,
       workspace: WorkspaceProviding = NSWorkspace.shared) {
    self.applicationStore = applicationStore
    self.applicationActivityMonitor = applicationActivityMonitor
    self.workspace = workspace
  }

  func run(_ command: SystemCommand, workflowCommands: [Command], applicationRunner: ApplicationCommandRunner,
           runtimeDictionary: [String: String],
           checkCancellation: Bool, snapshot: UserSpace.Snapshot) async throws {
    Task { @MainActor in
      switch command.kind {
      case .activateLastApplication:
        Task {
          if let previousApplication = applicationActivityMonitor.previousApplication() {
            try await applicationRunner.run(.init(application: previousApplication.asApplication()),
                                            machPortEvent: nil,
                                            checkCancellation: checkCancellation,
                                            snapshot: UserSpace.shared.snapshot(resolveUserEnvironment: false))
          }
        }
      case .fillAllOpenWindows:
        await SystemFillAllWindowsRunner.run(snapshot: UserSpace.shared.snapshot(resolveUserEnvironment: false))
      case .hideAllApps:
        let targetApplication: Application? = workflowCommands.compactMap {
          switch $0 {
          case .application(let command): command.application
          default: nil
          }
        }.last
        try await SystemHideAllAppsRunner.run(targetApplication: targetApplication, checkCancellation: checkCancellation, workflowCommands: workflowCommands)
      case .minimizeAllOpenWindows:
        guard let machPort else { return }
        try SystemMinimizeAllWindows.run(snapshot, machPort: machPort)
      case .showDesktop:
        Dock.run(.showDesktop)
      case .applicationWindows:
        Dock.run(.applicationWindows)
      case .missionControl:
        Dock.run(.missionControl)
      }
    }
  }
}
