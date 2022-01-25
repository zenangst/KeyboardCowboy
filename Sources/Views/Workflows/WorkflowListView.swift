import Apps
import SwiftUI

struct WorkflowListView: View {
  enum Action {
    case delete(Workflow)
  }
  @Binding var workflows: [Workflow]
  @Binding var selection: Set<String>

  var action: (Action) -> Void

  var body: some View {
    List($workflows, selection: $selection) { workflow in
      WorkflowRowView(workflow: workflow)
        .contextMenu { contextMenuView(workflow.wrappedValue) }
        .id(workflow.id)
    }
    .listStyle(InsetListStyle())
  }

  func contextMenuView(_ workflow: Workflow) -> some View {
    VStack {
      Button("Delete", action: { action(.delete(workflow)) })
    }
  }
}

struct WorkflowListView_Previews: PreviewProvider {
  static let store = Saloon()
  static var previews: some View {
    WorkflowListView(
      workflows: .constant(Array(store.selectedGroups.flatMap({ $0.workflows }))),
      selection: .constant([]), action: { _ in })
      .previewLayout(.sizeThatFits)
  }
}
