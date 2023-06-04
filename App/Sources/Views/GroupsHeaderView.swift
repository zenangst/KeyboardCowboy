import SwiftUI

struct GroupsHeaderView: View {
  enum Action {
    case addGroup
  }

  private let onAction: (Action) -> Void

  init(onAction: @escaping (Action) -> Void) {
    self.onAction = onAction
  }

  var body: some View {
    HStack {
      Label("Groups", image: "")
        .padding(.top)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.horizontal, 12)
  }
}

struct GroupsHeaderView_Previews: PreviewProvider {
  static var previews: some View {
    GroupsHeaderView { _ in }
  }
}
