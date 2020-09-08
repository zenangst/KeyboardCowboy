import SwiftUI

struct GroupList: View {
  static let idealWidth: CGFloat = 200

  let groups: [Group]
  @State private var selection: Group?

  var body: some View {
    NavigationView {
      List {
        ForEach(groups) { group in
          NavigationLink(
            destination: WorkflowList(workflows: group.workflows),
            tag: group,
            selection: $selection
          ) {
            GroupListCell(group: group)
          }
        }
        .onAppear(perform: {
          selection = groups.first
        })
      }
      .listStyle(SidebarListStyle())
      .frame(minWidth: 200, idealWidth: Self.idealWidth, maxWidth: 200, maxHeight: .infinity)
    }
  }
}

// MARK: - Previews

struct GroupList_Previews: PreviewProvider {
  static var previews: some View {
    GroupList(groups: ModelFactory().groupList())
  }
}
