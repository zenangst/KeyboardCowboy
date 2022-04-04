import Apps
import SwiftUI

struct WorkflowListView: View, Equatable {
  @ObservedObject private var iO = Inject.observer
  enum Action {
    case delete(Workflow)
  }

  let applicationStore: ApplicationStore
  let store: GroupStore
  @Binding var workflows: [Workflow]
  @Binding var selection: Set<String>

  var action: (Action) -> Void

  var body: some View {
    ScrollViewReader { proxy in
      List(selection: $selection) {
        ForEach($workflows) { workflow in
          WorkflowRowView(applicationStore: applicationStore, workflow: workflow)
            .contextMenu { contextMenuView(workflow) }
            .id(workflow.id)
        }
        .onMove { indexSet, offset in
          workflows.move(fromOffsets: indexSet, toOffset: offset)
        }
      }
      .onChange(of: selection, perform: {
        proxy.scrollTo($0.first)
      })
      .onAppear(perform: {
        proxy.scrollTo(selection.first)
      })
      .listStyle(InsetListStyle())
      .onCopyCommand(perform: {
        workflows
          .filter { selection.contains($0.id) }
          .compactMap({ try? $0.asString() })
          .compactMap { NSItemProvider(object: $0 as NSString) }
      })
      .onPasteCommand(of: [.text], perform: { items in
        let decoder = JSONDecoder()
        guard var group = store.selectedGroups.first else { return }
        for item in items {
          item.loadObject(ofClass: NSString.self) { reading, error in
            guard let output = reading as? String,
                  let data = output.data(using: .utf8),
                  let workflow = try? decoder.decode(Workflow.self, from: data) else { return }
            DispatchQueue.main.async {
              workflows.append(workflow.copy())
              group.workflows = workflows
              store.updateGroups([group])
            }
          }
        }
      })
      .onDeleteCommand(perform: {
        let selectedWorkflows = workflows.filter { selection.contains($0.id) }
        store.remove(selectedWorkflows)
      })
    }
    .enableInjection()
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
  static var previews: some View {
    WorkflowListView(
      applicationStore: ApplicationStore(),
      store: groupStore,
      workflows: .constant(groupStore.selectedGroups.flatMap({ $0.workflows })),
      selection: .constant([]), action: { _ in })
      .previewLayout(.sizeThatFits)
  }
}
