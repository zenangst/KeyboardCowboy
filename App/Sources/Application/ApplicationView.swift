import SwiftUI
import ViewKit

enum ApplicationView: View {
  case hidden
  case needsPermission(PermissionsView)
  case content(MainView)

  var body: some View {
    switch self {
    case .hidden:
      Spacer()
    case .content(let view):
      view.frame(minWidth: 900, minHeight: 520)
    case .needsPermission(let view):
      view.frame(minWidth: 600, minHeight: 320)
    }
  }
}
