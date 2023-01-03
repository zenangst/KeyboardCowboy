import SwiftUI
import Apps

struct SingleDetailView: View {
  enum Action {
    case addCommand(workflowId: Workflow.ID)
    case applicationTrigger(workflowId: Workflow.ID, action: WorkflowApplicationTriggerView.Action)
    case commandView(workflowId: Workflow.ID, action: CommandView.Action)
    case moveCommand(workflowId: Workflow.ID, indexSet: IndexSet, toOffset: Int)
    case trigger(workflowId: Workflow.ID, action: WorkflowTriggerView.Action)
    case updateName(workflowId: Workflow.ID, name: String)
  }

  enum Sheet: Int, Identifiable {
    var id: Int { self.rawValue }
    case newCommand
  }

  @ObserveInjection var inject
  @State private var model: DetailViewModel
  @State private var sheet: Sheet?
  private let onAction: (Action) -> Void

  init(_ model: DetailViewModel, onAction: @escaping (Action) -> Void) {
    _model = .init(initialValue: model)
    self.onAction = onAction
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        WorkflowInfoView($model)
          .padding(.horizontal, 8)
          .padding(.vertical, 16)
          .onChange(of: model) { model in
            onAction(.updateName(workflowId: model.id, name: model.name))
          }
        WorkflowTriggerListView(model, onAction: onAction)
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
      WorkflowCommandListView(model, onAction: onAction)
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
    SingleDetailView(DesignTime.detail) { _ in }
      .frame(height: 900)
  }
}
