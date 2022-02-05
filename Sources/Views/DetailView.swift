import SwiftUI

struct DetailView: View, Equatable {
  let applicationStore: ApplicationStore
  @Binding var workflows: [Workflow]

  var body: some View {
    if workflows.count > 1 {
      Text("Multiple workflows selected")
    } else {
      ForEach($workflows, content: { workflow in
        WorkflowView(applicationStore: applicationStore, workflow: workflow)
      })
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
      workflows: .constant([
      Workflow.designTime(nil)
    ]))
  }
}
