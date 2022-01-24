import Apps
import SwiftUI

struct WorkflowCommandsListView: View {
  @Binding var workflow: Workflow

  var body: some View {
    VStack(alignment: .leading) {
      Label("Commands:", image: "")
        .labelStyle(HeaderLabelStyle())
      ForEach($workflow.commands, content: { CommandView(command: $0) })
    }
  }
}

struct WorkflowCommandsView_Previews: PreviewProvider {
  static var previews: some View {
    WorkflowCommandsListView(workflow: .constant(Workflow.designTime(.application([
      ApplicationTrigger.init(application: Application.finder())
    ]))))
  }
}
