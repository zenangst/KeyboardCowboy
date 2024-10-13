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

  @MainActor
  func resetFocusComponents() {
    centerFocus.reset()
    quarterFocus.reset()
    relativeFocus.reset()
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
            self.resetFocusComponents()
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
        try await SystemHideAllAppsRunner.run(workflowCommands: workflowCommands)
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
        try await relativeFocus.run(.up, snapshot: snapshot)
      case .moveFocusToNextWindowDownwards:
        try await relativeFocus.run(.down, snapshot: snapshot)
      case .moveFocusToNextWindowOnLeft:
        try await relativeFocus.run(.left, snapshot: snapshot)
      case .moveFocusToNextWindowOnRight:
        try await relativeFocus.run(.right, snapshot: snapshot)
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
        resetFocusComponents()
      case .windowTilingRight:
        try await SystemWindowTilingRunner.run(.right, snapshot: snapshot)
        resetFocusComponents()
      case .windowTilingTop:
        try await SystemWindowTilingRunner.run(.top, snapshot: snapshot)
        resetFocusComponents()
      case .windowTilingBottom:
        try await SystemWindowTilingRunner.run(.bottom, snapshot: snapshot)
        resetFocusComponents()
      case .windowTilingTopLeft:
        try await SystemWindowTilingRunner.run(.topLeft, snapshot: snapshot)
        resetFocusComponents()
      case .windowTilingTopRight:
        try await SystemWindowTilingRunner.run(.topRight, snapshot: snapshot)
        resetFocusComponents()
      case .windowTilingBottomLeft:
        try await SystemWindowTilingRunner.run(.bottomLeft, snapshot: snapshot)
        resetFocusComponents()
      case .windowTilingBottomRight:
        try await SystemWindowTilingRunner.run(.bottomRight, snapshot: snapshot)
        resetFocusComponents()
      case .windowTilingCenter:
        try await SystemWindowTilingRunner.run(.center, snapshot: snapshot)
        resetFocusComponents()
      case .windowTilingFill:
        try await SystemWindowTilingRunner.run(.fill, snapshot: snapshot)
        resetFocusComponents()
      case .windowTilingArrangeLeftRight:
        try await SystemWindowTilingRunner.run(.arrangeLeftRight, snapshot: snapshot)
        resetFocusComponents()
      case .windowTilingArrangeRightLeft:
        try await SystemWindowTilingRunner.run(.arrangeRightLeft, snapshot: snapshot)
        resetFocusComponents()
      case .windowTilingArrangeTopBottom:
        try await SystemWindowTilingRunner.run(.arrangeTopBottom, snapshot: snapshot)
        resetFocusComponents()
      case .windowTilingArrangeBottomTop:
        try await SystemWindowTilingRunner.run(.arrangeBottomTop, snapshot: snapshot)
        resetFocusComponents()
      case .windowTilingArrangeLeftQuarters:
        try await SystemWindowTilingRunner.run(.arrangeLeftQuarters, snapshot: snapshot)
        resetFocusComponents()
      case .windowTilingArrangeRightQuarters:
        try await SystemWindowTilingRunner.run(.arrangeRightQuarters, snapshot: snapshot)
        resetFocusComponents()
      case .windowTilingArrangeTopQuarters:
        try await SystemWindowTilingRunner.run(.arrangeTopQuarters, snapshot: snapshot)
        resetFocusComponents()
      case .windowTilingArrangeBottomQuarters:
        try await SystemWindowTilingRunner.run(.arrangeBottomQuarters, snapshot: snapshot)
        resetFocusComponents()
      case .windowTilingArrangeDynamicQuarters:
        try await SystemWindowTilingRunner.run(.arrangeDynamicQuarters, snapshot: snapshot)
        resetFocusComponents()
      case .windowTilingArrangeQuarters:
        try await SystemWindowTilingRunner.run(.arrangeQuarters, snapshot: snapshot)
        resetFocusComponents()
      case .windowTilingPreviousSize:
        try await SystemWindowTilingRunner.run(.previousSize, snapshot: snapshot)
        resetFocusComponents()
      case .windowTilingZoom:
        try await SystemWindowTilingRunner.run(.zoom, snapshot: snapshot)
        resetFocusComponents()
      }
    }
  }
}
