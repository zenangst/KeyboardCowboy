import SwiftUI
import Apps

struct SingleDetailView: View {
  enum Action {
    case updateKeyboardShortcuts(workflowId: Workflow.ID, keyboardShortcuts: [KeyShortcut])
    case removeCommands(workflowId: Workflow.ID, commandIds: Set<Command.ID>)
    case applicationTrigger(workflowId: Workflow.ID, action: WorkflowApplicationTriggerView.Action)
    case commandView(workflowId: Workflow.ID, action: CommandView.Action)
    case moveCommand(workflowId: Workflow.ID, indexSet: IndexSet, toOffset: Int)
    case trigger(workflowId: Workflow.ID, action: WorkflowTriggerView.Action)
    case removeTrigger(workflowId: Workflow.ID)
    case setIsEnabled(workflowId: Workflow.ID, isEnabled: Bool)
    case updateName(workflowId: Workflow.ID, name: String)
  }

  @Environment(\.controlActiveState) var controlActiveState
  @Environment(\.openWindow) var openWindow
  @Binding private var workflow: DetailViewModel
  private let onAction: (Action) -> Void

  init(_ workflow: Binding<DetailViewModel>, onAction: @escaping (Action) -> Void) {
    _workflow = workflow
    self.onAction = onAction
  }

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        VStack(alignment: .leading) {
          WorkflowInfoView(workflow, onAction: { action in
            switch action {
            case .updateName(let name):
              onAction(.updateName(workflowId: workflow.id, name: name))
            case .setIsEnabled(let isEnabled):
              onAction(.setIsEnabled(workflowId: workflow.id, isEnabled: isEnabled))
            }
          })
          .padding(.horizontal, 4)
          .padding(.vertical, 12)
          .id(workflow.id)
          WorkflowTriggerListView($workflow, onAction: onAction)
            .id(workflow.id)
        }
        .padding()
        .background(alignment: .bottom, content: {
          GeometryReader { proxy in
            Rectangle()
              .fill(Color(.textBackgroundColor))
            Path { path in
              path.move(to: CGPoint(x: proxy.size.width / 2, y: proxy.size.height))
              path.addLine(to: CGPoint(x: proxy.size.width / 2 - 16, y: proxy.size.height))
              path.addLine(to: CGPoint(x: proxy.size.width / 2, y: proxy.size.height + 8))
              path.addLine(to: CGPoint(x: proxy.size.width / 2 + 16, y: proxy.size.height))
            }
            .fill(Color(.textBackgroundColor))
          }
          .compositingGroup()
        })
        .shadow(radius: 4)

        WorkflowCommandListView(
          $workflow,
          scrollViewProxy: proxy,
          onNewCommand: {
            openWindow(value: NewCommandWindow.Context.newCommand(workflowId: workflow.id))
          },
          onAction: { action in
            onAction(action)
          })
      }
      .labelStyle(HeaderLabelStyle())
    }
  }
}

struct SingleDetailView_Previews: PreviewProvider {
  static var previews: some View {
    SingleDetailView(.constant(DesignTime.detail)) { _ in }
      .frame(height: 900)
  }
}
