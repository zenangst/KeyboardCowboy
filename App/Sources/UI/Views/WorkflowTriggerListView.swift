import Bonzai
import Combine
import Inject
import SwiftUI

struct WorkflowTriggerListView: View {
  @ObserveInjection var inject
  @Namespace private var namespace
  @ObservedObject private var publisher: TriggerPublisher
  private let applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>
  private let keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>
  private let onAction: (SingleDetailView.Action) -> Void
  private let onTab: () -> Void
  private let workflowId: String
  private var focus: FocusState<AppFocus?>.Binding

  init(_ focus: FocusState<AppFocus?>.Binding,
       workflowId: String,
       publisher: TriggerPublisher,
       applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>,
       keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>,
       onTab: @escaping () -> Void,
       onAction: @escaping (SingleDetailView.Action) -> Void) {
    self.focus = focus
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
        WorkflowTriggerHeaderView("Keyboard Shortcuts Sequence") { onAction(.removeTrigger(workflowId: workflowId)) }
          .matchedGeometryEffect(id: "workflow-trigger-header", in: namespace)
        WorkflowKeyboardTriggerView(
          namespace: namespace,
          workflowId: workflowId,
          focus: focus,
          trigger: trigger,
          keyboardShortcutSelectionManager: keyboardShortcutSelectionManager)
      case .applications(let triggers):
        WorkflowTriggerHeaderView("Application Trigger") { onAction(.removeTrigger(workflowId: workflowId)) }
          .matchedGeometryEffect(id: "workflow-trigger-header", in: namespace)
        WorkflowApplicationTriggerView(focus, data: triggers,
                                       selectionManager: applicationTriggerSelectionManager,
                                       onTab: onTab)
        .matchedGeometryEffect(id: "workflow-triggers", in: namespace)
      case .snippet(let snippet):
        WorkflowTriggerHeaderView("Add Snippet") { onAction(.removeTrigger(workflowId: workflowId)) }
          .matchedGeometryEffect(id: "workflow-trigger-header", in: namespace)
        WorkflowSnippetTriggerView(focus, snippet: snippet) { snippet in
          onAction(.updateSnippet(workflowId: workflowId, snippet: snippet))
        }
        .matchedGeometryEffect(id: "workflow-triggers", in: namespace)
      case .empty:
        WorkflowTriggerHeaderView("Add Trigger", onRemove: nil)
          .matchedGeometryEffect(id: "workflow-trigger-header", in: namespace)
        WorkflowTriggerView(focus, isGrayscale: .readonly(publisher.data != .empty),
                            onAction: { action in
          onAction(.trigger(workflowId: workflowId, action: action))
        })
        .matchedGeometryEffect(id: "workflow-triggers", in: namespace)
      }
    }
    .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.2), value: publisher.data)
    .enableInjection()
  }
}

private struct WorkflowTriggerHeaderView: View {
  let text: String
  let onRemove: (() -> Void)?

  init(_ text: String, onRemove: (() -> Void)? = nil) {
    self.text = text
    self.onRemove = onRemove
  }

  var body: some View {
    HStack {
      ZenLabel(text)
      Spacer()
      Button(action: { onRemove?() },
             label: {
        Image(systemName: "xmark")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 10, height: 10)
      })
      .buttonStyle(.calm(color: .systemRed, padding: .medium))
      .opacity(onRemove != nil ? 1 : 0)
    }
    .padding([.leading, .trailing], 8)
  }
}

struct WorkflowTriggerListView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    VStack {
      WorkflowTriggerListView($focus, workflowId: UUID().uuidString,
                              publisher: .init(.empty),
                              applicationTriggerSelectionManager: .init(),
                              keyboardShortcutSelectionManager: .init(), onTab: {}) { _ in }
      Spacer()
      WorkflowTriggerListView($focus, workflowId: UUID().uuidString,
                              publisher: .init(.applications([.init(id: "", name: "Finder", application: .finder(), contexts: [])])),
                              applicationTriggerSelectionManager: .init(),
                              keyboardShortcutSelectionManager: .init(), onTab: {}) { _ in }
      Spacer()
      WorkflowTriggerListView($focus, workflowId: UUID().uuidString,
                              publisher: .init(.snippet(.init(id: "", text: "foo"))),
                              applicationTriggerSelectionManager: .init(),
                              keyboardShortcutSelectionManager: .init(), onTab: {}) { _ in }
      Spacer()
      WorkflowTriggerListView($focus, workflowId: UUID().uuidString,
                              publisher: .init(DesignTime.detail.trigger),
                              applicationTriggerSelectionManager: .init(),
                              keyboardShortcutSelectionManager: .init(), onTab: {}) { _ in }
    }
      .designTime()
      .padding()
      .frame(minHeight: 500)
  }
}
