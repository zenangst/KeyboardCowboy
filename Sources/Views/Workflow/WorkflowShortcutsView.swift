import Apps
import SwiftUI

struct WorkflowShortcutsView: View, Equatable {
  @ObserveInjection var inject
  let applicationStore: ApplicationStore
  @FocusState var focus: Focus?
  @Binding var workflow: Workflow

  init(_ applicationStore: ApplicationStore,
       focus: FocusState<Focus?>,
       workflow: Binding<Workflow>) {
    self.applicationStore = applicationStore
    _focus = focus
    _workflow = workflow
  }

  var body: some View {
    VStack(alignment: .leading) {
      switch workflow.trigger {
      case .application(let applicationTriggers):
        HStack {
          Label("Application Trigger:", image: "")
          removeButton
        }
        // TODO: This is a bottleneck
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
        KeyShortcutsListView(keyboardShortcuts: Binding<[KeyShortcut]>(
          get: { keyboardShortcuts },
          set: { workflow.trigger = .keyboardShortcuts($0) })) { action in
            switch action {
            case .add(let shortcut):
              if case .keyboardShortcuts(var shortcuts) = workflow.trigger {
                shortcuts.append(shortcut)
                workflow.trigger = .keyboardShortcuts(shortcuts)
              }
            }
            focus = .detail(.shortcuts(workflow))
          }
      case .none:
        HStack {
          Label("Add a trigger:", image: "")
        }
        HStack {
          Button("Application", action: { workflow.trigger = .application([]) })
          Button("Keyboard Shortcut", action: { workflow.trigger = .keyboardShortcuts([]) })
        }
      }
    }
    .focused($focus, equals: .detail(.shortcuts(workflow)))
    .labelStyle(HeaderLabelStyle())
    .enableInjection()
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
      ApplicationStore(),
      focus: FocusState(),
      workflow: .constant(workflow))
  }
}
