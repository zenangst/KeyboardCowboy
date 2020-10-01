import SwiftUI

struct WorkflowView: View {
  static let idealWidth: CGFloat = 500

  @Binding var workflow: WorkflowViewModel

  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        VStack(alignment: .leading) {
          name.padding(.horizontal)
          HeaderView(title: "Keyboard shortcuts:")
          keyboardShortcuts
        }
        .padding(.vertical, 12)

        VStack(alignment: .leading) {
          HeaderView(title: "Commands:")
          commands
        }
        .padding(.bottom, 12)
        .background(Color(.gridColor).opacity(0.5))
      }.padding(.vertical, 12)
    }
  }
}

private extension WorkflowView {
  var name: some View {
    TextField("", text: $workflow.name)
      .font(.title)
      .foregroundColor(.primary)
      .textFieldStyle(PlainTextFieldStyle())
  }

  var keyboardShortcuts: some View {
    KeyboardShortcutListView(combinations: workflow.keyboardShortcuts)
      .background(Color(.windowBackgroundColor))
      .cornerRadius(8.0)
      .padding(.horizontal, 16)
      .frame(alignment: .top)
      .listStyle(DefaultListStyle())
      .shadow(color: Color(.shadowColor).opacity(0.05), radius: 1, x: 0, y: 3)
  }

  var commands: some View {
    CommandListView(commands: workflow.commands)
      .background(Color(.windowBackgroundColor))
      .cornerRadius(8.0)
      .padding(.horizontal, 16)
      .frame(alignment: .top)
      .listStyle(DefaultListStyle())
      .shadow(color: Color(.shadowColor).opacity(0.05), radius: 1, x: 0, y: 3)
  }
}

// MARK: - Previews

struct WorkflowView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    WorkflowView(workflow: .constant(ModelFactory().workflowDetail()))
      .frame(minHeight: 720)
  }
}
