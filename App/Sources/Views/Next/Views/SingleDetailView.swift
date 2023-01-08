import SwiftUI
import Apps

struct SingleDetailView: View {
  enum Action {
    case addCommand(workflowId: Workflow.ID)
    case removeCommands(workflowId: Workflow.ID, commandIds: Set<Command.ID>)
    case applicationTrigger(workflowId: Workflow.ID, action: WorkflowApplicationTriggerView.Action)
    case commandView(workflowId: Workflow.ID, action: CommandView.Action)
    case moveCommand(workflowId: Workflow.ID, indexSet: IndexSet, toOffset: Int)
    case trigger(workflowId: Workflow.ID, action: WorkflowTriggerView.Action)
    case removeTrigger(workflowId: Workflow.ID)
    case setIsEnabled(workflowId: Workflow.ID, isEnabled: Bool)
    case updateName(workflowId: Workflow.ID, name: String)
  }

  enum Sheet: Int, Identifiable {
    var id: Int { self.rawValue }
    case newCommand
  }

  @ObserveInjection var inject
  @Binding private var model: DetailViewModel
  @State private var sheet: Sheet?
  private let onAction: (Action) -> Void

  init(_ model: Binding<DetailViewModel>, onAction: @escaping (Action) -> Void) {
    _model = model
    self.onAction = onAction
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        WorkflowInfoView(model, onAction: { action in
          switch action {
          case .updateName(let name):
            onAction(.updateName(workflowId: model.id, name: name))
          case .setIsEnabled(let isEnabled):
            onAction(.setIsEnabled(workflowId: model.id, isEnabled: isEnabled))
          }
        })
        .padding(.horizontal, 4)
        .padding(.vertical, 12)
        WorkflowTriggerListView($model, onAction: onAction)
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
      WorkflowCommandListView($model, onAction: onAction)
        .focusable()
    }
    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
    .labelStyle(HeaderLabelStyle())
    .sheet(item: $sheet, content: { kind in
      switch kind {
      case .newCommand:
        NewCommandSheetView { action in
          switch action {
          case .close:
            sheet = nil
          }
        }
      }
    })
    .enableInjection()
  }
}

struct SingleDetailView_Previews: PreviewProvider {
  static var previews: some View {
    SingleDetailView(.constant(DesignTime.detail)) { _ in }
      .frame(height: 900)
  }
}
