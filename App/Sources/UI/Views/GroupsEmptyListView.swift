import SwiftUI

struct GroupsEmptyListView: View {
  private let onAction: (GroupsView.Action) -> Void
  private let namespace: Namespace.ID

  init(_ namespace: Namespace.ID, onAction: @escaping (GroupsView.Action) -> Void) {
    self.namespace = namespace
    self.onAction = onAction
  }

  var body: some View {
    VStack {
      Button(action: {
        withAnimation {
          onAction(.openScene(.addGroup))
        }
      }, label: {
        HStack(spacing: 8) {
          Image(systemName: "plus.circle")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 16, height: 16)
          Divider()
            .opacity(0.5)
          Text("Add Group")
        }
        .padding(4)
      })
      .buttonStyle(GradientButtonStyle(.init(nsColor: .systemGreen, hoverEffect: false)))
      .frame(maxHeight: 32)
      .matchedGeometryEffect(id: "add-group-button", in: namespace)

      Text("No groups yet.\nAdd a group to get started.")
        .multilineTextAlignment(.center)
        .font(.footnote)
    }
    .padding(.top, 64)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
  }
}

struct GroupsEmptyListView_Previews: PreviewProvider {
  @Namespace static var namespace
  static var previews: some View {
    GroupsEmptyListView(namespace) { _ in }
      .designTime()
  }
}
