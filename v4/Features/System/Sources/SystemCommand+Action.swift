public extension SystemCommand {
  enum Action: String, Codable, CaseIterable, Sendable {
    case activateLastApplication
    case missionControl
    case applicationWindows
    case showDesktop
    case hideAllApps
    case minimizeAllOpenWindows
    case showNotificationCenter
    case fillAllOpenWindows
  }
}
