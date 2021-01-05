import BridgeKit
import Introspect
import ModelKit
import SwiftUI

public struct WorkflowList: View {
  public enum Action {
    case set(group: ModelKit.Group)
    case create(groupId: String?)
    case duplicate(Workflow, groupId: String?)
    case update(Workflow)
    case delete(Workflow)
    case deleteMultiple(Set<String>)
    case move(Workflow, to: Int)
    case transfer(Set<String>, to: ModelKit.Group)
    case drop([URL], String?, Workflow?)
  }

  @AppStorage("groupSelection") var groupSelection: String?
  let store: ViewKitStore
  @ObservedObject var workflowsController: WorkflowsController
  @Binding var workflowSelections: Set<String>
  @State var isDropping: Bool = false

  public var body: some View {
    List(selection: $workflowSelections) {
      ForEach(workflowsController.state, id: \.id) { workflow in
        WorkflowListView(workflow: workflow)
          .contextMenu {
            WorkflowListContextMenu(store: store, workflow: workflow,
                                    selections: $workflowSelections)
          }
        .tag(workflow.id)
      }
      .onMove(perform: { indices, newOffset in
        for i in indices {
          workflowsController.perform(.move(workflowsController.state[i], to: newOffset))
        }
      })
    }
    .introspectTableView { tableView in
      tableView.rowHeight = 56
    }
    .onDrop($isDropping) { urls in
      workflowsController.perform(.drop(urls, groupSelection, nil))
    }
    .onDeleteCommand(perform: {
      workflowsController.perform(.deleteMultiple(workflowSelections))
    })
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(Color.accentColor, lineWidth: isDropping ? 5 : 0)
        .padding(4)
    )
  }
}

// MARK: Previews

struct WorkflowList_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    let groups = ModelFactory().groupList()
    return WorkflowList(
      store: ViewKitStore.preview(),
      workflowsController: WorkflowsPreviewController().erase(),
      workflowSelections: .constant(Set<String>(arrayLiteral: groups.first!.id)))
  }
}
