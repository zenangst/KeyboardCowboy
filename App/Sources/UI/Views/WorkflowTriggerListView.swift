import Combine
import SwiftUI
import Bonzai

struct WorkflowTriggerListView: View {
  @FocusState private var focus: AppFocus?
  @Namespace private var namespace
  @ObservedObject private var publisher: TriggerPublisher
  private let applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>
  private let keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>
  private let onAction: (SingleDetailView.Action) -> Void
  private let onTab: () -> Void
  private let workflowId: String

  init(_ focus: FocusState<AppFocus?>,
       workflowId: String,
       publisher: TriggerPublisher,
       applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>,
       keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>,
       onTab: @escaping () -> Void,
       onAction: @escaping (SingleDetailView.Action) -> Void) {
    _focus = focus
    self.publisher = publisher
    self.applicationTriggerSelectionManager = applicationTriggerSelectionManager
    self.keyboardShortcutSelectionManager = keyboardShortcutSelectionManager
    self.onTab = onTab
    self.onAction = onAction
    self.workflowId = workflowId
  }

  var body: some View {
    Group {
      switch publisher.data {
      case .keyboardShortcuts(let trigger):
        KeyboardTriggerView(
          namespace: namespace,
          workflowId: workflowId,
          focus: _focus,
          trigger: trigger,
          keyboardShortcutSelectionManager: keyboardShortcutSelectionManager,
          onAction: onAction
        )
      case .applications(let triggers):
        HStack {
          Label("Application Trigger", image: "")
          Spacer()
          Button(action: { onAction(.removeTrigger(workflowId: workflowId)) },
                 label: {
            Image(systemName: "xmark")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 10, height: 10)
          })
          .buttonStyle(.calm(color: .systemRed, padding: .medium))
        }
        .padding([.leading, .trailing], 8)
        WorkflowApplicationTriggerView(_focus, data: triggers,
                                       selectionManager: applicationTriggerSelectionManager,
        onTab: onTab) { action in
          onAction(.applicationTrigger(workflowId: workflowId, action: action))
        }
        .matchedGeometryEffect(id: "workflow-triggers", in: namespace)
      case .empty:
        Label("Add Trigger", image: "")
          .padding([.leading, .trailing], 8)
        WorkflowTriggerView(_focus, isGrayscale: .readonly(publisher.data != .empty),
                            onAction: { action in
          onAction(.trigger(workflowId: workflowId, action: action))
        })
        .matchedGeometryEffect(id: "workflow-triggers", in: namespace)
      }
    }
    .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.2), value: publisher.data)
  }
}

struct WorkflowTriggerListView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    VStack {
      WorkflowTriggerListView(_focus, workflowId: UUID().uuidString,
                              publisher: .init(DesignTime.detail.trigger),
                              applicationTriggerSelectionManager: .init(),
                              keyboardShortcutSelectionManager: .init(), onTab: {}) { _ in }
    }
      .designTime()
      .padding()
      .frame(minHeight: 100)
  }
}
