import SwiftUI

struct WorkflowList: View {
  static let idealWidth: CGFloat = 300
  let workflows: [WorkflowViewModel]
  @State private var selection: WorkflowViewModel?

  var body: some View {
    NavigationView {
      List(workflows, selection: $selection) { workflow in
        NavigationLink(
          destination: WorkflowView(workflow: workflow),
          tag: workflow,
          selection: $selection
        ) {
          WorkflowListCell(workflow: workflow)
        }
        .onAppear(perform: {
          selection = selection ?? workflows.first
        })
      }
      .listStyle(PlainListStyle())
      .frame(minWidth: 300, maxWidth: 500, maxHeight: .infinity)
    }
  }
}

// MARK: - Previews

struct WorkflowList_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    WorkflowList(workflows: ModelFactory().workflowList())
  }
}
