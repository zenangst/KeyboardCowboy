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
  private let applicationActivityMonitor: ApplicationActivityMonitor<UserSpace.Application>
  private let workspace: WorkspaceProviding

  private var flagsChangedSubscription: AnyCancellable?
  private var frontMostIndex: Int = 0
  private var visibleMostIndex: Int = 0

  init(_ applicationStore: ApplicationStore = .shared, 
       applicationActivityMonitor: ApplicationActivityMonitor<UserSpace.Application>,
       workspace: WorkspaceProviding = NSWorkspace.shared) {
    self.applicationStore = applicationStore
    self.applicationActivityMonitor = applicationActivityMonitor
    self.relativeFocus = SystemWindowRelativeFocus()
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
           checkCancellation: Bool, snapshot: UserSpace.Snapshot) async throws {
    Task { @MainActor in
      switch command.kind {
      case .activateLastApplication:
        Task {
          if let previousApplication = applicationActivityMonitor.previousApplication() {
            try await applicationRunner.run(.init(application: previousApplication.asApplication()),
                                            checkCancellation: checkCancellation)
          }
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
        SystemFrontmostWindowFocus.run(kind: command.kind, snapshot: snapshot)
      case .minimizeAllOpenWindows:
        guard let machPort else { return }
        try SystemMinimizeAllWindows.run(snapshot, machPort: machPort)
      case .showDesktop:
        Dock.run(.showDesktop)
      case .applicationWindows:
        Dock.run(.applicationWindows)
      case .missionControl:
        Dock.run(.missionControl)
      case .moveFocusToNextWindowUpwards:
        try SystemWindowRelativeFocus.run(.up, snapshot: snapshot)
      case .moveFocusToNextWindowDownwards:
        try SystemWindowRelativeFocus.run(.down, snapshot: snapshot)
      case .moveFocusToNextWindowOnLeft:
        try SystemWindowRelativeFocus.run(.left, snapshot: snapshot)
      case .moveFocusToNextWindowOnRight:
        try SystemWindowRelativeFocus.run(.right, snapshot: snapshot)
      }
    }
  }
}
