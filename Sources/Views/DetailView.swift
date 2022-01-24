import SwiftUI

struct DetailView: View {
  @Binding var workflows: [Workflow]

  var body: some View {
    if workflows.count > 1 {
      Text("Multiple workflows selected")
    } else {
      ForEach($workflows, content: WorkflowView.init)
    }
  }
}

struct DetailView_Previews: PreviewProvider {
  static var previews: some View {
    DetailView(workflows: .constant([
      Workflow.designTime(nil)
    ]))
  }
}
