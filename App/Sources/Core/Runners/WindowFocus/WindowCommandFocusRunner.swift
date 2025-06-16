import Apps
import AXEssibility
import Cocoa
import Combine
import Dock
import Foundation
import MachPort
import Windows

@MainActor
final class WindowCommandFocusRunner {
  private let applicationStore: ApplicationStore
  private let centerFocus: WindowFocusCenter
  private let relativeFocus: WindowFocusRelativeFocus
  private let quarterFocus: WindowFocusQuarter
  private let workspace: WorkspaceProviding

  private var flagsChangedSubscription: AnyCancellable?
  private var frontmostIndex: Int = 0
  private var visibleMostIndex: Int = 0

  init(applicationStore: ApplicationStore = .shared,
       centerFocus: WindowFocusCenter, relativeFocus: WindowFocusRelativeFocus,
       quarterFocus: WindowFocusQuarter,
       workspace: WorkspaceProviding = NSWorkspace.shared) {
    self.applicationStore = applicationStore
    self.centerFocus = centerFocus
    self.relativeFocus = relativeFocus
    self.quarterFocus = quarterFocus
    self.workspace = workspace
  }

  func resetFocusComponents() {
    centerFocus.reset()
    quarterFocus.reset()
    relativeFocus.reset()
  }

  func run(_ command: WindowFocusCommand, snapshot: UserSpace.Snapshot) async throws {
    switch command.kind {
    case .moveFocusToNextWindowUpwards:
      try await relativeFocus.run(.up, snapshot: snapshot)
      quarterFocus.reset()
    case .moveFocusToNextWindowDownwards:
      try await relativeFocus.run(.down, snapshot: snapshot)
      quarterFocus.reset()
    case .moveFocusToNextWindowOnLeft:
      try await relativeFocus.run(.left, snapshot: snapshot)
      quarterFocus.reset()
    case .moveFocusToNextWindowOnRight:
      try await relativeFocus.run(.right, snapshot: snapshot)
      quarterFocus.reset()
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
    case .moveFocusToNextWindow, .moveFocusToPreviousWindow,
        .moveFocusToNextWindowGlobal, .moveFocusToPreviousWindowGlobal:
      try WindowFocus.run(
        &visibleMostIndex,
        kind: command.kind,
        snapshot: snapshot.windows,
        applicationStore: applicationStore,
        workspace: workspace
      )
    case .moveFocusToNextWindowFront, .moveFocusToPreviousWindowFront:
      WindowFocusFrontmostWindow.run(kind: command.kind, snapshot: snapshot)
    }
  }
}
