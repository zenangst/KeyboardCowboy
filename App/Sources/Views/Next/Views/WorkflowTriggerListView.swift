import SwiftUI

struct WorkflowTriggerListView: View {
  @State private var model: DetailViewModel
  private let onAction: (SingleDetailView.Action) -> Void

  init(_ model: DetailViewModel, onAction: @escaping (SingleDetailView.Action) -> Void) {
    _model = .init(initialValue: model)
    self.onAction = onAction
  }

  var body: some View {
    Group {
      switch model.trigger {
      case .keyboardShortcuts(let shortcuts):
        HStack {
          Button(action: {  },
                 label: { Image(systemName: "xmark") })
          .buttonStyle(.appStyle)
          Label("Keyboard Shortcuts sequence:", image: "")
            .padding(.trailing, 12)
        }
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
        HStack {
          Button(action: {  },
                 label: { Image(systemName: "xmark") })
          .buttonStyle(.appStyle)
          Label("Application trigger:", image: "")
        }
        .padding([.leading, .trailing], 8)
        WorkflowApplicationTriggerView(triggers) { action in
          onAction(.applicationTrigger(workflowId: model.id, action: action))
        }
        .padding(.bottom, 16)
      case .none:
        Label("Add a trigger:", image: "")
          .padding([.leading, .trailing], 8)
        WorkflowTriggerView(onAction: { action in
          onAction(.trigger(workflowId: model.id, action: action))
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
}

struct WorkflowTriggerListView_Previews: PreviewProvider {
  static var previews: some View {
    WorkflowTriggerListView(DesignTime.detail) { _ in }
      .frame(height: 900)
  }
}
