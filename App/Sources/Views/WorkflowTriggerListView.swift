import SwiftUI

struct WorkflowTriggerListView: View {
  @ObserveInjection var inject

  private let model: DetailViewModel
  private let onAction: (SingleDetailView.Action) -> Void

  init(_ model: DetailViewModel, onAction: @escaping (SingleDetailView.Action) -> Void) {
    self.model = model
    self.onAction = onAction
  }

  var body: some View {
    Group {
      switch model.trigger {
      case .keyboardShortcuts(let shortcuts):
        HStack {
          Button(action: {
            onAction(.removeTrigger(workflowId: model.id))
          },
                 label: { Image(systemName: "xmark") })
          .buttonStyle(.appStyle)
          Label("Keyboard Shortcuts sequence:", image: "")
            .padding(.trailing, 12)
        }
        .padding([.leading, .trailing], 8)
        WorkflowShortcutsView(shortcuts) { keyboardShortcuts in
          onAction(.updateKeyboardShortcuts(workflowId: model.id, keyboardShortcuts: keyboardShortcuts))
        }
      case .applications(let triggers):
        HStack {
          Button(action: {
            onAction(.removeTrigger(workflowId: model.id))
          },
                 label: { Image(systemName: "xmark") })
          .buttonStyle(.gradientStyle(config: .init(nsColor: .systemRed, grayscaleEffect: true)))
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
    .enableInjection()
  }
}

struct WorkflowTriggerListView_Previews: PreviewProvider {
  static var previews: some View {
    WorkflowTriggerListView(DesignTime.detail) { _ in }
      .frame(height: 900)
  }
}
