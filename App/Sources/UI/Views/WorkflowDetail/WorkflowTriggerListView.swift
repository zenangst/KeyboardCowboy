import Bonzai
import Combine
import HotSwiftUI
import SwiftUI

struct WorkflowTriggerListView: View {
  @Namespace private var namespace
  @ObservedObject private var publisher: TriggerPublisher
  private let applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>
  private let keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>
  private let onTab: () -> Void
  private let workflowId: String
  private var focus: FocusState<AppFocus?>.Binding

  init(_ focus: FocusState<AppFocus?>.Binding,
       workflowId: String,
       publisher: TriggerPublisher,
       applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>,
       keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>,
       onTab: @escaping () -> Void)
  {
    self.focus = focus
    self.publisher = publisher
    self.applicationTriggerSelectionManager = applicationTriggerSelectionManager
    self.keyboardShortcutSelectionManager = keyboardShortcutSelectionManager
    self.onTab = onTab
    self.workflowId = workflowId
  }

  var body: some View {
    Group {
      switch publisher.data {
      case let .keyboardShortcuts(trigger):
        WorkflowTriggerHeaderView("Keyboard Shortcuts Sequence")
          .matchedGeometryEffect(id: "workflow-trigger-header", in: namespace)
        WorkflowKeyboardTriggerView(
          namespace: namespace,
          workflowId: workflowId,
          focus: focus,
          trigger: trigger,
          keyboardShortcutSelectionManager: keyboardShortcutSelectionManager,
        )
      case let .applications(triggers):
        WorkflowTriggerHeaderView("Application Trigger")
          .matchedGeometryEffect(id: "workflow-trigger-header", in: namespace)
        WorkflowApplicationTrigger(focus, data: triggers,
                                   selectionManager: applicationTriggerSelectionManager,
                                   onTab: onTab)
          .matchedGeometryEffect(id: "workflow-triggers", in: namespace)
      case let .snippet(snippet):
        WorkflowTriggerHeaderView("Add Snippet")
          .matchedGeometryEffect(id: "workflow-trigger-header", in: namespace)
        WorkflowSnippetTriggerView(focus, snippet: snippet)
          .matchedGeometryEffect(id: "workflow-triggers", in: namespace)
      case .modifier:
        WorkflowTriggerHeaderView("Add Modifier Trigger")
      case .empty:
        WorkflowTriggerHeaderView("Add Trigger", showRemoveButton: false)
          .matchedGeometryEffect(id: "workflow-trigger-header", in: namespace)
        WorkflowTrigger(focus, isGrayscale: .readonly { publisher.data != .empty })
          .matchedGeometryEffect(id: "workflow-triggers", in: namespace)
      }
    }
    .style(.derived)
  }
}

private struct WorkflowTriggerHeaderView: View {
  @ObserveInjection var inject
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  private let text: String
  private let showRemoveButton: Bool

  init(_ text: String, showRemoveButton: Bool = true) {
    self.text = text
    self.showRemoveButton = showRemoveButton
  }

  var body: some View {
    HStack {
      ZenLabel(text)
      Spacer()
      Button(action: {
        updater.modifyWorkflow(using: transaction) { workflow in
          workflow.trigger = nil
        }
      }, label: {
        Image(systemName: "xmark")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 10, height: 10)
      })
      .opacity(showRemoveButton ? 1 : 0)
      .environment(\.buttonCalm, true)
      .environment(\.buttonPadding, .medium)
      .environment(\.buttonBackgroundColor, .systemRed)
      .enableInjection()
    }
  }
}

struct WorkflowTriggerListView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    VStack {
      WorkflowTriggerListView($focus, workflowId: UUID().uuidString,
                              publisher: .init(.empty),
                              applicationTriggerSelectionManager: .init(),
                              keyboardShortcutSelectionManager: .init(), onTab: {})
      Spacer()
      WorkflowTriggerListView($focus, workflowId: UUID().uuidString,
                              publisher: .init(.applications([.init(id: "", name: "Finder", application: .finder(), contexts: [])])),
                              applicationTriggerSelectionManager: .init(),
                              keyboardShortcutSelectionManager: .init(), onTab: {})
      Spacer()
      WorkflowTriggerListView($focus, workflowId: UUID().uuidString,
                              publisher: .init(.snippet(.init(id: "", text: "foo"))),
                              applicationTriggerSelectionManager: .init(),
                              keyboardShortcutSelectionManager: .init(), onTab: {})
      Spacer()
      WorkflowTriggerListView($focus, workflowId: UUID().uuidString,
                              publisher: .init(DesignTime.detail.trigger),
                              applicationTriggerSelectionManager: .init(),
                              keyboardShortcutSelectionManager: .init(), onTab: {})
    }
    .designTime()
    .padding()
    .frame(minHeight: 500)
  }
}
