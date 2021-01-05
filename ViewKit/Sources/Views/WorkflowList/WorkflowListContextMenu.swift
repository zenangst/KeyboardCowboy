import SwiftUI
import ModelKit

struct WorkflowListContextMenu: View {
  let store: ViewKitStore
  let workflow: Workflow
  @Binding var selections: Set<String>
  @AppStorage("groupSelection") var groupSelection: String?

  var body: some View {
    Menu("Move To Group", content: {
      ForEach(store.groups.filter({ $0.id != groupSelection })) { group in
        Button(group.name, action: {
          store.context.workflows.perform(.transfer(selections, to: group))
        })
      }
    })
    Divider()
    Button("Duplicate", action: { store.context.workflows.perform(.duplicate(workflow, groupId: groupSelection)) })
    Button("Delete", action: { store.context.workflows.perform(.delete(workflow)) })
  }
}
