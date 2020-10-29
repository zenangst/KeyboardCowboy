import SwiftUI
import ModelKit

public struct WorkflowList: View {
  public enum Action {
    case createWorkflow(in: ModelKit.Group)
    case updateWorkflow(Workflow, in: ModelKit.Group)
    case deleteWorkflow(Workflow, in: ModelKit.Group)
    case moveWorkflow(Workflow, to: Int, in: ModelKit.Group)
  }

  static let idealWidth: CGFloat = 300
  @EnvironmentObject var userSelection: UserSelection
  let applicationProvider: ApplicationProvider
  let commandController: CommandController
  let groupController: GroupController
  let keyboardShortcutController: KeyboardShortcutController
  let openPanelController: OpenPanelController
  let group: ModelKit.Group
  let workflowController: WorkflowController
  @State private var selection: Workflow?

  public var body: some View {
    NavigationView {
      List {
        ForEach(group.workflows) { workflow in
          NavigationLink(
            destination: WorkflowView(
              applicationProvider: applicationProvider,
              commandController: commandController,
              keyboardShortcutController: keyboardShortcutController,
              openPanelController: openPanelController,
              workflowController: workflowController,
              workflow: workflow,
              group: group),
            tag: workflow,
            selection: $userSelection.workflow,
            label: {
              WorkflowListCell(workflow: workflow)
                .contextMenu {
                  Button("Delete") {
                    workflowController.perform(.deleteWorkflow(workflow, in: group))
                  }
                }
                .frame(height: 48)
            })
        }.onMove(perform: { indices, newOffset in
          for i in indices {
            let workflow = group.workflows[i]
            workflowController.perform(.moveWorkflow(workflow, to: newOffset, in: group))
          }
        }).onDelete(perform: { indexSet in
          for index in indexSet {
            let workflow = group.workflows[index]
            workflowController.perform(.deleteWorkflow(workflow, in: group))
          }
        })
      }
      .listStyle(PlainListStyle())
      .frame(minWidth: 275)
      .id(group.id)
    }
  }
}

private extension WorkflowList {
  func addButton(in group: ModelKit.Group) -> some View {
    HStack(spacing: 4) {
      RoundOutlinedButton(title: "+", color: Color(.secondaryLabelColor))
        .onTapGesture {
          workflowController.action(.createWorkflow(in: group))()
        }
      Button("Add Workflow", action: {
        workflowController.action(.createWorkflow(in: group))()
      })
      .buttonStyle(PlainButtonStyle())
    }
  }
}

// MARK: - Previews

struct WorkflowList_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    WorkflowList(applicationProvider: ApplicationPreviewProvider().erase(),
                 commandController: CommandPreviewController().erase(),
                 groupController: GroupPreviewController().erase(),
                 keyboardShortcutController: KeyboardShortcutPreviewController().erase(),
                 openPanelController: OpenPanelPreviewController().erase(),
                 group: ModelFactory().groupList().first!,
                 workflowController: WorkflowPreviewController().erase())
  }
}
