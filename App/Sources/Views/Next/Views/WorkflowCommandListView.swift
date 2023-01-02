import SwiftUI

struct WorkflowCommandListView: View {
  @State private var model: DetailViewModel
  private let onAction: (SingleDetailView.Action) -> Void

  init(_ model: DetailViewModel, onAction: @escaping (SingleDetailView.Action) -> Void) {
    _model = .init(initialValue: model)
    self.onAction = onAction
  }

  var body: some View {
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
        Divider()
          .padding(.horizontal, 4)
        Button(action: {}) {
          HStack(spacing: 4) {
            Image(systemName: "plus")
          }
        }
        .padding(4)
        .buttonStyle(AppButtonStyle())
      }
      .padding([.leading, .bottom], 8)
      .padding(.trailing, 16)
      EditableStack($model.commands, spacing: 10, onMove: { indexSet, toOffset in
        onAction(.moveCommand(workflowId: $model.id, indexSet: indexSet, toOffset: toOffset))
      }) { command in
        CommandView(command, workflowId: model.id) { action in
          if action.isAction(.delete), let index = model.commands.firstIndex(of: command.wrappedValue) {
            model.commands.remove(at: index)
          }
          if action.isAction(.run) { }
          onAction(.commandView(action))
        }
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
}

struct WorkflowCommandListView_Previews: PreviewProvider {
  static var previews: some View {
    WorkflowCommandListView(DesignTime.detail) { _ in }
      .frame(height: 900)
  }
}

enum CommandViewActionKind {
  case run, delete
}

extension CommandView.Action {
  func isAction(_ kind: CommandViewActionKind) -> Bool {
    switch self {
    case .application(let action, _, _):
      switch action {
      case .commandAction(let commandContainerAction):
        switch kind {
        case .run:
          return commandContainerAction.isRunAction
        case .delete:
          return commandContainerAction.isDeleteAction
        }
      default:
        return false
      }
    case .keyboard(let action, _, _):
      switch action {
      case .commandAction(let commandContainerAction):
        switch kind {
        case .run:
          return commandContainerAction.isRunAction
        case .delete:
          return commandContainerAction.isDeleteAction
        }
      default:
        return false
      }
    case .open(let action, _, _):
      switch action {
      case .commandAction(let commandContainerAction):
        switch kind {
        case .run:
          return commandContainerAction.isRunAction
        case .delete:
          return commandContainerAction.isDeleteAction
        }
      default:
        return false
      }
    case .script(let action, _, _):
      switch action {
      case .commandAction(let commandContainerAction):
        switch kind {
        case .run:
          return commandContainerAction.isRunAction
        case .delete:
          return commandContainerAction.isDeleteAction
        }
      default:
        return false
      }
    case .shortcut(let action, _, _):
      switch action {
      case .commandAction(let commandContainerAction):
        switch kind {
        case .run:
          return commandContainerAction.isRunAction
        case .delete:
          return commandContainerAction.isDeleteAction
        }
      default:
        return false
      }

    case .type(let action, _, _):
      switch action {
      case .commandAction(let commandContainerAction):
        switch kind {
        case .run:
          return commandContainerAction.isRunAction
        case .delete:
          return commandContainerAction.isDeleteAction
        }
      default:
        return false
      }
    }
  }
}

extension CommandContainerAction {
  var isRunAction: Bool {
    switch self {
    case .run:
      return true
    case .delete:
      return false
    }
  }

  var isDeleteAction: Bool {
    switch self {
    case .run:
      return false
    case .delete:
      return true
    }
  }
}
