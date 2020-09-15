import SwiftUI

struct WorkflowListCell: View {
  let workflow: Workflow

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        name
        numberOfCommands
      }
      Spacer()
      icon
    }
    .padding()
  }
}

// MARK: - Subviews

private extension WorkflowListCell {
  var name: some View {
    Text(workflow.name)
      .foregroundColor(.primary)
  }

  var numberOfCommands: some View {
    Text("\(workflow.commands.count) commands")
      .foregroundColor(.secondary)
  }

  var icon: some View {
    Text("􀍟")
      .font(.title)
      .foregroundColor(.primary)
  }
}

// MARK: - Previews

struct WorkflowListCell_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    WorkflowListCell(workflow: ModelFactory().workflowCell())
  }
}
