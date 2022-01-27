import Apps
import SwiftUI

struct WorkflowShortcutsView: View, Equatable {
  @Binding var workflow: Workflow
  var body: some View {
    VStack(alignment: .leading) {
      switch workflow.trigger {
      case .application(let applicationTriggers):
        HStack {
          Label("Application Trigger:", image: "")
          closeButton
        }
        ApplicationTriggerListView(applicationTriggers: applicationTriggers)
      case .keyboardShortcuts(let keyboardShortcuts):
        HStack {
          Label("Keyboard Shortcuts:", image: "")
          closeButton
        }
        KeyShortcutsListView(keyboardShortcuts: keyboardShortcuts)
      case .none:
        HStack {
          Label("Trigger:", image: "")
        }
        HStack {
          Button("Application", action: {})
          Button("Keyboard Shortcut", action: {})
        }
      }
    }
    .labelStyle(HeaderLabelStyle())
  }

  @ViewBuilder
  var closeButton: some View {
    Spacer()
    Button(action: { },
           label: { Image(systemName: "xmark.circle") })
    .buttonStyle(PlainButtonStyle())
  }

  static func == (lhs: WorkflowShortcutsView, rhs: WorkflowShortcutsView) -> Bool {
    lhs.workflow.trigger == rhs.workflow.trigger
  }
}

struct WorkflowShortcutsView_Previews: PreviewProvider {
  static let workflow = Workflow.designTime(
    .keyboardShortcuts([
      .init(key: "A", modifiers: [.command])
    ])
  )
  static var previews: some View {
    WorkflowShortcutsView(workflow: .constant(workflow))
  }
}
