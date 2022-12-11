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
          .padding(.horizontal, 8)
          .padding(.vertical, 16)
          .onChange(of: model) { model in
            onAction(.updateName(name: model.name, workflowId: model.id))
          }

        Group {
          switch model.trigger {
          case .keyboardShortcuts(let shortcuts):
            Label("Keyboard Shortcuts sequence:", image: "")
              .padding([.leading, .trailing], 8)
            WorkflowShortcutsView(shortcuts)
            HStack {
              Spacer()
              Text("These keys need to be pressed in sequence in order to run the workflow.")
                .multilineTextAlignment(.center)
                .frame(alignment: .center)
                .font(.caption)
              Spacer()
            }
          case .applications(let triggers):
            Label("Application trigger:", image: "")
              .padding([.leading, .trailing], 8)
            WorkflowApplicationTriggerView(triggers) { action in
              onAction(.applicationTrigger(action))
            }
            .padding(.bottom, 16)
          case .none:
            Label("Add a trigger:", image: "")
              .padding([.leading, .trailing, .bottom], 8)
            WorkflowTriggerView(onAction: { action in
              onAction(.trigger(action))
            })

            HStack {
              Spacer()
              Text("Choose if you want to bind this workflow to an application or assign it a global keyboard shortcut sequence.")
                .multilineTextAlignment(.center)
                .frame(alignment: .center)
                .font(.caption)
              Spacer()
            }
          }
        }
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

      VStack(alignment: .leading, spacing: 0) {
        HStack {
          Label("Commands:", image: "")
          Spacer()
          Menu(content: {
            ForEach(DetailViewModel.Flow.allCases) {
              Button($0.rawValue, action: {})
            }
          }, label: {
            Text("Run \(model.flow.rawValue)")
          }, primaryAction: {

          })
          .fixedSize()
        }
        .padding([.leading, .bottom, .trailing], 8)
        EditableStack($model.commands, spacing: 10, onMove: { indexSet, toOffset in
          onAction(.moveCommand(workflowId: $model.id, indexSet: indexSet, toOffset: toOffset))
        }) { command in
          CommandView(command)
        }
        .background(
          GeometryReader { proxy in
            Rectangle()
              .fill(Color.gray)
              .frame(width: 3.0)
              .offset(x: (proxy.size.width / 2.0) - 3.0)
              .opacity(model.flow == .concurrent ? 0 : 1)
          }
        )
      }
      .padding()
    }
    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
    .labelStyle(HeaderLabelStyle())
    .toolbar {
      ToolbarItemGroup {
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
}

struct SingleDetailView_Previews: PreviewProvider {
  static var previews: some View {
    SingleDetailView(DesignTime.detail) { _ in }
      .frame(height: 600)
  }
}
