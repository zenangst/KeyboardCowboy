import Apps
import SwiftUI

struct WorkflowCommandsListView: View, Equatable {
  enum Action {
    case commandView(CommandView.Action)
  }

  enum Focusable: Hashable {
    case none
    case row(id: String)
  }

  @Binding var workflow: Workflow
  @Namespace var namespace
  var action: (Action) -> Void

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Label("Commands:", image: "")
          .labelStyle(HeaderLabelStyle())
        Spacer()
      }
      LazyVStack(spacing: 4) {
        EditableVStack(
          data: $workflow.commands,
          id: \.self,
          namespace: namespace,
          onDelete: { indexSet in
            workflow.commands.remove(atOffsets: indexSet)
          },
          onMove: { indexSet, offset in
            workflow.commands.move(fromOffsets: indexSet, toOffset: offset)
          }) { command in
            VStack(spacing: 0) {
              ResponderView(
                command, namespace: namespace,
                onDoubleClick: {
                  self.action(.commandView(.commandAction(.edit(command.wrappedValue))))
                }) { responder in
                  CommandView(workflow: $workflow,
                              command: command, responder: responder) { action in
                    self.action(.commandView(action))
                }
                .equatable()
                .cornerRadius(8)
              }
            }
          }
      }
      .shadow(radius: 0.2)
    }
  }

  static func == (lhs: WorkflowCommandsListView, rhs: WorkflowCommandsListView) -> Bool {
    lhs.workflow.commands == rhs.workflow.commands
  }
}

struct WorkflowCommandsView_Previews: PreviewProvider {
  static var previews: some View {
    WorkflowCommandsListView(workflow: .constant(Workflow.designTime(.application([
      ApplicationTrigger.init(application: Application.finder())
    ]))), action: { _ in })
  }
}
