import SwiftUI

struct ContentAddWorkflowHeaderView: View {
  @EnvironmentObject private var contentPublisher: ContentPublisher

  private let namespace: Namespace.ID
  private let onAction: () -> Void

  init(_ namespace: Namespace.ID,
       onAction: @escaping () -> Void) {
    self.namespace = namespace
    self.onAction = onAction
  }

  var body: some View {
    if !contentPublisher.data.isEmpty {
      Button(action: onAction) {
        Image(systemName: "plus.square.dashed")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(height: 12)
          .padding(2)
      }
      .buttonStyle(.gradientStyle(config: .init(nsColor: .systemGreen, grayscaleEffect: true)))
      .padding(.trailing, 8)
      .matchedGeometryEffect(id: "add-workflow-button", in: namespace)
    }
  }
}
