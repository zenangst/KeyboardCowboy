import Combine
import SwiftUI
import ZenViewKit

struct WorkflowTriggerListView: View {
  @Namespace var namespace

  private let data: DetailViewModel
  private let onAction: (SingleDetailView.Action) -> Void

  var focus: FocusState<AppFocus?>.Binding

  private let applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>
  private let keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>

  init(_ focus: FocusState<AppFocus?>.Binding, data: DetailViewModel,
       applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>,
       keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>,
       onAction: @escaping (SingleDetailView.Action) -> Void) {
    self.focus = focus
    self.data = data
    self.applicationTriggerSelectionManager = applicationTriggerSelectionManager
    self.keyboardShortcutSelectionManager = keyboardShortcutSelectionManager
    self.onAction = onAction
  }

  var body: some View {
    Group {
      switch data.trigger {
      case .keyboardShortcuts(let trigger):
       KeyboardTriggerView(namespace: namespace, focus: focus, data: data, trigger: trigger,
                           keyboardShortcutSelectionManager: keyboardShortcutSelectionManager, onAction: onAction)
      case .applications(let triggers):
        HStack {
          Button(action: { onAction(.removeTrigger(workflowId: data.id)) },
                 label: {
            Image(systemName: "xmark")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 10, height: 10)
          })
          .buttonStyle(.calm(color: .systemRed, padding: .medium))
          Label("Application Trigger:", image: "")
        }
        .padding([.leading, .trailing], 8)
        WorkflowApplicationTriggerView(focus, data: triggers,
                                       selectionManager: applicationTriggerSelectionManager) { action in
          onAction(.applicationTrigger(workflowId: data.id, action: action))
        }
        .padding(.bottom, 16)
        .matchedGeometryEffect(id: "workflow-triggers", in: namespace)
      case .none:
        Label("Add a trigger:", image: "")
          .padding([.leading, .trailing], 8)
        WorkflowTriggerView(onAction: { action in
          onAction(.trigger(workflowId: data.id, action: action))
        })
        .matchedGeometryEffect(id: "workflow-triggers", in: namespace)
      }
    }
    .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.2), value: data.trigger)
  }
}

struct WorkflowTriggerListView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    VStack {
      WorkflowTriggerListView($focus, data: DesignTime.detail,
                              applicationTriggerSelectionManager: .init(),
                              keyboardShortcutSelectionManager: .init()) { _ in }
    }
      .designTime()
      .padding()
      .frame(minHeight: 100)
  }
}
