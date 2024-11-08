import SwiftUI

struct UserModeContainerView: View {
  private let onAction: (SidebarView.Action) -> Void

  init(onAction: @escaping (SidebarView.Action) -> Void) {
    self.onAction = onAction
  }

  var body: some View {
    UserModesView { action in
      onAction(.userMode(action))
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 4)
  }
}
