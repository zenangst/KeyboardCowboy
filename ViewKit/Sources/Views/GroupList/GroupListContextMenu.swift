import SwiftUI
import ModelKit

struct GroupListContextMenu: View {
  @Binding var sheet: GroupList.Sheet?
  let group: ModelKit.Group
  let deleteAction: (ModelKit.Group) -> Void

  var body: some View {
    Button("Show Info") { sheet = .edit(group) }
    Divider()
    Button("Delete", action: { onDelete(group) })
  }

  func onDelete(_ group: ModelKit.Group) {
    if group.workflows.isEmpty {
      deleteAction(group)
    } else {
      sheet = .delete(group)
    }
  }
}
