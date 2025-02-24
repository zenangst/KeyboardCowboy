import Foundation

final class SystemMigrator {
  static func migrateIfNeeded(_ systemCommand: SystemCommand) -> Command {
    switch systemCommand.kind {
    case .activateLastApplication: return .systemCommand(systemCommand)
    case .applicationWindows: return .systemCommand(systemCommand)
    case .minimizeAllOpenWindows: return .systemCommand(systemCommand)
    case .hideAllApps: return .systemCommand(systemCommand)
    case .missionControl: return .systemCommand(systemCommand)
    case .showDesktop: return .systemCommand(systemCommand)

    // Window Focus
    case .moveFocusToNextWindowOnLeft: return .windowFocus(.init(kind: .moveFocusToNextWindowOnLeft, meta: systemCommand.meta))
    case .moveFocusToNextWindowOnRight: return .windowFocus(.init(kind: .moveFocusToNextWindowOnRight, meta: systemCommand.meta))
    case .moveFocusToNextWindowUpwards: return .windowFocus(.init(kind: .moveFocusToNextWindowUpwards, meta: systemCommand.meta))
    case .moveFocusToNextWindowDownwards: return .windowFocus(.init(kind: .moveFocusToNextWindowDownwards, meta: systemCommand.meta))
    case .moveFocusToNextWindowUpperLeftQuarter: return .windowFocus(.init(kind: .moveFocusToNextWindowUpperLeftQuarter, meta: systemCommand.meta))
    case .moveFocusToNextWindowUpperRightQuarter: return .windowFocus(.init(kind: .moveFocusToNextWindowUpperRightQuarter, meta: systemCommand.meta))
    case .moveFocusToNextWindowLowerLeftQuarter: return .windowFocus(.init(kind: .moveFocusToNextWindowLowerLeftQuarter, meta: systemCommand.meta))
    case .moveFocusToNextWindowLowerRightQuarter: return .windowFocus(.init(kind: .moveFocusToNextWindowLowerRightQuarter, meta: systemCommand.meta))
    case .moveFocusToNextWindowCenter: return .windowFocus(.init(kind: .moveFocusToNextWindowCenter, meta: systemCommand.meta))
    case .moveFocusToNextWindowFront: return .windowFocus(.init(kind: .moveFocusToNextWindowFront, meta: systemCommand.meta))
    case .moveFocusToPreviousWindowFront: return .windowFocus(.init(kind: .moveFocusToPreviousWindowFront, meta: systemCommand.meta))
    case .moveFocusToNextWindow: return .windowFocus(.init(kind: .moveFocusToNextWindow, meta: systemCommand.meta))
    case .moveFocusToPreviousWindow: return .windowFocus(.init(kind: .moveFocusToPreviousWindow, meta: systemCommand.meta))
    case .moveFocusToNextWindowGlobal: return .windowFocus(.init(kind: .moveFocusToNextWindowGlobal, meta: systemCommand.meta))
    case .moveFocusToPreviousWindowGlobal: return .windowFocus(.init(kind: .moveFocusToPreviousWindowGlobal, meta: systemCommand.meta))

    // Window Tiling
    case .windowTilingLeft: return .windowTiling(.init(kind: .left, meta: systemCommand.meta))
    case .windowTilingRight: return .windowTiling(.init(kind: .right, meta: systemCommand.meta))
    case .windowTilingTop: return .windowTiling(.init(kind: .top, meta: systemCommand.meta))
    case .windowTilingBottom: return .windowTiling(.init(kind: .bottom, meta: systemCommand.meta))
    case .windowTilingTopLeft: return .windowTiling(.init(kind: .topLeft, meta: systemCommand.meta))
    case .windowTilingTopRight: return .windowTiling(.init(kind: .topRight, meta: systemCommand.meta))
    case .windowTilingBottomLeft: return .windowTiling(.init(kind: .bottomLeft, meta: systemCommand.meta))
    case .windowTilingBottomRight: return .windowTiling(.init(kind: .bottomRight, meta: systemCommand.meta))
    case .windowTilingCenter: return .windowTiling(.init(kind: .center, meta: systemCommand.meta))
    case .windowTilingFill: return .windowTiling(.init(kind: .fill, meta: systemCommand.meta))
    case .windowTilingZoom: return .windowTiling(.init(kind: .zoom, meta: systemCommand.meta))
    case .windowTilingArrangeLeftRight: return .windowTiling(.init(kind: .arrangeLeftRight, meta: systemCommand.meta))
    case .windowTilingArrangeRightLeft: return .windowTiling(.init(kind: .arrangeRightLeft, meta: systemCommand.meta))
    case .windowTilingArrangeTopBottom: return .windowTiling(.init(kind: .arrangeTopBottom, meta: systemCommand.meta))
    case .windowTilingArrangeBottomTop: return .windowTiling(.init(kind: .arrangeBottomTop, meta: systemCommand.meta))
    case .windowTilingArrangeLeftQuarters: return .windowTiling(.init(kind: .arrangeLeftQuarters, meta: systemCommand.meta))
    case .windowTilingArrangeRightQuarters: return .windowTiling(.init(kind: .arrangeRightQuarters, meta: systemCommand.meta))
    case .windowTilingArrangeTopQuarters: return .windowTiling(.init(kind: .arrangeTopQuarters, meta: systemCommand.meta))
    case .windowTilingArrangeBottomQuarters: return .windowTiling(.init(kind: .arrangeBottomQuarters, meta: systemCommand.meta))
    case .windowTilingArrangeDynamicQuarters: return .windowTiling(.init(kind: .arrangeDynamicQuarters, meta: systemCommand.meta))
    case .windowTilingArrangeQuarters: return .windowTiling(.init(kind: .arrangeQuarters, meta: systemCommand.meta))
    case .windowTilingPreviousSize: return .windowTiling(.init(kind: .previousSize, meta: systemCommand.meta))
    }
  }
}
