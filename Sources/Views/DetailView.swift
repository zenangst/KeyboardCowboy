import SwiftUI

struct DetailView: View, Equatable {
  @Binding var workflows: [Workflow]

  var body: some View {
    if workflows.count > 1 {
      Text("Multiple workflows selected")
    } else {
      ForEach($workflows, content: WorkflowView.init)
    }
  }

  static func == (lhs: DetailView, rhs: DetailView) -> Bool {
    lhs.workflows == rhs.workflows
  }
}

struct DetailView_Previews: PreviewProvider {
  static var previews: some View {
    DetailView(workflows: .constant([
      Workflow.designTime(nil)
    ]))
  }
}
