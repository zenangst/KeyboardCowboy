import Bonzai
import HotSwiftUI
import SwiftUI

struct EmptyWorkflowList: View {
  @EnvironmentObject private var publisher: GroupDetailPublisher

  private let namespace: Namespace.ID
  private let onAction: (GroupDetailView.Action) -> Void

  init(_ namespace: Namespace.ID, onAction: @escaping (GroupDetailView.Action) -> Void) {
    self.namespace = namespace
    self.onAction = onAction
  }

  var body: some View {
    VStack(spacing: 8) {
      Button(action: {
        withAnimation {
          onAction(.addWorkflow(workflowId: UUID().uuidString))
        }
      }, label: {
        HStack(spacing: 8) {
          Image(systemName: "plus.square.dashed")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .fixedSize()
            .frame(width: 16, height: 16)
          Divider()
            .opacity(0.5)
          Text("Add Workflow")
        }
      })
      .fixedSize()
      .help("Add Workflow")
      .matchedGeometryEffect(id: "add-workflow-button", in: namespace, isSource: false)
      .environment(\.buttonBackgroundColor, .systemGreen)
      .environment(\.buttonFocusEffect, true)
      .environment(\.buttonHoverEffect, false)
      .environment(\.buttonCalm, false)
      .environment(\.buttonPadding, .large)

      Text("No workflows yet,\nadd a workflow to get started.")
        .multilineTextAlignment(.center)
        .font(.footnote)
    }
    .frame(height: publisher.data.isEmpty ? nil : 0)
    .opacity(publisher.data.isEmpty ? 1 : 0)
    .enableInjection()
  }
}

#Preview {
  @Namespace var namespace
  return EmptyWorkflowList(namespace) { _ in }
    .designTime()
    .frame(width: 200, height: 100)
}
