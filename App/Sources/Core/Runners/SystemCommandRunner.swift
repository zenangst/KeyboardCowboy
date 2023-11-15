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

  private let applicationStore: ApplicationStore
  private var flagsChangedSubscription: AnyCancellable?
  private let workspace: WorkspaceProviding

  private var frontMostIndex: Int = 0
  private var visibleMostIndex: Int = 0

  init(_ applicationStore: ApplicationStore, workspace: WorkspaceProviding = NSWorkspace.shared) {
    self.applicationStore = applicationStore
    self.workspace = workspace
  }

  func subscribe(to publisher: Published<CGEventFlags?>.Publisher) {
    flagsChangedSubscription = publisher
      .compactMap { $0 }
      .sink { [weak self] flags in
        guard let self else { return }
        WindowStore.shared.state.interactive = flags != CGEventFlags.maskNonCoalesced
        if WindowStore.shared.state.interactive == false {
          self.frontMostIndex = 0
          self.visibleMostIndex = 0
        }
      }
  }

  func run(_ command: SystemCommand, applicationRunner: ApplicationCommandRunner, 
           snapshot: UserSpace.Snapshot) async throws {
    try await MainActor.run {
      switch command.kind {
      case .activateLastApplication:
        Task {
          let previousApplication = snapshot.previousApplication
          try await applicationRunner.run(.init(application: previousApplication.asApplication()))
        }
      case .moveFocusToNextWindow, .moveFocusToPreviousWindow,
           .moveFocusToNextWindowGlobal, .moveFocusToPreviousWindowGlobal:
        try SystemWindowFocus.run(
          &visibleMostIndex,
          kind: command.kind,
          snapshot: snapshot.windows,
          applicationStore: applicationStore,
          workspace: workspace
        )
      case .moveFocusToNextWindowFront, .moveFocusToPreviousWindowFront:
        SystemFrontmostWindowFocus.run(
          &frontMostIndex,
          kind: command.kind,
          snapshot: snapshot
        )
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

