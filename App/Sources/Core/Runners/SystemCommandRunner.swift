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
  private let centerFocus: SystemWindowCenterFocus
  private let relativeFocus: SystemWindowRelativeFocus
  private let quarterFocus: SystemWindowQuarterFocus
  private let workspace: WorkspaceProviding

  private var flagsChangedSubscription: AnyCancellable?
  private var frontMostIndex: Int = 0
  private var visibleMostIndex: Int = 0

  init(_ applicationStore: ApplicationStore = .shared, 
       applicationActivityMonitor: ApplicationActivityMonitor<UserSpace.Application>,
       workspace: WorkspaceProviding = NSWorkspace.shared) {
    self.applicationStore = applicationStore
    self.applicationActivityMonitor = applicationActivityMonitor
    self.centerFocus = SystemWindowCenterFocus()
    self.relativeFocus = SystemWindowRelativeFocus()
    self.quarterFocus = SystemWindowQuarterFocus()
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
            self.centerFocus.reset()
            self.relativeFocus.reset()
            self.quarterFocus.reset()
          }
        }
      }
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
                                            checkCancellation: checkCancellation)
          }
        }
      case .hideAllApps:
        await SystemHideAllAppsRunner.run(workflowCommands: workflowCommands)
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
      case .moveFocusToNextWindowUpperLeftQuarter:
        try quarterFocus.run(.upperLeft, snapshot: snapshot)
      case .moveFocusToNextWindowUpperRightQuarter:
        try quarterFocus.run(.upperRight, snapshot: snapshot)
      case .moveFocusToNextWindowLowerLeftQuarter:
        try quarterFocus.run(.lowerLeft, snapshot: snapshot)
      case .moveFocusToNextWindowLowerRightQuarter:
        try quarterFocus.run(.lowerRight, snapshot: snapshot)
      case .moveFocusToNextWindowCenter:
        try await centerFocus.run(snapshot: snapshot)
      case .windowTilingLeft:
        try await SystemWindowTilingRunner.run(.left, snapshot: snapshot)
        quarterFocus.reset()
        centerFocus.reset()
      case .windowTilingRight:
        try await SystemWindowTilingRunner.run(.right, snapshot: snapshot)
        quarterFocus.reset()
        centerFocus.reset()
      case .windowTilingTop:
        try await SystemWindowTilingRunner.run(.top, snapshot: snapshot)
        quarterFocus.reset()
        centerFocus.reset()
      case .windowTilingBottom:
        try await SystemWindowTilingRunner.run(.bottom, snapshot: snapshot)
        quarterFocus.reset()
        centerFocus.reset()
      case .windowTilingTopLeft:
        try await SystemWindowTilingRunner.run(.topLeft, snapshot: snapshot)
        quarterFocus.reset()
        centerFocus.reset()
      case .windowTilingTopRight:
        try await SystemWindowTilingRunner.run(.topRight, snapshot: snapshot)
        quarterFocus.reset()
        centerFocus.reset()
      case .windowTilingBottomLeft:
        try await SystemWindowTilingRunner.run(.bottomLeft, snapshot: snapshot)
        quarterFocus.reset()
        centerFocus.reset()
      case .windowTilingBottomRight:
        try await SystemWindowTilingRunner.run(.bottomRight, snapshot: snapshot)
        quarterFocus.reset()
        centerFocus.reset()
      case .windowTilingCenter:
        try await SystemWindowTilingRunner.run(.center, snapshot: snapshot)
        quarterFocus.reset()
        centerFocus.reset()
      case .windowTilingFill:
        try await SystemWindowTilingRunner.run(.fill, snapshot: snapshot)
        quarterFocus.reset()
        centerFocus.reset()
      case .windowTilingArrangeLeftRight:
        try await SystemWindowTilingRunner.run(.arrangeLeftRight, snapshot: snapshot)
        quarterFocus.reset()
        centerFocus.reset()
      case .windowTilingArrangeRightLeft:
        try await SystemWindowTilingRunner.run(.arrangeRightLeft, snapshot: snapshot)
        quarterFocus.reset()
        centerFocus.reset()
      case .windowTilingArrangeTopBottom:
        try await SystemWindowTilingRunner.run(.arrangeTopBottom, snapshot: snapshot)
        quarterFocus.reset()
        centerFocus.reset()
      case .windowTilingArrangeBottomTop:
        try await SystemWindowTilingRunner.run(.arrangeBottomTop, snapshot: snapshot)
        quarterFocus.reset()
        centerFocus.reset()
      case .windowTilingArrangeLeftQuarters:
        try await SystemWindowTilingRunner.run(.arrangeLeftQuarters, snapshot: snapshot)
        quarterFocus.reset()
        centerFocus.reset()
      case .windowTilingArrangeRightQuarters:
        try await SystemWindowTilingRunner.run(.arrangeRightQuarters, snapshot: snapshot)
        quarterFocus.reset()
        centerFocus.reset()
      case .windowTilingArrangeTopQuarters:
        try await SystemWindowTilingRunner.run(.arrangeTopQuarters, snapshot: snapshot)
        quarterFocus.reset()
        centerFocus.reset()
      case .windowTilingArrangeBottomQuarters:
        try await SystemWindowTilingRunner.run(.arrangeBottomQuarters, snapshot: snapshot)
        quarterFocus.reset()
        centerFocus.reset()
      case .windowTilingArrangeQuarters:
        try await SystemWindowTilingRunner.run(.arrangeQuarters, snapshot: snapshot)
        quarterFocus.reset()
        centerFocus.reset()
      case .windowTilingPreviousSize:
        try await SystemWindowTilingRunner.run(.previousSize, snapshot: snapshot)
        quarterFocus.reset()
        centerFocus.reset()
      case .windowTilingZoom:
        try await SystemWindowTilingRunner.run(.zoom, snapshot: snapshot)
        quarterFocus.reset()
        centerFocus.reset()
      }
    }
  }
}
