import SwiftUI

struct WorkflowView: View {
  let workflow: Workflow

  var body: some View {
    VStack {
      Text(workflow.name).font(.title)
    }
    .padding()
    .frame(minWidth: 300, idealWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
  }
}

// MARK: - Previews

struct WorkflowView_Previews: PreviewProvider {
  static var previews: some View {
    WorkflowView(workflow: ModelFactory().workflowDetail())
  }
}
