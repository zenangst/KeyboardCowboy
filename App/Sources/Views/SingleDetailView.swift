import SwiftUI
import Apps
import Inject

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

  @ObserveInjection var inject
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
          WorkflowInfoView($workflow, onAction: { action in
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
        .padding([.top, .leading, .trailing])
        .padding(.bottom, 32)
        .background(alignment: .bottom, content: {
          Canvas(rendersAsynchronously: true) { context, size in
            context.fill(
              Path(CGRect(origin: .zero, size: CGSize(width: size.width,
                                                      height: size.height - 12))),
              with: .color(Color(.textBackgroundColor)))

            context.fill(Path { path in
              path.move(to: CGPoint(x: size.width / 2, y: size.height - 12))
              path.addLine(to: CGPoint(x: size.width / 2 - 24, y: size.height - 12))
              path.addLine(to: CGPoint(x: size.width / 2, y: size.height - 2))
              path.addLine(to: CGPoint(x: size.width / 2 + 24, y: size.height - 12))
              path.addLine(to: CGPoint(x: size.width / 2, y: size.height - 12))
            }, with: .color(Color(.textBackgroundColor)))
          }
        })

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
    .enableInjection()
  }
}

struct SingleDetailView_Previews: PreviewProvider {
  static var previews: some View {
    SingleDetailView(.constant(DesignTime.detail)) { _ in }
      .frame(height: 900)
  }
}
