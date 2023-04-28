import SwiftUI

struct GroupHeaderView: View {
  @ObservedObject private var groupSelectionManager: SelectionManager<GroupViewModel>
  let data: [GroupViewModel]

  init(groupSelectionManager: SelectionManager<GroupViewModel>, data: [GroupViewModel]) {
    self.groupSelectionManager = groupSelectionManager
    self.data = data
  }

  var body: some View {
    VStack(alignment: .leading) {
      if let groupId = groupSelectionManager.selections.first,
         let group = data.first(where: { $0.id == groupId }) {
        Label("Group", image: "")
          .labelStyle(SidebarLabelStyle())
          .padding(.leading, 8)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.top, 6)
        HStack(spacing: 8) {
          GroupIconView(color: group.color, icon: group.icon, symbol: group.symbol)
            .frame(width: 24, height: 24)
            .padding(4)
            .background(
              RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .init(hex: group.color)).opacity(0.4))
            )
          VStack(alignment: .leading) {
            Text(group.name)
              .font(.headline)
            Text("Workflows: \(group.count)")
              .font(.caption)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.bottom, 4)
        .padding(.leading, 14)
        .id(group)
      }

      Label("Workflows", image: "")
        .labelStyle(SidebarLabelStyle())
        .padding(.leading, 8)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

  }
}
