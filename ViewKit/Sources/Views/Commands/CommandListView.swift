import SwiftUI

struct CommandListView: View {
  let commands: [CommandViewModel]

  var body: some View {
    VStack(spacing: 0) {
      ForEach(commands) { command in
        HStack {
          CommandView(command: command)
          Spacer()
          Text("≣")
            .font(.title)
            .foregroundColor(Color(.secondaryLabelColor))
            .padding(8)
            .offset(x: 0, y: -2)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .cornerRadius(8.0)
        .tag(command)
        Divider()
      }
    }
  }
}

// MARK: - Previews

struct CommandListView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    CommandListView(commands: ModelFactory().workflowDetail().commands)
  }
}
