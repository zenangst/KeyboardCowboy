extension SystemCommand {
  enum Kind: String, Identifiable, Codable, CaseIterable {
    var id: String { rawValue }

    var displayValue: String {
      switch self {
      case .activateLastApplication: "Activate Last Application"
      case .applicationWindows: "Application Windows"
      case .minimizeAllOpenWindows: "Minimize All Open Windows"
      case .fillAllOpenWindows: "Maximize All Open Windows"
      case .hideAllApps: "Hide All Apps"
      case .missionControl: "Mission Control"
      case .showDesktop: "Show Desktop"
      case .showNotificationCenter: "Show Notification Center"
      }
    }

    var symbol: String {
      switch self {
      case .activateLastApplication: "arrow.counterclockwise.circle"
      case .applicationWindows: "rectangle.on.rectangle"
      case .minimizeAllOpenWindows: "arrow.down.right.and.arrow.up.left"
      case .fillAllOpenWindows: "square.and.arrow.up.on.square"
      case .hideAllApps: "eye.slash"
      case .missionControl: "square.grid.3x3"
      case .showDesktop: "desktopcomputer"
      case .showNotificationCenter: "app.badge"
      }
    }

    var iconPath: String {
      switch self {
      case .activateLastApplication: "/System/Library/CoreServices/Family.app"
      case .applicationWindows: "/System/Applications/Mission Control.app/Contents/Resources/AppIcon.icns"
      case .minimizeAllOpenWindows: "/System/Applications/Mission Control.app/Contents/Resources/AppIcon.icns"
      case .fillAllOpenWindows: "/System/Applications/Mission Control.app/Contents/Resources/AppIcon.icns"
      case .hideAllApps: "/System/Applications/Mission Control.app/Contents/Resources/AppIcon.icns"
      case .missionControl: "/System/Applications/Mission Control.app/Contents/Resources/AppIcon.icns"
      case .showDesktop: "/System/Library/CoreServices/Dock.app/Contents/Resources/Dock.icns"
      case .showNotificationCenter: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/Notifications.icns"
      }
    }

    case activateLastApplication
    case applicationWindows
    case fillAllOpenWindows
    case hideAllApps
    case minimizeAllOpenWindows
    case missionControl
    case showDesktop
    case showNotificationCenter
  }
}
