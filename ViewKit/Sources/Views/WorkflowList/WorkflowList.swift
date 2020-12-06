import SwiftUI
import ModelKit
import Introspect

public struct WorkflowList: View {
  public enum Action {
    case createWorkflow(in: ModelKit.Group)
    case updateWorkflow(Workflow, in: ModelKit.Group)
    case deleteWorkflow(Workflow, in: ModelKit.Group)
    case moveWorkflow(Workflow, to: Int, in: ModelKit.Group)
    case drop([URL], Workflow?, in: ModelKit.Group)
  }

  static let idealWidth: CGFloat = 300
  @EnvironmentObject var userSelection: UserSelection
  let factory: ViewFactory
  let group: ModelKit.Group
  let searchController: SearchController
  let workflowController: WorkflowController
  @State private var isDropping: Bool = false
  @State var selection: Workflow?

  public var body: some View {
    if userSelection.searchQuery.isEmpty {
      List(selection: Binding<Workflow?>(
            get: { selection },
            set: {
              selection = $0
              userSelection.workflow = $0
            }) ) {
        ForEach(group.workflows, id: \.self) { workflow in
          WorkflowListCell(workflow: workflow)
            .tag(workflow)
            .frame(height: 48)
            .contextMenu {
              Button("Delete") {
                workflowController.perform(.deleteWorkflow(workflow, in: group))
              }.keyboardShortcut(.delete, modifiers: [])
            }
        }.onMove { indices, newOffset in
          for i in indices {
            let workflow = group.workflows[i]
            workflowController.perform(.moveWorkflow(workflow, to: newOffset, in: group))
          }
        }.onDelete { indexSet in
          for index in indexSet {
            let workflow = group.workflows[index]
            workflowController.perform(.deleteWorkflow(workflow, in: group))
          }
        }.onInsert(of: []) { _, _ in }
      }
      .onDrop($isDropping) {
        workflowController.perform(.drop($0, nil, in: group))
      }
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(Color.accentColor, lineWidth: isDropping ? 5 : 0)
          .padding(4)
      )
      .id(group.id)
      .introspectTableView(customize: {
        $0.allowsEmptySelection = false
      })
      .onAppear {
        if selection == nil {
          selection = userSelection.workflow
        }
      }
      .frame(minWidth: 250)
      .navigationViewStyle(DoubleColumnNavigationViewStyle())
      .navigationTitle("\(group.name)")
      .navigationSubtitle("Workflows: \(group.workflows.count)")
      .environment(\.defaultMinListRowHeight, 1)
    } else {
      SearchView(searchController: searchController)
    }
  }
}

// MARK: - Previews

struct WorkflowList_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    DesignTimeFactory().workflowList(group: ModelFactory().groupList().first!,
                                     selectedWorkflow: nil)
      .environmentObject(UserSelection())
  }
}
