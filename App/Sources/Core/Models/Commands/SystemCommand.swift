import Foundation

struct SystemCommand: Identifiable, Equatable, Codable, Hashable, Sendable {
  enum Kind: String, Identifiable, Codable, CaseIterable {
    var id: String { rawValue }

    var displayValue: String {
      switch self {
      case .applicationWindows:
        return "Application windows"
      case .missionControl:
        return "Mission Control"
      case .showDesktop:
        return "Show Desktop"
      case .moveFocusToNextWindowGlobal:
        return "Move focus to next window (all windows)"
      case .moveFocusToPreviousWindowGlobal:
        return "Move focus to previous window (all windows)"
      case .moveFocusToNextWindow:
        return "Move focus to next window"
      case .moveFocusToPreviousWindow:
        return "Move focus to previous window"
      case .moveFocusToNextWindowFront:
        return "Move focus to next window of active application"
      case .moveFocusToPreviousWindowFront:
        return "Move focus to previous window of active application"
      }
    }

    case applicationWindows
    case moveFocusToNextWindowFront
    case moveFocusToPreviousWindowFront
    case moveFocusToNextWindow
    case moveFocusToPreviousWindow
    case moveFocusToNextWindowGlobal
    case moveFocusToPreviousWindowGlobal
    case missionControl
    case showDesktop
  }
  var id: String
  var name: String
  var kind: Kind
  var isEnabled: Bool = true
  var notification: Bool
}
