import SwiftUI
import Bonzai

struct GroupDetailAddButton: View {
  @EnvironmentObject private var contentPublisher: GroupDetailPublisher
  @EnvironmentObject private var groupPublisher: GroupPublisher

  private let namespace: Namespace.ID
  private let onAction: () -> Void

  init(_ namespace: Namespace.ID, onAction: @escaping () -> Void) {
    self.namespace = namespace
    self.onAction = onAction
  }

  var body: some View {
    Button(action: onAction) {
      Text("Add Workflow")
        .font(.caption)
    }
    .help("Add new Workflow")
    .environment(\.buttonCalm, false)
    .environment(\.buttonFocusEffect, true)
    .environment(\.buttonHoverEffect, true)
    .environment(\.buttonGrayscaleEffect, true)
    .environment(\.buttonUnfocusedOpacity, 0.1)
    .environment(\.buttonBackgroundColor, Color(.init(hex: groupPublisher.data.color)))
    .matchedGeometryEffect(id: "add-workflow-button", in: namespace, isSource: true)
  }
}

struct ContentAddWorkflowHeaderView_Previews: PreviewProvider {
  @Namespace static var namespace
  static var previews: some View {
    GroupDetailAddButton(namespace) {}
      .designTime()
      .padding(.all)
  }
}
