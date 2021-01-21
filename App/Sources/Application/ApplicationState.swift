import ViewKit
import SwiftUI

enum ApplicationState: Equatable {
  static func == (lhs: ApplicationState, rhs: ApplicationState) -> Bool {
    lhs.stringValue == rhs.stringValue
  }

  case launching
  case needsPermission(PermissionsView)
  case content(MainView)

  var stringValue: String {
    switch self {
    case .content:
      return "content"
    case .launching:
      return "launching"
    case .needsPermission:
      return "needsPermission"
    }
  }

  var currentView: AnyView? {
    switch self {
    case .launching:
      return nil
    case .needsPermission(let view):
      return view.erase()
    case .content(let view):
      return view.erase()
    }
  }
}
