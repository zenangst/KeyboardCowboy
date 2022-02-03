import Apps
import SwiftUI

struct WorkflowListView: View, Equatable {
  enum Action {
    case delete(Workflow)
  }

  let store: WorkflowGroupStore
  @Binding var workflows: [Workflow]
  @Binding var selection: Set<String>

  var action: (Action) -> Void

  var body: some View {
    ScrollViewReader { proxy in
      List($workflows, selection: $selection) { workflow in
        WorkflowRowView(workflow: workflow)
          .contextMenu { contextMenuView(workflow) }
          .id(workflow.id)
      }
      .onChange(of: selection, perform: {
        proxy.scrollTo($0.first)
      })
      .onAppear(perform: {
        proxy.scrollTo(selection.first)
      })
      .listStyle(InsetListStyle())
      .onDeleteCommand(perform: {
        let selectedWorkflows = workflows.filter { selection.contains($0.id) }
        store.remove(selectedWorkflows)
      })
    }
  }

  func contextMenuView(_ workflow: Binding<Workflow>) -> some View {
    VStack {
      Button("Delete", action: { action(.delete(workflow.wrappedValue)) })
    }
  }

  static func == (lhs: WorkflowListView, rhs: WorkflowListView) -> Bool {
    lhs.workflows == rhs.workflows
  }
}

struct WorkflowListView_Previews: PreviewProvider {
  static let store = Saloon()
  static var previews: some View {
    WorkflowListView(
      store: store.groupStore,
      workflows: .constant(store.groupStore.selectedGroups.flatMap({ $0.workflows })),
      selection: .constant([]), action: { _ in })
      .previewLayout(.sizeThatFits)
  }
}
