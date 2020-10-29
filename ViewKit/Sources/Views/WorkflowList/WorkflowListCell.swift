import SwiftUI
import ModelKit

struct WorkflowListCell: View {
  let workflow: Workflow

  var body: some View {
    HStack {
      ZStack(alignment: .bottom) {
        HStack {
          VStack(alignment: .leading) {
            name
            numberOfCommands
          }.frame(minHeight: 48)
          Spacer()
          icon
        }.padding(.horizontal, 10)
      }
    }
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
    ZStack {
      ForEach(workflow.commands, id: \.self) { command in
        if case .application(let applicationCommand) = command {
          IconView(icon: Icon(identifier: applicationCommand.application.bundleIdentifier,
                              path: applicationCommand.application.path))
            .frame(width: 32, height: 32)
        }
      }
    }
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
