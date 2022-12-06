import SwiftUI
import Apps

struct SingleDetailView: View {
  enum Action {
    case updateName(name: String, workflowId: Workflow.ID)
    case addCommand(workflowId: Workflow.ID)
    case applicationTrigger(WorkflowApplicationTriggerView.Action)
    case trigger(WorkflowTriggerView.Action)
    case moveCommand(workflowId: Workflow.ID, indexSet: IndexSet, toOffset: Int)
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
          .padding([.leading, .trailing, .bottom], 8)
          .onChange(of: model) { model in
            onAction(.updateName(name: model.name, workflowId: model.id))
          }

        Group {
          switch model.trigger {
          case .keyboardShortcuts(let shortcuts):
            Label("Keyboard Shortcuts:", image: "")
              .padding([.leading, .trailing], 8)
            WorkflowShortcutsView(shortcuts)
          case .applications(let triggers):
            Label("Application trigger:", image: "")
              .padding([.leading, .trailing], 8)
            WorkflowApplicationTriggerView(triggers) { action in
              onAction(.applicationTrigger(action))
            }
          case .none:
            Label("Add a trigger:", image: "")
              .padding([.leading, .trailing, .bottom], 8)
            WorkflowTriggerView(onAction: { action in
              onAction(.trigger(action))
            })
          }
        }
      }
      .padding()
      .background(Color(.textBackgroundColor))

      VStack(alignment: .leading, spacing: 0) {
        Label("Commands:", image: "")
          .padding([.leading, .trailing, .bottom], 8)
        EditableStack($model.commands, spacing: 10, onMove: { indexSet, toOffset in
          onAction(.moveCommand(workflowId: $model.id, indexSet: indexSet, toOffset: toOffset))
        }) { command in
          CommandView(command)
        }
      }
      .padding()
    }
    .background(gradient)
    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
    .labelStyle(HeaderLabelStyle())
    .toolbar {
      ToolbarItemGroup(placement: .primaryAction) {
        HStack {
          Button(
            action: {
              sheet = .newCommand
            },
            label: {
              Label(title: {
                Text("Add command")
              }, icon: {
                Image(systemName: "plus.square.dashed")
                  .renderingMode(.template)
                  .foregroundColor(Color(.systemGray))
              })
            })
        }
      }
    }
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

  var gradient: some View {
    LinearGradient(
      gradient: Gradient(
        stops: [
          .init(color: Color(.windowBackgroundColor).opacity(0.25), location: 0.5),
          .init(color: Color(.gridColor).opacity(0.75), location: 1.0),
        ]),
      startPoint: .top,
      endPoint: .bottom)
  }
}

struct SingleDetailView_Previews: PreviewProvider {
  static var previews: some View {
    SingleDetailView(DesignTime.detail) { _ in }
  }
}
