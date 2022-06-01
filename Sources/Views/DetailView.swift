import SwiftUI

struct DetailView: View, Equatable {
  @ObserveInjection var inject
  enum Action {
    case workflow(WorkflowView.Action)
  }
  let applicationStore: ApplicationStore
  let recorderStore: KeyShortcutRecorderStore
  let shortcutStore: ShortcutStore
  @FocusState var focus: Focus?
  @Binding var workflows: [Workflow]
  @Binding var sheet: WorkflowView.Sheet?
  var action: (Action) -> Void

  var body: some View {
    if workflows.count > 1 {
      Text("Multiple workflows selected")
        .enableInjection()
    } else {
      ForEach($workflows, content: { workflow in
        WorkflowView(applicationStore: applicationStore,
                     recorderStore: recorderStore,
                     shortcutStore: shortcutStore,
                     focus: _focus,
                     workflow: workflow,
                     sheet: $sheet) { action in
          self.action(.workflow(action))
        }
//        .equatable() // Fails in RELEASE
      })
      .enableInjection()
    }
  }

  static func == (lhs: DetailView, rhs: DetailView) -> Bool {
    lhs.workflows == rhs.workflows
  }
}

struct DetailView_Previews: PreviewProvider {
  static var previews: some View {
    DetailView(
      applicationStore: ApplicationStore(),
      recorderStore: KeyShortcutRecorderStore(),
      shortcutStore: ShortcutStore(),
      workflows: .constant([Workflow.designTime(nil)]),
      sheet: .constant(nil),
      action: { _ in })
  }
}
