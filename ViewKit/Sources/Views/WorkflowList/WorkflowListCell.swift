import SwiftUI

struct WorkflowListCell: View {
  let workflow: WorkflowViewModel

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
        }
//        VStack { Divider() }
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
      ForEach(workflow.commands) { command in
        if case .application(let path, let identifier) = command.kind {
          IconView(identifier: identifier, path: path)
            .frame(width: 32, height: 32)
//            .offset(x: CGFloat(workflow.commands.count) - CGFloat(index),
//                    y: -CGFloat(workflow.commands.count) + CGFloat(index))
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
