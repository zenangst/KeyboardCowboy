import SwiftUI

struct WorkflowView: View, Equatable {
  static let idealWidth: CGFloat = 500

  let workflow: WorkflowViewModel

  var body: some View {
    VStack {
      Text(workflow.name).font(.title)
    }
    .padding()
    .frame(minWidth: 400, idealWidth: Self.idealWidth, maxWidth: .infinity, maxHeight: .infinity)
  }
}

// MARK: - Previews

struct WorkflowView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    WorkflowView(workflow: ModelFactory().workflowDetail())
  }
}
