import Apps
import SwiftUI

struct WorkflowShortcutsView: View, Equatable {
  let applicationStore: ApplicationStore
  @Binding var workflow: Workflow

  var body: some View {
    VStack(alignment: .leading) {
      switch workflow.trigger {
      case .application(let applicationTriggers):
        HStack {
          Label("Application Trigger:", image: "")
          removeButton
        }
        ApplicationTriggerListView(
          action: { action in
            guard case .application(var triggers) = workflow.trigger else { return }
            switch action {
            case .add(let application):
              triggers.append(.init(application: application))
            case .remove(let application):
              triggers.removeAll(where: { $0.application == application })
            }
            workflow.trigger = .application(triggers)
          },
          applicationStore: applicationStore,
          applicationTriggers: Binding<[ApplicationTrigger]>(get: {
            applicationTriggers
          }, set: { triggers in
            workflow.trigger = .application(triggers)
          }) )
      case .keyboardShortcuts(let keyboardShortcuts):
        HStack {
          Label("Keyboard Shortcuts:", image: "")
          removeButton
        }
        KeyShortcutsListView(keyboardShortcuts: keyboardShortcuts)
      case .none:
        HStack {
          Label("Trigger:", image: "")
        }
        HStack {
          Button("Application", action: {
            workflow.trigger = .application([])
          })
          Button("Keyboard Shortcut", action: {
            workflow.trigger = .keyboardShortcuts([])
          })
        }
      }
    }
    .labelStyle(HeaderLabelStyle())
  }

  @ViewBuilder
  var removeButton: some View {
    Spacer()
    Button(action: { workflow.trigger = nil },
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
    WorkflowShortcutsView(
      applicationStore: ApplicationStore(),
      workflow: .constant(workflow))
  }
}
