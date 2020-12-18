import SwiftUI
import ModelKit

public struct WorkflowList: View {
  public enum Action {
    case set(workflow: Workflow)
    case create(groupId: String?)
    case update(Workflow)
    case delete(Workflow)
    case move(Workflow, to: Int)
    case drop([URL], String?, Workflow?)
  }

  @AppStorage("groupSelection") var groupSelection: String?

  let store: ViewKitStore
  let title: String
  let subtitle: String
  let workflows: [Workflow]

  @Binding var selection: String?
  @State var isDropping: Bool = false

  public var body: some View {
    List {
      ForEach(workflows, id: \.id) { workflow in
        NavigationLink(
          destination: DetailView(context: store.context,
                                  workflowController: store.context.workflow),
          tag: workflow.id,
          selection: $selection,
          label: {
            WorkflowListView(workflow: workflow)
          })
          .contextMenu {
            Button("Delete", action: { store.context.workflow.perform(.delete(workflow)) })
          }
      }
      .onMove(perform: { indices, newOffset in
        for i in indices {
          store.context.workflow.perform(.move(workflows[i], to: newOffset))
        }
      })
    }
    .navigationTitle(title)
    .navigationSubtitle(subtitle)
    .onDrop($isDropping) { urls in
      store.context.workflow.perform(.drop(urls, groupSelection, nil))
    }
    .onDeleteCommand(perform: {
      if let workflow = store.selectedWorkflow {
        store.context.workflow.perform(.delete(workflow))
      }
    })
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(Color.accentColor, lineWidth: isDropping ? 5 : 0)
        .padding(4)
    )
    .toolbar(content: {
      WorkflowListToolbar(groupId: groupSelection, workflowController: store.context.workflow)
    })
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
      store: .init(
        groups: groups,
        context: .preview()),
      title: "",
      subtitle: "",
      workflows: groups.first?.workflows ?? [],
      selection: .constant(groups.first?.id))
  }
}
