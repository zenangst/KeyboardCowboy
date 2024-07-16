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
  private let relativeFocus: SystemWindowRelativeFocus
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
        Task { @MainActor in
          WindowStore.shared.state.interactive = flags != CGEventFlags.maskNonCoalesced
          if WindowStore.shared.state.interactive == false {
            self.frontMostIndex = 0
            self.visibleMostIndex = 0
            self.relativeFocus.reset()
          }
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
        try relativeFocus.run(.up, snapshot: snapshot)
      case .moveFocusToNextWindowDownwards:
        try relativeFocus.run(.down, snapshot: snapshot)
      case .moveFocusToNextWindowOnLeft:
        try relativeFocus.run(.left, snapshot: snapshot)
      case .moveFocusToNextWindowOnRight:
        try relativeFocus.run(.right, snapshot: snapshot)
      case .windowTilingLeft:
        try await SystemWindowTilingRunner.run(.left, snapshot: snapshot)
      case .windowTilingRight:
        try await SystemWindowTilingRunner.run(.right, snapshot: snapshot)
      case .windowTilingTop:
        try await SystemWindowTilingRunner.run(.top, snapshot: snapshot)
      case .windowTilingBottom:
        try await SystemWindowTilingRunner.run(.bottom, snapshot: snapshot)
      case .windowTilingTopLeft:
        try await SystemWindowTilingRunner.run(.topLeft, snapshot: snapshot)
      case .windowTilingTopRight:
        try await SystemWindowTilingRunner.run(.topRight, snapshot: snapshot)
      case .windowTilingBottomLeft:
        try await SystemWindowTilingRunner.run(.bottomLeft, snapshot: snapshot)
      case .windowTilingBottomRight:
        try await SystemWindowTilingRunner.run(.bottomRight, snapshot: snapshot)
      case .windowTilingCenter:
        try await SystemWindowTilingRunner.run(.center, snapshot: snapshot)
      case .windowTilingFill:
        try await SystemWindowTilingRunner.run(.fill, snapshot: snapshot)
      case .windowTilingArrangeLeftRight:
        try await SystemWindowTilingRunner.run(.arrangeLeftRight, snapshot: snapshot)
      case .windowTilingArrangeRightLeft:
        try await SystemWindowTilingRunner.run(.arrangeRightLeft, snapshot: snapshot)
      case .windowTilingArrangeTopBottom:
        try await SystemWindowTilingRunner.run(.arrangeTopBottom, snapshot: snapshot)
      case .windowTilingArrangeBottomTop:
        try await SystemWindowTilingRunner.run(.arrangeBottomTop, snapshot: snapshot)
      case .windowTilingArrangeLeftQuarters:
        try await SystemWindowTilingRunner.run(.arrangeLeftQuarters, snapshot: snapshot)
      case .windowTilingArrangeRightQuarters:
        try await SystemWindowTilingRunner.run(.arrangeRightQuarters, snapshot: snapshot)
      case .windowTilingArrangeTopQuarters:
        try await SystemWindowTilingRunner.run(.arrangeTopQuarters, snapshot: snapshot)
      case .windowTilingArrangeBottomQuarters:
        try await SystemWindowTilingRunner.run(.arrangeBottomQuarters, snapshot: snapshot)
      case .windowTilingArrangeQuarters:
        try await SystemWindowTilingRunner.run(.arrangeQuarters, snapshot: snapshot)
      case .windowTilingPreviousSize:
        try await SystemWindowTilingRunner.run(.previousSize, snapshot: snapshot)
      }
    }
  }
}
